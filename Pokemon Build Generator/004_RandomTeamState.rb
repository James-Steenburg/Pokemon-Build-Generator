#===============================================================================
# Random Team Generator - Temporary Runtime State
#===============================================================================
# This is intentionally module-owned runtime state rather than save data.
#
# Event Script example:
#
#   RandomTeamGenerator.criteria = :STEEL_OU
#
# The next trainer loaded by the Random Team Handler consumes the criteria.
#===============================================================================

module RandomTeamGenerator
  @criteria_id = nil
  @level = 100

  def self.start(criteria, level = 100)
    @criteria_id = criteria.nil? ? nil : criteria.to_sym
    @level = level.to_i.clamp(1, 100)
  end

  def self.criteria=(criteria_id)
    @criteria_id = criteria_id.nil? ? nil : criteria_id.to_sym
  end

  def self.criteria
    @criteria_id
  end

  def self.pending?
    !@criteria_id.nil?
  end

  def self.level
    @level
  end

  def self.clear
    @criteria_id = nil
    @level = 100
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

    # Clear Player's party
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
    
    # Clear Player's party
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
end

# Short event-friendly alias
RTG = RandomTeamGenerator