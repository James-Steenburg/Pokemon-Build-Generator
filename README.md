# Random Team Generator

### Pokémon Essentials v21.1 — Implementation Guide

A Pokémon Essentials v21.1 plugin for generating random Pokémon teams from predefined criteria.

The plugin can:

* Filter available Pokémon builds by tier, tag, species, type, BST, and more
* Generate teams while satisfying multiple constraints
* Create balanced teams using tag and tier requirements
* Generate teams for trainers
* Generate rental teams for the player
* Generate individual Pokémon builds
* Convert Smogon sets into Pokémon Essentials PBS format using the included Python tool

---

## 1. Install the Plugin

Copy the **Pokemon Build Generator** folder into your project's `Plugins` folder.

Copy the plugin's `Graphics` folder into your project's `Graphics` folder.

### Plugin Structure

The scripts should be loaded in this order:

```text
Pokemon Build Generator/
├── 001_PokemonBuildData.rb
├── 002_PokemonBuildGenerator.rb
├── 003_GeneratedTeamData.rb
├── 004_RandomTeamState.rb
└── 005_RandomTeamHandler.rb
```

### Required PBS Files

The plugin requires the following PBS files:

```text
PBS/
├── pokemon_builds.txt
└── generated_teams_criterion.txt
```

* `pokemon_builds.txt` contains the individual Pokémon builds that can be selected.
* `generated_teams_criterion.txt` defines the rules used when creating a random team.

### Required Graphics

The plugin references the following graphics, which should be placed in your project's `Graphics` folder:

```text
Graphics/
├── Battle animations/
│   ├── ball_RENTALBALL.png
│   └── ball_RENTALBALL_open.png
└── Items/
    └── RENTALBALL.png
```

### Tools

A `Tools` folder is also included for converting Smogon JSON files into Pokémon Essentials PBS format.

```text
Tools/
├── Py_ConvertSmogonToPBS.py
├── pokemon_builds.txt
├── SmogonSource8.txt
├── SmogonSource9.txt
└── SmogonSourceSample.txt
```

The sample source files are provided for reference and testing. They are **not used by Pokémon Essentials** and can be deleted if desired.

---

# 2. Create Team Criteria

Open:

```text
PBS/generated_teams_criterion.txt
```

Each section defines a set of rules that can be used to generate a team.

A criteria set can be reused as often as needed.

### Example

```ini
[STEEL_OU]
team_size = 6
tier = OU
monotype = STEEL
mega_limit = 1
unique_items = true
no_duplicate_species = true
```

This creates a criteria set named:

```text
STEEL_OU
```

It tells the generator to create:

* A team of 6 Pokémon
* Only Pokémon in the OU tier
* Only Steel-type Pokémon
* No more than 1 Mega Pokémon
* No duplicate held items
* No duplicate species

You can create as many criteria sections as you want.

---

# 3. Available Criteria

The generator supports the following settings.

## 3.1 Team Size

**Required**

Team size can be between 1 and 6.

```ini
team_size = 6
```

---

## 3.2 Tier

**Optional**

Currently supported tiers:

```text
OU
UU
RU
NU
PU
ZU
NFE
LC
UBERS
MONOTYPE
DOUBLES
VGC
OTHER
```

### Single Tier

```ini
tier = OU
```

### Multiple Tiers

```ini
tiers = OU, UU, RU
```

---

## 3.3 Tags

**Optional**

Require a specific tag:

```ini
tag = OFFENSIVE
```

Allow several tags:

```ini
tags = OFFENSIVE, DEFENSIVE, SUPPORT
```

Exclude tags:

```ini
excluded_tags = SUPPORT
```

---

## 3.4 Species Restrictions

**Optional**

Exclude specific Pokémon:

```ini
excluded_species = BLISSEY, CHANSEY
```

---

## 3.5 Monotype

**Optional**

Require every selected Pokémon to have the specified type:

```ini
monotype = WATER
```

Valid types are:

```text
NORMAL
FIRE
WATER
ELECTRIC
GRASS
ICE
FIGHTING
POISON
GROUND
FLYING
PSYCHIC
BUG
ROCK
GHOST
DRAGON
DARK
STEEL
FAIRY
```

---

## 3.6 Mega Pokémon

**Optional**

Limit the number of Mega Pokémon:

