import json
from pathlib import Path
from urllib.request import Request, urlopen

# ===========================================================================
# Settings
# ===========================================================================
# Enter the name of the Smogon JSON file:
#   It needs to be in the same directory as this scritp.
input_filename = 'SmogonSource9.json'

# Optional Index Offset
#   This is used if you're planning on appending other Smogon JSON files to
#   an already existing generated PBS
#       Reasons you might do this? Including older Smogon files for more builds
output_index_offset = 0

# Optional Terablast Replacement
#   Currently just replaces the move with return. May be updated in a future version
replace_terablast_option = True
replace_z_moves_option = True

# ===========================================================================
# API Cache and Helpers
# ===========================================================================

API_CACHE = {}

def get_pokeapi_data(pokemon_name):
    """
    Get Pokémon data from PokéAPI.

    Results are cached so each Pokémon/form is only requested once.
    """
    source_name = pokemon_name.lower().replace("’", "'")

    # Translate source-file names to PokéAPI names when necessary.
    api_name = POKEAPI_NAME_EXCEPTIONS.get(
        source_name,
        source_name
    )

    if api_name in API_CACHE:
        return API_CACHE[api_name]

    url = f"https://pokeapi.co/api/v2/pokemon/{api_name}/"

    request = Request(
        url,
        headers={
            "User-Agent": "PokemonEssentialsBuildParser/1.0"
        }
    )

    try:
        with urlopen(request) as response:
            data = json.load(response)
    except Exception as e:
        raise RuntimeError(
            f"Failed to retrieve '{pokemon_name}' from PokéAPI: {e}"
        )

    API_CACHE[api_name] = data
    return data

def get_api_ability(pokemon_name):
    """Return the first ability listed by PokéAPI."""
    data = get_pokeapi_data(pokemon_name)

    abilities = data.get("abilities", [])

    if not abilities:
        return None

    ability = abilities[0].get("ability")

    if not ability:
        return None

    return ability.get("name")

def get_total_base_stats(pokemon_name):
    """Return the sum of all base stats from PokéAPI."""
    data = get_pokeapi_data(pokemon_name)

    return sum(
        stat.get("base_stat", 0)
        for stat in data.get("stats", [])
    )

# ===========================================================================
# Parsing Source
# ===========================================================================

def parse_sets(data):
    parsed = []

    for pokemon, formats in data.items():
        for format_name, sets in formats.items():
            for set_name, set_data in sets.items():

                parsed_set = {
                    "pokemon": pokemon,
                    "format": format_name,
                    "set_name": set_name,

                    "moves": pick_moves(set_data.get("moves", [])),

                    "ability": pick(set_data.get("ability")),
                    "item": pick(set_data.get("item")),
                    "nature": pick(set_data.get("nature")),
                    "ivs": pick(set_data.get("ivs")),
                    "evs": pick(set_data.get("evs")),
                    "teratypes": pick(set_data.get("teratypes")),
                }

                parsed.append(parsed_set)

    return parsed

# ===========================================================================
# Mapping
# ===========================================================================
STAT_ORDER = ["hp", "atk", "def", "spa", "spd", "spe"]

HIDDEN_POWER_IVS = {
    "BUG":    [31, 30, 31, 31, 30, 31],
    "DARK":   [31, 31, 31, 31, 31, 31],
    "DRAGON": [30, 31, 31, 31, 31, 31],
    "ELECTRIC": [30, 31, 30, 31, 31, 30],
    "FIGHTING": [30, 30, 31, 30, 30, 30],
    "FIRE":   [31, 30, 31, 30, 31, 30],
    "FLYING": [30, 30, 30, 30, 30, 31],
    "GHOST":  [31, 30, 31, 31, 30, 31],
    "GRASS":  [30, 31, 31, 30, 31, 31],
    "GROUND": [30, 30, 30, 31, 30, 30],
    "ICE":    [30, 31, 30, 31, 31, 31],
    "POISON": [30, 30, 31, 30, 30, 31],
    "PSYCHIC": [30, 31, 31, 31, 31, 30],
    "ROCK":   [30, 30, 31, 31, 30, 30],
    "STEEL":  [31, 30, 30, 30, 31, 30],
    "WATER":  [31, 30, 30, 30, 31, 31],
}

