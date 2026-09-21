#===============================================================================
# Random Team Generator - Trainer Load Handler
#===============================================================================

module RandomTeamGenerator
  module_function

  def build_to_pokemon(build_id, level)
    unless GameData::PokemonBuild.exists?(build_id)
      raise _INTL("Undefined Pokémon Build '{1}'.", build_id)
    end

    build = GameData::PokemonBuild.get(build_id)
    pkmn = build.to_pokemon

    pkmn.level = level
    pkmn.owner.id = $player.make_foreign_ID
    pkmn.owner.name = "Battle Tower"
    pkmn.cannot_store = true
    pkmn.cannot_trade = true
    pkmn.cannot_release = true
    pkmn.poke_ball = :RENTALBALL
    pkmn.calc_stats
    pkmn
  end

  def fixed_build_species(entries)
    entries.filter_map do |entry|
      next unless entry.is_a?(Symbol) || entry.is_a?(String)
      next unless GameData::PokemonBuild.exists?(entry.to_sym)

      GameData::PokemonBuild.get(entry.to_sym).species.to_sym
    end.uniq
  end

  def mixed_team_build_ids(entries, level, exclude_species)
    fixed_entries = entries.select do |entry|
      entry.is_a?(Symbol) || entry.is_a?(String)
    end

    random_entries = entries.select do |entry|
      entry.is_a?(Hash) && entry[:type] == :random
    end

    total_count = fixed_entries.length + random_entries.sum { |entry| entry[:count].to_i }
    if total_count > PokemonBuildGenerator::MAX_TEAM_SIZE
      raise _INTL(
        "A generated team cannot contain more than {1} Pokémon.",
        PokemonBuildGenerator::MAX_TEAM_SIZE
      )
    end

    excluded_species = exclude_species ? fixed_build_species(fixed_entries) : []
    builds = fixed_entries.map(&:to_sym)

    random_entries.each do |entry|
      criteria_id = entry[:criteria].to_sym
      count = entry[:count].to_i
      next if count <= 0

      unless GameData::GeneratedTeam.exists?(criteria_id)
        raise _INTL(
          "Undefined generated team criteria '{1}'.",
          criteria_id
        )
      end

      criteria = GameData::GeneratedTeam.get(criteria_id)
      options = criteria.options.dup

      if exclude_species
        existing_exclusions = Array(options[:excluded_species])
        options[:excluded_species] =
          (existing_exclusions + excluded_species).uniq
      end

      generated = PokemonBuildGenerator.random_team(count, options)
      builds.concat(generated)
    end

    builds
  end
end

EventHandlers.add(:on_trainer_load, :RANDOM_TEAM_GENERATOR,
  proc { |trainer|
    next unless trainer
    next unless RandomTeamGenerator.pending?

    begin
      if RandomTeamGenerator.mixed?
        builds = RandomTeamGenerator.mixed_team_build_ids(
          RandomTeamGenerator.entries,
          RandomTeamGenerator.level,
          RandomTeamGenerator.exclude_species?
        )
      else
        criteria_id = RandomTeamGenerator.criteria

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
      end

      trainer.party.clear

      builds.each do |build_id|
        next unless GameData::PokemonBuild.exists?(build_id)

        trainer.party.push(
          RandomTeamGenerator.build_to_pokemon(
            build_id,
            RandomTeamGenerator.level
          )
        )
      end
    ensure
      # Requests are one-shot so they cannot leak into a later trainer.
      RandomTeamGenerator.clear
    end
  }
)