```ini
mega_limit = 1
```

Prevent Mega Pokémon from being selected:

```ini
mega_limit = 0
```

---

## 3.7 Duplicate Items

**Optional**

Prevent multiple Pokémon from holding the same item:

```ini
unique_items = true
```

---

## 3.8 Duplicate Species

**Optional**

Prevent the same species from appearing more than once:

```ini
no_duplicate_species = true
```

---

## 3.9 Legendary and Mythical Pokémon

**Optional**

Only Legendary Pokémon:

```ini
legendary = true
```

Exclude Legendary Pokémon:

```ini
legendary = false
```

Only Mythical Pokémon:

```ini
mythical = true
```

Exclude Mythical Pokémon:

```ini
mythical = false
```

If these settings are omitted, no Legendary/Mythical restriction is applied.

---

## 3.10 Base Stat Total Restrictions

**Optional**

You can restrict Pokémon by Base Stat Total (BST).

### BST Range

```ini
bst_range = 400, 500
```

Only Pokémon with a BST between 400 and 500 can be selected.

This can be useful for creating intentionally weaker teams:

```ini
[WEAK_TEAM]
team_size = 6
bst_range = 300, 400
no_duplicate_species = true
```

---

## 3.11 BST Targets

**Optional**

You can specify a desired BST for each team slot:

```ini
bst_targets = 350, 375, 400, 425, 450, 475
```

The generator attempts to find Pokémon close to those values.

You can control the acceptable difference with:

```ini
bst_target_tolerance = 25
```

For example, a target of `400` with a tolerance of `25` allows Pokémon with BSTs approximately between `375` and `425`.

---

## 3.12 Tag Requirements

**Optional**

Require a minimum number of Pokémon with particular tags:

```ini
tag_requirements = OFFENSIVE:2, DEFENSIVE:2
```

### Example

```ini
[BALANCED_TEAM]
team_size = 6
tier = OU
no_duplicate_species = true
tag_requirements = OFFENSIVE:2, DEFENSIVE:2
```

This requires at least:

* 2 Offensive Pokémon
* 2 Defensive Pokémon

The remaining two Pokémon can have any valid tag.

---

## 3.13 Tier Requirements

**Optional**

You can similarly require specific numbers of Pokémon from particular tiers:

```ini
tier_requirements = OU:3, UU:2
```

### Example

```ini
[MIXED_TEAM]
team_size = 6
tiers = OU, UU, RU
no_duplicate_species = true
tier_requirements = OU:3, UU:2
```

This guarantees at least:

* 3 OU Pokémon
* 2 UU Pokémon

The remaining Pokémon can come from any of the allowed tiers.

---

# 4. Using a Criteria Set in an RPG Maker Event

Once your criteria have been created, you can select them from an RPG Maker event.

Add a **Script** command to your event:

```ruby
RandomTeamGenerator.start(:STEEL_OU, 30)
```

The numeric second argument sets the level of the generated Pokémon.

### Short Version

You can also use the shorthand:

```ruby
RTG.start(:STEEL_OU, 30)
```

Then start the trainer battle normally.

### Example

```text
Script:
    RTG.start(:STEEL_OU, 30)

Trainer Battle:
    Camper
```

The plugin sees that `STEEL_OU` was selected and automatically generates the trainer's party when the trainer is loaded.

---

# 5. Reusing the Same Trainer

The same trainer can be used with different criteria.

For example:

```text
Script:
    RandomTeamGenerator.start(:STEEL_OU, 30)

Trainer Battle:
    GeneratedMale
```

Later:

```text
Script:
    RandomTeamGenerator.start(:MIXED_TEAM, 30)

Trainer Battle:
    GeneratedMale
```

The trainer type remains the same. Only the generation criteria changes.

---

# 6. Creating Your Own Presets

A good way to organize a project is to create presets for common battle types.

For example:

```ini
[STANDARD_OU]
team_size = 6
tier = OU
no_duplicate_species = true
unique_items = true

[MONO_FIRE]
team_size = 6
monotype = FIRE
no_duplicate_species = true

[WEAK_TRAINER]
team_size = 3
bst_range = 250, 400
no_duplicate_species = true

[ELITE_TRAINER]
team_size = 6
tier = OU
mega_limit = 1
unique_items = true
no_duplicate_species = true
tag_requirements = OFFENSIVE:2, DEFENSIVE:2
```

