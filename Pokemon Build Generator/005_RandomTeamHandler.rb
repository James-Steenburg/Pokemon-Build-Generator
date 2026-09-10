#===============================================================================
# Random Team Generator - Trainer Load Handler
#===============================================================================

EventHandlers.add(:on_trainer_load, :RANDOM_TEAM_GENERATOR,
  proc { |trainer|
    next unless trainer
    next unless RandomTeamGenerator.pending?

    #Console.echo_li("=== Generated Team Criteria Debug ===")
    #Console.echo_li("WEAKER_RANDOM exists?: #{GameData::GeneratedTeamCriteria.exists?(:WEAKER_RANDOM)}")
    #Console.echo_li("Available criteria:")
    #
    #GameData::GeneratedTeamCriteria.each do |criteria|
    #  Console.echo_li("  #{criteria.id}")
    #end

    criteria_id = RandomTeamGenerator.criteria

    begin
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

      trainer.party.clear

      builds.each do |build_id|
        next unless GameData::PokemonBuild.exists?(build_id)

        build = GameData::PokemonBuild.get(build_id)
        pkmn = build.to_pokemon

        pkmn.level = RandomTeamGenerator.level
        pkmn.owner.id = $player.make_foreign_ID
        pkmn.owner.name = "Battle Tower"
        pkmn.cannot_store = true
        pkmn.cannot_trade = true
        pkmn.cannot_release = true
        pkmn.poke_ball = :RENTALBALL
        pkmn.calc_stats

        trainer.party.push(pkmn)
      end
    ensure
      # Criteria are one-shot. This prevents the selection from leaking into
      # a later trainer if generation fails.
      RandomTeamGenerator.clear
    end
  }
)