POKEAPI_NAME_EXCEPTIONS = {
    "tauros-paldea-blaze": "tauros-paldea-blaze-breed",
    "tauros-paldea-aqua": "tauros-paldea-aqua-breed",
    "deoxys": "deoxys-normal",
    "giratina": "giratina-altered",
    "shaymin": "shaymin-land",
    "arceus-bug": "arceus",
    "arceus-dark": "arceus",
    "arceus-dragon": "arceus",
    "arceus-electric": "arceus",
    "arceus-fairy": "arceus",
    "arceus-fighting": "arceus",
    "arceus-fire": "arceus",
    "arceus-flying": "arceus",
    "arceus-ghost": "arceus",
    "arceus-grass": "arceus",
    "arceus-ground": "arceus",
    "arceus-ice": "arceus",
    "arceus-poison": "arceus",
    "arceus-psychic": "arceus",
    "arceus-rock": "arceus",
    "arceus-steel": "arceus",
    "arceus-water": "arceus",
    "darmanitan": "darmanitan-standard",
    "darmanitan-galar": "darmanitan-galar-standard",
    "tornadus": "tornadus-incarnate",
    "thundurus": "thundurus-incarnate",
    "landorus": "landorus-incarnate",
    "enamorus": "enamorus-incarnate",
    "keldeo": "keldeo-ordinary",
    "meloetta": "meloetta-aria",
    "pyroar": "pyroar-male",
    "meowstic": "meowstic-male",
    "aegislash": "aegislash-shield",
    "zygarde-10%": "zygarde-10",
    "zygarde": "zygarde-50",
    "oricorio": "oricorio-baile",
    "oricorio-pa'u": "oricorio-pau",
    "lycanroc": "lycanroc-midday",
    "minior": "minior-red",
    "mimikyu": "mimikyu-disguised",
    "tapu koko": "tapu-koko",
    "tapu lele": "tapu-lele",
    "tapu bulu": "tapu-bulu",
    "tapu fini": "tapu-fini",
    "necrozma-dusk-mane": "necrozma-dusk",
    "necrozma-dawn-wings": "necrozma-dawn",
    "toxtricity": "toxtricity-amped",
    "indeedee": "indeedee-male",
    "indeedee-f": "indeedee-female",
    "morpeko": "morpeko-full-belly",
    "urshifu": "urshifu-single-strike",
    "basculegion": "basculegion-male",
    "basculegion-f": "basculegion-female",
    "maushold": "maushold-family-of-three",
    "maushold-four": "maushold-family-of-four",
    "palafin": "palafin-zero",
    "tatsugiri": "tatsugiri-curly",
    "dudunsparce": "dudunsparce-two-segment",
    "great tusk": "great-tusk",
    "scream tail": "scream-tail",
    "brute bonnet": "brute-bonnet",
    "flutter mane": "flutter-mane",
    "slither wing": "slither-wing",
    "sandy shocks": "sandy-shocks",
    "roaring moon": "roaring-moon",
    "walking wake": "walking-wake",
    "gouging fire": "gouging-fire",
    "raging bolt": "raging-bolt",
    "iron treads": "iron-treads",
    "iron bundle": "iron-bundle",
    "iron hands": "iron-hands",
    "iron jugulis": "iron-jugulis",
    "iron moth": "iron-moth",
    "iron thorns": "iron-thorns",
    "iron valiant": "iron-valiant",
    "iron leaves": "iron-leaves",
    "iron boulder": "iron-boulder",
    "iron crown": "iron-crown",
    "sinistcha": "sinistcha",
    "sinistcha-masterpiece": "sinistcha",
    "ogerpon-wellspring": "ogerpon-wellspring-mask",
    "ogerpon-hearthflame": "ogerpon-hearthflame-mask",
    "ogerpon-cornerstone": "ogerpon-cornerstone-mask",
    "farfetch'd": "farfetchd",
    "farfetch’d": "farfetchd",
    "farfetch'd-galar": "farfetchd-galar",
    "farfetch’d-galar": "farfetchd-galar",
    "mr. mime": "mr-mime",
    "basculin": "basculin-red-striped",
    "frillish": "frillish-male",
    "jellicent": "jellicent-male",
    "gourgeist": "gourgeist-large",
    "wishiwashi": "wishiwashi-solo",
    "type: null": "type-null",
    "silvally-bug": "silvally",
    "silvally-dark": "silvally",
    "silvally-dragon": "silvally",
    "silvally-electric": "silvally",
    "silvally-fairy": "silvally",
    "silvally-fighting": "silvally",
    "silvally-fire": "silvally",
    "silvally-flying": "silvally",
    "silvally-ghost": "silvally",
    "silvally-grass": "silvally",
    "silvally-ground": "silvally",
    "silvally-ice": "silvally",
    "silvally-poison": "silvally",
    "silvally-psychic": "silvally",
    "silvally-rock": "silvally",
    "silvally-steel": "silvally",
    "silvally-water": "silvally",
    "sirfetch'd": "sirfetchd",
    "sirfetch’d": "sirfetchd",
    "mr. rime": "mr-rime",
    "eiscue": "eiscue-ice",
    # GMAX
    "venusaur-gmax": "venusaur",
    "charizard-gmax": "charizard",
    "blastoise-gmax": "blastoise",
    "butterfree-gmax": "butterfree",
    "pikachu-gmax": "pikachu",
    "meowth-gmax": "meowth",
    "machamp-gmax": "machamp",
    "gengar-gmax": "gengar",
    "kingler-gmax": "kingler",
    "lapras-gmax": "lapras",
    "eevee-gmax": "eevee",
    "snorlax-gmax": "snorlax",
    "garbodor-gmax": "garbodor",
    "melmetal-gmax": "melmetal",
    "rillaboom-gmax": "rillaboom",
    "cinderace-gmax": "cinderace",
    "inteleon-gmax": "inteleon",
    "corviknight-gmax": "corviknight",
    "orbeetle-gmax": "orbeetle",
    "drednaw-gmax": "drednaw",
    "coalossal-gmax": "coalossal",
    "flapple-gmax": "flapple",
    "appletun-gmax": "appletun",
    "sandaconda-gmax": "sandaconda",
    "toxtricity-gmax": "toxtricity",
    "centiskorch-gmax": "centiskorch",
    "hatterene-gmax": "hatterene",
    "grimmsnarl-gmax": "grimmsnarl",
    "alcremie-gmax": "alcremie",
    "copperajah-gmax": "copperajah",
    "duraludon-gmax": "duraludon",
    "urshifu-gmax": "urshifu-single-strike",

}