Your RPG Maker events then only need to select the appropriate preset.

---

# 7. Important: Criteria Are One-Time

The criteria selected by:

```ruby
RandomTeamGenerator.start(:STEEL_OU, 30)
```

is intended for the **next generated trainer**.

After the trainer's party is generated, the plugin clears the criteria automatically.

You therefore do not need to manually reset it after every battle.

---

# 8. Quick Example — Team Generation

### PBS

```ini
[ANY_SIX]
team_size = 6

[STEEL_ELITE]
team_size = 6
monotype = STEEL
tier = OU
mega_limit = 1
unique_items = true
no_duplicate_species = true
tag_requirements = OFFENSIVE:2, DEFENSIVE:2
```

### RPG Maker Event

```text
Script:
    RTG.start(:STEEL_ELITE, 100)

Trainer Battle:
    GeneratedM
```

### Rental Team

To create a team of any six Pokémon at level 30 as rental Pokémon:

```ruby
RTG.rent(:ANY_SIX, 30)
```

To give the player any six Pokémon at level 30 **without** making them rental Pokémon:

```ruby
RTG.give(:ANY_SIX, 30)
```

---

# 9. Quick Example — Individual Builds

The plugin can also work with individual Pokémon builds.

A build can be retrieved by its key and converted into a Pokémon object:

```ruby
build = GameData::PokemonBuild.get(:PB_000030)
pkmn = build.to_pokemon
```

### Example PBS Build

```ini
[PB_000030]
species = PIKACHU
form = 0
tier = NFE
tag = OFFENSIVE
item = LIGHTBALL
nature = TIMID
ability = LIGHTNINGROD
evs = 0, 0, 0, 252, 4, 252
ivs = 31, 31, 31, 31, 31, 31
moves = THUNDERBOLT, SURF, VOLTSWITCH, KNOCKOFF
total_base_stats = 320
```

---

# 10. Troubleshooting

## "Undefined generated team criteria"

If you see an error such as:

```text
Undefined generated team criteria 'STEEL_OU'
```

Check that your criteria file contains:

```ini
[STEEL_OU]
```

Then make sure the PBS files have been recompiled.

---

## "No Pokémon Builds Match the Requested Filters"

If generation fails with:

```text
No Pokémon Builds match the requested filters.
```

your criteria are probably too restrictive.

For example, this may be impossible:

```ini
team_size = 6
monotype = ICE
tier = OU
legendary = true
mega_limit = 0
```

Try relaxing one or more restrictions.

---

## Unable to Create a Team

If the generator reports that it cannot satisfy the requested constraints, check combinations such as:

```ini
no_duplicate_species = true
unique_items = true
tag_requirements = ...
tier_requirements = ...
bst_range = ...
```

The constraint solver must find a single team satisfying **all** requested rules simultaneously.

---

# 11. Smogon Build Conversion

The included Python tool can convert Smogon JSON set data into the `pokemon_builds.txt` format used by the plugin.

```text
Tools/
└── Py_ConvertSmogonToPBS.py
```

The tool can be used to generate large numbers of Pokémon builds from Smogon data.

The included sample source files are provided for testing and demonstration.

> **Note:** Python tools and source JSON files are development tools only. Pokémon Essentials does not execute the Python files.

---

# 12. Summary

The Random Team Generator provides several ways to create Pokémon teams and individual Pokémon builds:

### Random Teams

```ruby
RTG.start(:STEEL_OU, 30)
```

Generate a trainer's party using a predefined criteria set.

### Rental Teams

```ruby
RTG.rent(:ANY_SIX, 30)
```

Generate a team and give it to the player as rental Pokémon.

### Normal Player Teams

```ruby
RTG.give(:ANY_SIX, 30)
```

Generate a team and give it to the player normally.

### Individual Builds

```ruby
build = GameData::PokemonBuild.get(:PB_000030)
pkmn = build.to_pokemon
```

Retrieve and create an individual Pokémon from `pokemon_builds.txt`.

The plugin handles:

* Filtering available Pokémon builds
* Solving team constraints
* Generating Pokémon
* Creating trainer parties
* Creating rental teams
* Creating individual Pokémon
* Managing reusable team criteria
* Converting Smogon sets into PBS data
