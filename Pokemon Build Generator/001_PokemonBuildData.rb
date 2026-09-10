#===============================================================================
# Pokémon Build Data
#-------------------------------------------------------------------------------
# Pokémon Essentials v21.1
#
# PBS file:
#   PBS/pokemon_builds.txt
#
# Example:
#
# [PB_000001]
# species = IVYSAUR
# form = 0
# tier = NFE
# tag = DEFENSIVE
# item = EVIOLITE
# nature = BOLD
# ability = CHLOROPHYLL
# evs = 252, 0, 252, 0, 4, 0
# ivs = 31, 31, 31, 31, 31, 31
# moves = KNOCKOFF, SLUDGEBOMB, GIGADRAIN, SYNTHESIS
# total_base_stats = 405
#
# Usage:
#
#   pkmn = GameData::PokemonBuild.get(:PB_000001).to_pokemon
#   pbAddPokemon(pkmn)
#
#===============================================================================

module GameData
  class PokemonBuild
    extend GameData::ClassMethodsSymbols
    include GameData::InstanceMethods

    DATA_FILENAME     = "pokemon_builds.dat"
    PBS_BASE_FILENAME = "pokemon_builds"
    DATA = {}

    SCHEMA = {
      "SectionName"      => [:id, "s"],
      "species"          => [:species, "s"],
      "form"             => [:form, "i"],
      "tier"             => [:tier, "s"],
      "tag"              => [:tag, "s"],
      "item"             => [:item, "s"],
      "nature"           => [:nature, "s"],
      "ability"          => [:ability, "s"],
      "evs"               => [:evs, "s"],
      "ivs"               => [:ivs, "s"],
      "moves"             => [:moves, "s"],
      "total_base_stats"  => [:total_base_stats, "i"]
    }

    attr_reader :id, :species, :form, :tier, :tag, :item, :nature
    attr_reader :ability, :evs, :ivs, :moves, :total_base_stats

    def initialize(hash)
      @id               = hash[:id]
      @species          = hash[:species]
      @form             = hash[:form] || 0
      @tier             = hash[:tier]
      @tag              = hash[:tag]
      @item             = hash[:item]
      @nature            = hash[:nature]
      @ability           = hash[:ability]
      @evs               = hash[:evs] || [0, 0, 0, 0, 0, 0]
      @ivs               = hash[:ivs] || [31, 31, 31, 31, 31, 31]
      @moves             = hash[:moves] || []
      @total_base_stats  = hash[:total_base_stats]
    end

    # Creates a level-100 Pokémon by default using this build's settings.
    def to_pokemon(level = 100)
      species_data = begin
        GameData::Species.get_species_form(@species, @form)
      rescue StandardError
        raise _INTL(
          "Pokemon build {1} uses an invalid form {2} for {3}.",
          @id,
          @form,
          @species
        )
      end

      pokemon = Pokemon.new(@species, level)
      pokemon.form = @form.to_i

      # Item
      pokemon.item = @item if @item && !@item.empty?

      # Nature
      pokemon.nature = (@nature && !@nature.empty?) ? @nature : :DOCILE

      # Ability
      ability_data = GameData::Ability.try_get(@ability)
      if ability_data
        ability_id = ability_data.id
        if species_data.abilities.include?(ability_id)
          pokemon.ability_index = species_data.abilities.index(ability_id)
        elsif species_data.hidden_abilities.include?(ability_id)
          pokemon.ability_index = species_data.abilities.length
        else
          pokemon.ability_index = 0
        end
      else
        pokemon.ability_index = 0
      end

      # IVs
      iv_array = normalize_stat_array(@ivs, 31, Pokemon::IV_STAT_LIMIT)
      pokemon.iv[:HP]              = iv_array[0]
      pokemon.iv[:ATTACK]          = iv_array[1]
      pokemon.iv[:DEFENSE]         = iv_array[2]
      pokemon.iv[:SPECIAL_ATTACK]  = iv_array[3]
      pokemon.iv[:SPECIAL_DEFENSE] = iv_array[4]
      pokemon.iv[:SPEED]           = iv_array[5]

      # EVs
      ev_array = normalize_stat_array(@evs, 0, Pokemon::EV_STAT_LIMIT)
      if ev_array.sum > Pokemon::EV_LIMIT
        # Preserve the old fallback behavior for malformed/over-budget builds.
        ev_array = [252, 0, 4, 0, 0, 252]
      end

      pokemon.ev[:HP]              = ev_array[0]
      pokemon.ev[:ATTACK]          = ev_array[1]
      pokemon.ev[:DEFENSE]         = ev_array[2]
      pokemon.ev[:SPECIAL_ATTACK]  = ev_array[3]
      pokemon.ev[:SPECIAL_DEFENSE] = ev_array[4]
      pokemon.ev[:SPEED]           = ev_array[5]

      # Moves
      pokemon.forget_all_moves
      @moves.each { |move_id| pokemon.learn_move(move_id) }

      pokemon.calc_stats
      pokemon
    end

    private

    def normalize_stat_array(values, default, maximum)
      values = Array(values)
      values = Array.new(6, default) if values.length != 6
      values.map { |value| [[value.to_i, 0].max, maximum].min }
    end
  end