FORMAT_TO_TIER = {
    # Standard tiers
    "ou": "OU",
    "uu": "UU",
    "ru": "RU",
    "nu": "NU",
    "pu": "PU",
    "zu": "ZU",
    "nfe": "NFE",
    "lc": "LC",

    # Ubers
    "ubers": "UBERS",
    "ubersuu": "UBERS",

    # National Dex
    "nationaldex": "OTHER",
    "nationaldexuu": "UU",
    "nationaldexru": "RU",
    "nationaldexubers": "UBERS",
    "nationaldexmonotype": "MONOTYPE",
    "nationaldexdoubles": "DOUBLES",
    "dlc1nationaldexag": "OTHER",

    # Other formats
    "monotype": "MONOTYPE",
    "doublesou": "DOUBLES",
    "vgc2020": "VGC",
    "vgc2021": "VGC",
    "vgc2022": "VGC",
    "vgc2023": "VGC",
    "vgc2024": "VGC",
    "vgc2025": "VGC",
    "battlestadiumsingles": "OTHER",
    "battlestadiumdoubles": "DOUBLES",
    "anythinggoes": "SKIP",
    "balancedhackmons": "SKIP",
    "cap": "SKIP",
    "godlygift": "SKIP",
    "inheritance": "SKIP",
    "mixandmega": "SKIP",
    "partnersincrime": "SKIP",
    "stabmons": "SKIP",
    "1v1": "SKIP",
    "almostanyability": "SKIP",
    "bdspou": "OU",
    "camomons": "SKIP",
    "2v2doubles": "DOUBLES",
}

FORMAT_ABILITY_EXCEPTIONS = {
    "ASONEGLASTRIER": "ASONECHILLINGNEIGH",
    "ASONESPECTRIER": "ASONEGRIMNEIGH",
}

SET_TO_TAG = {
    "Offensive Utility": "OFFENSIVE",
    "Defensive Utility": "DEFENSIVE",
    "Offensive": "OFFENSIVE",
    "Wallbreaker (Poison)": "WALLBREAKER",
    "Redirection Support": "REDIRECTION",
    "Bulky Support": "SUPPORT",
    "Defensive": "DEFENSIVE",
    "Physical Wall": "PHYSICALWALL",
}

