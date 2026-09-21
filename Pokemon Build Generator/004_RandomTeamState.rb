#===============================================================================
# Random Team Generator - Temporary Runtime State
#===============================================================================
# This is intentionally module-owned runtime state rather than save data.
#
# Existing event script:
#   RTG.start(:STEEL_OU, 30)
#
# Mixed-team event script:
#   RTG.start(
#     :PB_000001,
#     :PB_000002,
#     :PB_000003,
#     RTG.random(:STEEL_OU, 3),
#     level: 30,
#     exclude_species: true
#   )
#===============================================================================

module RandomTeamGenerator
  @criteria_id = nil
  @level = 100
  @mixed_entries = nil
  @exclude_species = true

  #--------------------------------------------------------------------------
  # Start a standard criteria-based team or a mixed fixed/random team.
  #
  # Legacy:
  #   RTG.start(:STEEL_OU, 30)
  #
  # Mixed:
  #   RTG.start(:PB_000001, RTG.random(:STEEL_OU, 5), level: 30)
  #--------------------------------------------------------------------------
  def self.start(*entries, level: nil, exclude_species: true)
    # Preserve the original API: RTG.start(criteria_id, level)
    if entries.length.between?(1, 2) &&
       entries[0].is_a?(Symbol) &&
       (entries.length == 1 || entries[1].is_a?(Numeric)) &&
       level.nil?
      @criteria_id = entries[0].to_sym
      @level = (entries[1] || 100).to_i.clamp(1, 100)
      @mixed_entries = nil
      @exclude_species = true
      return
    end

    @criteria_id = nil
    @level = (level || 100).to_i.clamp(1, 100)
    @mixed_entries = entries
    @exclude_species = !!exclude_species
  end

  def self.random(criteria_id, count = 1)
    {
      type: :random,
      criteria: criteria_id.to_sym,
      count: count.to_i
    }
  end

  def self.criteria=(criteria_id)
    @criteria_id = criteria_id.nil? ? nil : criteria_id.to_sym
    @mixed_entries = nil
  end

  def self.criteria
    @criteria_id
  end

  def self.pending?
    !@criteria_id.nil? || mixed?
  end

  def self.mixed?
    !@mixed_entries.nil?
  end

  def self.entries
    @mixed_entries || []
  end

  def self.exclude_species?
    @exclude_species
  end

  def self.level
    @level
  end

  def self.clear
    @criteria_id = nil
    @level = 100
    @mixed_entries = nil
    @exclude_species = true
  end

  def self.give(criteria_id, level = 100)
    generate_player_party(criteria_id, level)
  end

  # Helper for Generating a Party for the Player
  def self.generate_player_party(criteria_id, level = 100)
    criteria_id = criteria_id.to_sym
    level = level.to_i.clamp(1, 100)

    unless GameData::GeneratedTeam.exists?(criteria_id)
      raise _INTL(
        "Undefined generated team criteria '{1}'.",
        criteria_id
      )
    end

    $player.party.clear
    criteria = GameData::GeneratedTeam.get(criteria_id)

    builds = PokemonBuildGenerator.random_team(
      criteria.team_size,
      criteria.options
    )

    builds.each do |build_id|
      next unless GameData::PokemonBuild.exists?(build_id)

      build = GameData::PokemonBuild.get(build_id)
      pkmn = build.to_pokemon
      pkmn.level = level
      pkmn.calc_stats
      $player.party.push(pkmn)
    end

    builds
  end

  def self.rent(criteria_id, level = 100)
    generate_player_rental_party(criteria_id, level)
  end

  # Helper for Generating a Rental Party for the Player
  def self.generate_player_rental_party(criteria_id, level = 100)
    criteria_id = criteria_id.to_sym
    level = level.to_i.clamp(1, 100)

    unless GameData::GeneratedTeam.exists?(criteria_id)
      raise _INTL(
        "Undefined generated team criteria '{1}'.",
        criteria_id
      )
    end

    $player.party.clear
    criteria = GameData::GeneratedTeam.get(criteria_id)

    builds = PokemonBuildGenerator.random_team(
      criteria.team_size,
      criteria.options
    )

    builds.each do |build_id|
      next unless GameData::PokemonBuild.exists?(build_id)

      build = GameData::PokemonBuild.get(build_id)
      pkmn = build.to_pokemon

      pkmn.owner.id = $player.make_foreign_ID
      pkmn.owner.name = "Battle Tower"
      pkmn.cannot_store = true
      pkmn.cannot_trade = true
      pkmn.cannot_release = true
      pkmn.poke_ball = :RENTALBALL
      pkmn.level = level
      pkmn.calc_stats

      $player.party.push(pkmn)
    end

    builds
  end

  def self.rand_arr(criteria_id, level = 100)
    generate_builds_array(criteria_id, level)
  end

  # Helper for Generating a Build array
  def self.generate_builds_array(criteria_id, level = 100)
    criteria_id = criteria_id.to_sym
    level = level.to_i.clamp(1, 100)

    unless GameData::GeneratedTeam.exists?(criteria_id)
      raise _INTL(
        "Undefined generated team criteria '{1}'.",
        criteria_id
      )
    end

    criteria = GameData::GeneratedTeam.get(criteria_id)

    PokemonBuildGenerator.random_team(
      criteria.team_size,
      criteria.options
    )
  end

  def self.store(criteria_id, level = 100)
    store_build_party(criteria_id, level)
  end

  # Helper for Generating a Party for the Player
  def self.store_build_party(criteria_id, level = 100)
    criteria_id = criteria_id.to_sym
    level = level.to_i.clamp(1, 100)

    unless GameData::GeneratedTeam.exists?(criteria_id)
      raise _INTL(
        "Undefined generated team criteria '{1}'.",
        criteria_id
      )
    end

    criteria = GameData::GeneratedTeam.get(criteria_id)

    builds = PokemonBuildGenerator.random_team(
      criteria.team_size,
      criteria.options
    )

    builds.each do |build_id|
      next unless GameData::PokemonBuild.exists?(build_id)

      build = GameData::PokemonBuild.get(build_id)
      pkmn = build.to_pokemon
      pkmn.level = level
      pkmn.calc_stats
      pbStorePokemon(pkmn)
    end

    builds
  end
end

# Short event-friendly alias
RTG = RandomTeamGenerator