end

#===============================================================================
# Pokémon Build PBS Compiler
#===============================================================================

module Compiler
  module_function

  def compile_pokemon_builds(path = nil)
    path = File.join(
      "Plugins",
      "Pokemon Build Generator",
      "PBS",
      "pokemon_builds.txt"
    )

    raise "PokemonBuild PBS file not found: #{path}" unless FileTest.exist?(path)

    dat_file = "Data/pokemon_builds.dat"
    if File.exist?(dat_file) && File.mtime(dat_file) >= File.mtime(path)
      return
    end


    GameData::PokemonBuild::DATA.clear

    File.open(path, "rb") do |f|
      FileLineData.file = path

      pbEachFileSection(f) do |contents, section_name|
        FileLineData.setSection(section_name, nil, nil)

        hash = { :id => section_name.strip.to_sym }

        required_value(contents, section_name, "species") do |value|
          hash[:species] = parse_species_value(value)
        end

        if contents["form"]
          with_section(section_name, "form", contents["form"]) do
            hash[:form] = contents["form"].strip.to_i
          end
        else
          hash[:form] = 0
        end

        if contents["tier"]
          with_section(section_name, "tier", contents["tier"]) do
            hash[:tier] = contents["tier"].strip.to_sym
          end
        end

        if contents["tag"]
          with_section(section_name, "tag", contents["tag"]) do
            hash[:tag] = contents["tag"].strip.to_sym
          end
        end

        if contents["item"]
          with_section(section_name, "item", contents["item"]) do
            hash[:item] = parse_item_value(contents["item"])
          end
        end

        if contents["nature"]
          with_section(section_name, "nature", contents["nature"]) do
            hash[:nature] = parse_nature_value(contents["nature"])
          end
        end

        if contents["ability"]
          with_section(section_name, "ability", contents["ability"]) do
            hash[:ability] = parse_ability_value(contents["ability"])
          end
        end

        if contents["evs"]
          with_section(section_name, "evs", contents["evs"]) do
            hash[:evs] = parse_stat_array(contents["evs"])
          end
        else
          hash[:evs] = [0, 0, 0, 0, 0, 0]
        end

        if contents["ivs"]
          with_section(section_name, "ivs", contents["ivs"]) do
            hash[:ivs] = parse_stat_array(contents["ivs"])
          end
        else
          hash[:ivs] = [31, 31, 31, 31, 31, 31]
        end

        if contents["moves"]
          with_section(section_name, "moves", contents["moves"]) do
            hash[:moves] = parse_move_array(contents["moves"])
          end
        else
          hash[:moves] = []
        end

        if contents["total_base_stats"]
          with_section(section_name, "total_base_stats", contents["total_base_stats"]) do
            hash[:total_base_stats] = contents["total_base_stats"].strip.to_i
          end
        end

        validate_pokemon_build(hash)
        GameData::PokemonBuild.register(hash)
      end
    end

    GameData::PokemonBuild.save
  end

  def with_section(section_name, key, value)
    FileLineData.setSection(section_name, key, value)
    yield
  end

  def required_value(contents, section_name, key)
    unless contents[key]
      raise _INTL(
        "Build '{1}' has no {2}.",
        section_name.strip.to_sym,
        key
      ) + "\n" + FileLineData.linereport
    end

    with_section(section_name, key, contents[key]) { yield contents[key] }
  end

  def parse_species_value(value)
    species = value.strip.to_sym
    unless GameData::Species.exists?(species)
      raise _INTL("Undefined species '{1}'.", species) + "\n" + FileLineData.linereport
    end
    species
  end

  def parse_item_value(value)
    value = value.strip
    return nil if value.empty?

    item = value.to_sym
    unless GameData::Item.exists?(item)
      raise _INTL("Undefined item '{1}'.", item) + "\n" + FileLineData.linereport
    end
    item
  end

  def parse_nature_value(value)
    nature = value.strip.to_sym
    return :DOCILE unless GameData::Nature.exists?(nature)
    nature
  end

  def parse_ability_value(value)
    ability = value.strip.to_sym
    unless GameData::Ability.exists?(ability)
      raise _INTL("Undefined ability '{1}'.", ability) + "\n" + FileLineData.linereport
    end
    ability
  end

  def parse_move_array(value)
    moves = value.split(",").map { |move| move.strip.to_sym }
    moves.each do |move|
      unless GameData::Move.exists?(move)
        raise _INTL("Undefined move '{1}'.", move) + "\n" + FileLineData.linereport
      end
    end
    moves
  end

  def parse_stat_array(value)
    values = value.split(",").map { |v| v.strip.to_i }
    if values.length != 6
      raise _INTL("Expected exactly 6 stat values, got {1}.", values.length) +
            "\n" + FileLineData.linereport
    end
    values
  end

  def validate_pokemon_build(hash)
    if hash[:evs]
      hash[:evs].each do |ev|
        if ev < 0 || ev > Pokemon::EV_STAT_LIMIT
          raise _INTL("Invalid EV value '{1}' in build '{2}'.", ev, hash[:id]) +
                "\n" + FileLineData.linereport
        end
      end

      total_evs = hash[:evs].sum
      if total_evs > Pokemon::EV_LIMIT
        raise _INTL(
          "EV total for build '{1}' is {2}, which exceeds the limit of {3}.",
          hash[:id], total_evs, Pokemon::EV_LIMIT
        ) + "\n" + FileLineData.linereport
      end
    end

    if hash[:ivs]
      hash[:ivs].each do |iv|
        if iv < 0 || iv > Pokemon::IV_STAT_LIMIT
          raise _INTL("Invalid IV value '{1}' in build '{2}'.", iv, hash[:id]) +
                "\n" + FileLineData.linereport
        end
      end
    end

    if hash[:moves].length > 4
      raise _INTL("Build '{1}' has more than 4 moves.", hash[:id]) +
            "\n" + FileLineData.linereport
    end

    if hash[:moves].length != hash[:moves].uniq.length
      raise _INTL("Build '{1}' contains duplicate moves.", hash[:id]) +
            "\n" + FileLineData.linereport
    end

    if hash[:total_base_stats] && hash[:total_base_stats] < 0
      raise _INTL("Build '{1}' has an invalid total_base_stats value.", hash[:id]) +
            "\n" + FileLineData.linereport
    end
  end
end

#===============================================================================
# Add Pokémon Build compilation to the normal PBS compilation process.
#===============================================================================

module Compiler
  class << self
    unless method_defined?(:pokemon_builds_original_compile_pbs_files)
      alias pokemon_builds_original_compile_pbs_files compile_pbs_files
    end

    def compile_pbs_files(*args)
      pokemon_builds_original_compile_pbs_files(*args)
      compile_pokemon_builds
    end
  end
end