FORM_SUFFIXES = {
    "-alola": 1,
    "-hisui": 1,
    "-galar": 1,
    "-paldea": 1,
    "-Paldea-Blaze": 2,
    "-Paldea-Aqua": 3,
    "-Bloodmoon": 1,
    "-attack": 1,
    "-defense": 2,
    "-speed": 3,
    "-heat": 1,
    "-wash": 2,
    "-frost": 3,
    "-fan": 4,
    "-mow": 5,
    "-Therian": 1,
    "-white": 1,
    "-black": 2,
    "-10%": 1,
    "-Unbound": 1,
    "-Pom-Pom": 1,
    "-Pa'u": 2,
    "-Sensu": 3,
    "-Dusk": 2,
    "-Dusk-Mane": 1,
    "-Dawn-Wings": 2,
    "-Ultra": 3,
    "-Crowned": 1,
    "-Rapid-Strike": 1,
    "-Ice": 1,
    "-Shadow": 2,
    "-Masterpiece": 1,
    "-Wellspring": 1,
    "-Hearthflame": 2,
    "-Cornerstone": 3,
    "-sky": 1,
    "-roaming": 1,
    "-midnight": 1,
}

FORM_EXCEPTIONS = {
    "meowth": {
        "-alola": 1,
        "-galar": 2,
    },
    "darumaka": {
        "-galar": 2,
    },
    "darmanitan": {
        "-galar": 2,
    },
}

REPLACE_Z_MOVES = {
    "BUGINIUMZ": "BUGGEM",
    "DARKINIUMZ": "DARKGEM",
    "DRAGONIUMZ": "DRAGONGEM",
    "ELECTRIUMZ": "ELECTRICGEM",
    "FAIRIUMZ": "FAIRYGEM",
    "FIGHTINIUMZ": "FIGHTINGGEM",
    "FIRIUMZ": "FIREGEM",
    "FLYINIUMZ": "FLYINGGEM",
    "GHOSTIUMZ": "GHOSTGEM",
    "GRASSIUMZ": "GRASSGEM",
    "GROUNDIUMZ": "GROUNDGEM",
    "ICIUMZ": "ICEGEM",
    "NORMALIUMZ": "NORMALGEM",
    "POISONIUMZ": "POISONGEM",
    "PSYCHIUMZ": "PSYCHICGEM",
    "ROCKIUMZ": "ROCKGEM",
    "STEELIUMZ": "STEELGEM",
    "WATERIUMZ": "WATERGEM",
    "ALORAICHIUMZ": "ELECTRICGEM",
    "DECIDIUMZ": "GHOSTGEM",
    "EEVIUMZ": "NORMALGEM",
    "INCINIUMZ": "DARKGEM",
    "KOMMONIUMZ": "DRAGONGEM",
    "LUNALIUMZ": "GHOSTGEM",
    "LYCANIUMZ": "ROCKGEM",
    "MARSHADIUMZ": "GHOSTGEM",
    "MEWNIUMZ": "PSYCHICGEM",
    "MIMIKIUMZ": "FAIRYGEM",
    "PIKANIUMZ": "ELECTRICGEM",
    "PIKASHUNIUMZ": "ELECTRICGEM",
    "PRIMARIUMZ": "WATERGEM",
    "SNORLIUMZ": "NORMALGEM",
    "SOLGANIUMZ": "STEELGEM",
    "TAPUNIUMZ": "FAIRYGEM",
    "ULTRANECROZIUMZ": "PSYCHICGEM",
}

# ===========================================================================
# Output PBS Formatting
# ===========================================================================

def parse_species_name(name):
    """
    Separate a Pokémon's base species name from its form.

    Handles normal regional forms as well as Pokémon-specific
    form numbering exceptions.
    """

    name_lower = name.lower()

    # Check every recognized suffix.
    for suffix in FORM_SUFFIXES:

        if name_lower.endswith(suffix.lower()):

            base_name = name[:-len(suffix)]
            base_lower = base_name.lower()

            # Check for a Pokémon-specific form exception.
            if base_lower in FORM_EXCEPTIONS:
                form = FORM_EXCEPTIONS[base_lower].get(
                    suffix.lower(),
                    FORM_SUFFIXES[suffix]
                )
            else:
                form = FORM_SUFFIXES[suffix]

            base_name.replace("'", "").replace("’", "").replace(":", "").replace(".", "")
            return base_name, form

    return name, 0

def normalize_special_species_name(name):
    """
    Remove transformation suffixes that are handled dynamically
    by Pokémon Essentials rather than by the PBS form number.
    """
    special_suffixes = [
        # Mega Evolutions
        "-mega-x",
        "-mega-y",
        "-mega-z",
        "-mega",
        # Origin Forms
        "-origin",
        # Arceus type forms
        "-bug",
        "-dark",
        "-dragon",
        "-electric",
        "-fairy",
        "-fighting",
        "-fire",
        "-flying",
        "-ghost",
        "-grass",
        "-ground",
        "-ice",
        "-poison",
        "-psychic",
        "-rock",
        "-steel",
        "-water",
        # Others
        "-f",
        "-dada",
        "-four",
        "-gmax",
        "-small",
        "-medium",
        "-large",
        "-jumbo",
        "-super",
    ]

    if name.startswith("calyrex-ice"):
        return name

    for suffix in special_suffixes:
        if name.lower().endswith(suffix):
            return name[:-len(suffix)]

    return name

def pick(value):
    """If value is a list, arbitrarily pick the first option."""
    if isinstance(value, list):
        return value[0] if value else None
    return value

def pick_moves(moves):
    selected = []
    used = set()

    for slot in moves:
        options = slot if isinstance(slot, list) else [slot]

        selected_move = None

        # Prefer the first option that hasn't already been selected
        for move in options:
            formatted = format_move_name(move)

            if formatted not in used:
                selected_move = move
                break

        # If every option is already used, keep the first option
        if selected_move is None:
            selected_move = options[0]

        selected.append(selected_move)
        used.add(format_move_name(selected_move))

    return selected

def format_ability(value):
    """Convert an ability name to the output format and apply exceptions."""
    formatted = format_name(value)
    return FORMAT_ABILITY_EXCEPTIONS.get(formatted, formatted)

def format_name(value):
    """Convert a name to the format used in the output."""
    if value is None:
        return ""

    return str(value).upper().replace(" ", "").replace("-", "").replace("'", "").replace("’", "").replace(":", "").replace(".", "")

def format_move_name(value):
    """Convert a name to the format used in the output."""
    if value is None:
        return ""
    formatted_move_name = str(value).upper().replace(" ", "").replace("-", "").replace("'", "").replace("’", "").replace(":", "").replace(".", "")
    
    if formatted_move_name.startswith("HIDDENPOWER"):
        formatted_move_name = "HIDDENPOWER"

    return formatted_move_name

def replace_terablast(moves):
    moves = [format_move_name(move) for move in moves]

    if "TERABLAST" not in moves:
        return moves

    # Prefer Return
    if "RETURN" not in moves:
        replacement = "RETURN"

    # Return already exists, so use Protect
    elif "PROTECT" not in moves:
        replacement = "PROTECT"

    # Both are already present
    elif "SUBSTITUTE" not in moves:
        replacement = "SUBSTITUTE"

    else:
        # All fallback moves are already present
        replacement = "PROTECT"

    return [
        replacement if move == "TERABLAST" else move
        for move in moves
    ]

def format_item(value):
    """Convert a name to the format used in the output."""
    if value is None:
        return ""
    formatted_item_name = str(value).upper().replace(" ", "").replace("-", "")
    if replace_z_moves_option and formatted_item_name.endswith("IUMZ"):
        return REPLACE_Z_MOVES.get(formatted_item_name, formatted_item_name)

    return formatted_item_name

def format_evs(evs):
    """Convert EV data to HP, Atk, Def, SpA, SpD, Spe order."""
    evs = evs or {}
    if sum(evs.get(stat, 0) for stat in STAT_ORDER) > 510:
        return "252, 0, 0, 0, 0, 252"
    return ", ".join(str(evs.get(stat, 0)) for stat in STAT_ORDER)

def apply_hidden_power_ivs(ivs, moves):
    """
    Modify IVs if the Pokémon has a Hidden Power move.

    IV order:
    HP, Atk, Def, SpA, SpD, Spe
    """

    for move in moves:
        move = format_name(move)

        if move.startswith("HIDDENPOWER"):
            hidden_power_type = move[len("HIDDENPOWER"):]

            if hidden_power_type in HIDDEN_POWER_IVS:
                return HIDDEN_POWER_IVS[hidden_power_type].copy()

    return ivs

def format_ivs(ivs):
    """Convert an IV dictionary into 'hp, atk, def, spa, spd, spe'.

    Unspecified IVs default to 31.
    """
    if not ivs:
        ivs = {}

    return ", ".join(
        str(ivs.get(stat, 31))
        for stat in STAT_ORDER
    )

def get_tier(format_name):
    """Map a Smogon format to an Essentials build tier."""
    normalized = format_name.lower().strip()
    try:
        return FORMAT_TO_TIER[normalized]
    except KeyError:
        raise ValueError(
            f"Unmapped format '{normalized}'. Add it to FORMAT_TO_TIER."
        ) from None

def get_tag(set_name):
    name = set_name.lower()

    # --------------------------------
    # Defensive
    # --------------------------------
    defensive_keywords = [
        "defensive",
        "physical wall",
        "special wall",
        "physically defensive",
        "specially defensive",
    ]

    if any(keyword in name for keyword in defensive_keywords):
        return "DEFENSIVE"

    # --------------------------------
    # Support
    # --------------------------------
    support_keywords = [
        "support",
        "utility",
        "pivot",
        "tailwind",
        "redirection",
        "hazard setter",
        "hazard removal",
    ]

    if any(keyword in name for keyword in support_keywords):
        return "SUPPORT"

    # --------------------------------
    # Offensive
    # --------------------------------
    offensive_keywords = [
        "offensive",
        "attacker",
        "wallbreaker",
        "sweeper",
        "choice band",
        "choice specs",
        "swords dance",
        "nasty plot",
        "dragon dance",
        "calm mind",
        "quiver dance",
        "shell smash",
        "belly drum",
        "growth",
    ]

    if any(keyword in name for keyword in offensive_keywords):
        return "OFFENSIVE"

    # --------------------------------
    # Anything that doesn't fit
    # --------------------------------
    return "OTHER"

# ===========================================================================
# Output PBS Writing
# ===========================================================================

def write_builds(sets, filename):
    """Write parsed Smogon sets to a Pokémon Essentials PBS file."""
    output_index = 1 + output_index_offset

    with open(filename, "w", encoding="utf-8") as file:
        for pokemon_set in sets:
            tier = get_tier(pokemon_set["format"])
            if tier == "SKIP":
                continue

            pb_id = f"PB_{output_index:06d}"
            output_index += 1

            pokemon_name = pokemon_set["pokemon"]
            normalized_name = normalize_special_species_name(pokemon_name)
            species_name, form = parse_species_name(normalized_name)

            ability = pokemon_set["ability"] or get_api_ability(pokemon_name)

            moves = [format_move_name(move) for move in pokemon_set["moves"]]
            if replace_terablast_option:
                moves = replace_terablast(moves)

            ivs = format_ivs(pokemon_set["ivs"])
            ivs = [int(value.strip()) for value in ivs.split(",")]
            ivs = apply_hidden_power_ivs(ivs, pokemon_set["moves"])
            ivs = ", ".join(str(value) for value in ivs)

            lines = [
                "#-------------------------------",
                f"[{pb_id}]",
                f"species = {format_name(species_name)}",
                f"form = {form}",
                f"tier = {tier}",
                f"tag = {get_tag(pokemon_set['set_name'])}",
                f"item = {format_item(pokemon_set['item'])}",
                f"nature = {format_name(pokemon_set['nature'])}",
                f"ability = {format_ability(ability)}",
                f"evs = {format_evs(pokemon_set['evs'])}",
                f"ivs = {ivs}",
                f"moves = {', '.join(moves)}",
                f"total_base_stats = {get_total_base_stats(pokemon_name)}",
            ]

            file.write("\n".join(lines) + "\n")

# ===========================================================================
# Main
# ===========================================================================

def main():
    """Load the Smogon JSON source and write the converted PBS file."""
    input_path = Path(input_filename)

    if not input_path.exists():
        print("Source Not Found.")
        return

    print("Source Found.")

    with input_path.open("r", encoding="utf-8") as file:
        data = json.load(file)

    sets = parse_sets(data)

    output_path = input_path.with_name(f"output_{input_path.stem}.txt")
    write_builds(sets, output_path)

    print("Script Complete!")

if __name__ == "__main__":
    main()
