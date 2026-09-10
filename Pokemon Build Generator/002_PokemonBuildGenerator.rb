#===============================================================================
# Pokémon Build Generator
#-------------------------------------------------------------------------------
# Pokémon Essentials v21.1
#
# Provides filtering and constraint-based random team generation for
# GameData::PokemonBuild.
#
# Basic examples:
#
#   PokemonBuildGenerator.random_team(6)
#
#   PokemonBuildGenerator.random_team(
#     6,
#     tier: "OU",
#     mega_limit: 1,
#     unique_items: true,
#     legendary: false,
#     mythical: false,
#     no_duplicate_species: true
#   )
#
#   PokemonBuildGenerator.random_team(
#     6,
#     tiers: ["OU", "UU", "RU"]
#     no_duplicate_species: true
#   )
#   PokemonBuildGenerator.random_team(
#     6,
#     monotype: :WATER,
#     bst_range: [350, 500],
#     no_duplicate_species: true
#   )
#
#   PokemonBuildGenerator.random_team(
#     6,
#     bst_targets: [350, 375, 400, 425, 450, 475]
#   )
#
#   PokemonBuildGenerator.random_team(
#     6,
#     tag_requirements: {
#       "OFFENSIVE" => 2,
#       "DEFENSIVE" => 2
#     }
#   )
#
#===============================================================================

module PokemonBuildGenerator
  MAX_TEAM_SIZE = 6
  DEFAULT_ATTEMPTS = 100
  TYPES = [
    :NORMAL, :FIRE, :WATER, :ELECTRIC, :GRASS, :ICE,
    :FIGHTING, :POISON, :GROUND, :FLYING, :PSYCHIC, :BUG,
    :ROCK, :GHOST, :DRAGON, :DARK, :STEEL, :FAIRY
  ]

  #--------------------------------------------------------------------------
  # Public: filter a supplied list of build IDs.
  #--------------------------------------------------------------------------
  def self.filter(builds = GameData::PokemonBuild.keys, options = {})
    builds = builds.to_a

    builds.select do |build_id|
      build = GameData::PokemonBuild.get(build_id)
      matches_basic_filters?(build, options)
    end
  end

  #--------------------------------------------------------------------------
  # Public: generate a random team of build IDs.
  #--------------------------------------------------------------------------
  def self.random_team(num_of_pokemon, options = {})
    # Temporary Troubleshooting:
    #pbMessage("Initial options:\n#{options.inspect}")

    num_of_pokemon = num_of_pokemon.to_i.clamp(1, MAX_TEAM_SIZE)
    options = normalize_options(options)

    # Temporary Troubleshooting:
    #pbMessage("Normalized options:\n#{options.inspect}")

    validate_options!(num_of_pokemon, options)

    all_builds = GameData::PokemonBuild.keys
    # Temporary Troubleshooting:
    #pbMessage("All builds: #{all_builds.length}")

    candidates = filter(all_builds, options)
    # Temporary Troubleshooting:
    #pbMessage("Candidates: #{candidates.length}")


    if candidates.empty?
      raise_generator_error("No Pokémon Builds match the requested filters.")
    end

    # bst_targets are slot-specific, so solve them together with the other
    # constraints rather than treating them as an ordinary filter.
    if options[:bst_targets]
      return solve_target_distribution(num_of_pokemon, candidates, options)
    end

    solve_team(num_of_pokemon, candidates, options)
  end

  # Alias retained for compatibility with the earlier naming convention.
  def self.random_builds(num_of_builds, options = {})
    random_team(num_of_builds, options)
  end

  #--------------------------------------------------------------------------
  # Public: return the types for a build's species/form.
  #--------------------------------------------------------------------------
  def self.build_types(build)
    species_data = GameData::Species.get_species_form(build.species, build.form)
    Array(species_data.types).map { |type| type.to_sym }
  end

  #--------------------------------------------------------------------------
  # Public: check whether a build is compatible with a mono-type requirement.
  #--------------------------------------------------------------------------
  def self.matches_monotype?(build, type)
    requested_type = type.to_sym
    build_types(build).include?(requested_type)
  rescue StandardError
    false
  end

  #=============================================================================
  # Constraint Solver
  #=============================================================================

  def self.solve_team(team_size, candidates, options)
    attempts = options[:max_attempts]

    attempts.times do
      selected = []
      state = build_initial_state(options)

      if backtrack_select(selected, state, candidates, team_size, options)
        return selected
      end
    end

    raise_generator_error(
      "Unable to create a team of {1} Pokémon satisfying all requested constraints.",
      team_size
    )
  end

  def self.backtrack_select(selected, state, candidates, team_size, options)
    return true if selected.length >= team_size && constraints_satisfied?(selected, state, options)
    return false if selected.length >= team_size

    # A candidate can satisfy several constraints at once. Score candidates
    # by how many currently-unsatisfied requirements they can help satisfy.
    ranked = candidates.shuffle.sort_by do |build_id|
      build = GameData::PokemonBuild.get(build_id)
      -candidate_score(build, state, options)
    end

    ranked.each do |build_id|
      build = GameData::PokemonBuild.get(build_id)
      next unless candidate_allowed?(build, selected, state, options)

      add_to_state(build, state, selected, options)

      if state_still_possible?(selected, state, candidates, team_size, options) &&
         backtrack_select(selected, state, candidates, team_size, options)
        return true
      end

      remove_from_state(build, state, selected, options)
    end

    false
  end

  #=============================================================================
  # Candidate Filtering
  #=============================================================================

  def self.matches_basic_filters?(build, options)
    return false unless matches_tier_filter?(build, options)
    return false unless matches_tag_filter?(build, options)
    return false unless matches_excluded_filters?(build, options)
    return false unless matches_special_status_filters?(build, options)
    return false unless matches_bst_filter?(build, options)
    return false unless matches_monotype_filter?(build, options)
    true
  end

  def self.matches_tier_filter?(build, options)
    if options[:tier]
      return false unless normalize_string(build.tier) == normalize_string(options[:tier])
    end

    if options[:tiers]
      tiers = options[:tiers].map { |tier| normalize_string(tier) }
      return false unless tiers.include?(normalize_string(build.tier))
    end

    true
  end

  def self.matches_tag_filter?(build, options)
    tag = normalize_string(build.tag)

    if options[:tag]
      return false unless tag == normalize_string(options[:tag])
    end

    if options[:tags]
      tags = options[:tags].map { |value| normalize_string(value) }
      return false unless tags.include?(tag)
    end

    true
  end

  def self.matches_excluded_filters?(build, options)
    if options[:excluded_tags]
      excluded = options[:excluded_tags].map { |tag| normalize_string(tag) }
      return false if excluded.include?(normalize_string(build.tag))
    end

    if options[:excluded_species]
      excluded = options[:excluded_species].map { |species| normalize_string(species) }
      return false if excluded.include?(normalize_string(build.species))
    end

    true
  end

  #--------------------------------------------------------------------------
  # Legendary/Mythical filters use the flags defined in the Pokémon species
  # data (pokemon.txt). This avoids maintaining a separate species list.
  #--------------------------------------------------------------------------
  def self.matches_special_status_filters?(build, options)
    return true if options[:legendary].nil? && options[:mythical].nil?

    species_data = GameData::Species.get_species_form(build.species, build.form)

    if !options[:legendary].nil?
      is_legendary = species_data.has_flag?("Legendary")
      return false unless is_legendary == options[:legendary]
    end

    if !options[:mythical].nil?
      is_mythical = species_data.has_flag?("Mythical")
      return false unless is_mythical == options[:mythical]
    end

    true
  rescue StandardError
    false
  end

  def self.matches_bst_filter?(build, options)
    bst = build.total_base_stats.to_i

    if options[:bst_range]
      min_bst, max_bst = options[:bst_range]
      return false if bst < min_bst || bst > max_bst
    end

    if options[:target_bst]
      distribution = options[:bst_distribution]
      if distribution.is_a?(Hash)
        min_bst = options[:target_bst] - distribution[:min]
        max_bst = options[:target_bst] + distribution[:max]
      else
        distribution = distribution.to_i
        min_bst = options[:target_bst] - distribution
        max_bst = options[:target_bst] + distribution
      end
      return false if bst < min_bst || bst > max_bst
    end

    true
  end

  def self.matches_monotype_filter?(build, options)
    return true unless options[:monotype]
    matches_monotype?(build, options[:monotype])
  end

  #--------------------------------------------------------------------------
  # A build is considered a Mega Pokémon when its held item is a Mega Stone.
  # Mega Stones in the generated PBS data use the standard *ITE naming
  # convention (e.g. CHARIZARDITE, LUCARIONITE). EVIOLITE is explicitly
  # excluded because it is not a Mega Stone.
  #--------------------------------------------------------------------------
  def self.mega_build?(build)
    item = normalize_string(build.item)
    !item.empty? && item.end_with?("ITE") && item != "EVIOLITE"
  end

  def self.build_has_item?(build)
    !normalize_string(build.item).empty?
  end

  #=============================================================================
  # State / Requirements
  #=============================================================================

  def self.build_initial_state(options)
    {
      used_species: {},
      used_items: {},
      mega_count: 0,
      tag_counts: Hash.new(0),
      tier_counts: Hash.new(0)
    }
  end

  def self.candidate_allowed?(build, selected, state, options)
    if options[:no_duplicate_species]
      species = normalize_string(build.species)
      return false if state[:used_species][species]
    end

    if options[:unique_items] && build_has_item?(build)
      item = normalize_string(build.item)
      return false if state[:used_items][item]
    end

    if !options[:mega_limit].nil? && mega_build?(build)
      return false if state[:mega_count] >= options[:mega_limit]
    end

    true
  end

  def self.add_to_state(build, state, selected, options)
    selected << build.id

    species = normalize_string(build.species)
    state[:used_species][species] = true

    if build_has_item?(build)
      item = normalize_string(build.item)
      state[:used_items][item] = true
    end

    state[:mega_count] += 1 if mega_build?(build)
    state[:tag_counts][normalize_string(build.tag)] += 1
    state[:tier_counts][normalize_string(build.tier)] += 1
  end

  def self.remove_from_state(build, state, selected, options)
    selected.pop

    species = normalize_string(build.species)
    state[:used_species].delete(species)

    if build_has_item?(build)
      item = normalize_string(build.item)
      state[:used_items].delete(item)
    end

    state[:mega_count] -= 1 if mega_build?(build)

    tag = normalize_string(build.tag)
    state[:tag_counts][tag] -= 1

    tier = normalize_string(build.tier)
    state[:tier_counts][tier] -= 1
  end

  #=============================================================================
  # Constraint Satisfaction
  #=============================================================================

  def self.constraints_satisfied?(selected, state, options)
    return false unless tag_requirements_satisfied?(state, options)
    return false unless tier_requirements_satisfied?(state, options)
    true
  end

  def self.tag_requirements_satisfied?(state, options)
    options[:tag_requirements].all? do |tag, required|
      state[:tag_counts][normalize_string(tag)] >= required
    end
  end

  def self.tier_requirements_satisfied?(state, options)
    options[:tier_requirements].all? do |tier, required|
      state[:tier_counts][normalize_string(tier)] >= required
    end
  end

  def self.state_still_possible?(selected, state, candidates, team_size, options)
    slots_left = team_size - selected.length
    return false if slots_left < 0

    return false unless requirement_still_possible?(state[:tag_counts], options[:tag_requirements], candidates, selected, slots_left, :tag)
    return false unless requirement_still_possible?(state[:tier_counts], options[:tier_requirements], candidates, selected, slots_left, :tier)

    if options[:no_duplicate_species]
      remaining_species = candidates.map { |id| normalize_string(GameData::PokemonBuild.get(id).species) }
      remaining_species = remaining_species.uniq.reject { |species| state[:used_species][species] }
      return false if remaining_species.length < slots_left && selected.length < team_size
    end

    true
  end

  def self.requirement_still_possible?(counts, requirements, candidates, selected, slots_left, dimension)
    requirements.each do |requirement, needed|
      key = normalize_string(requirement)
      current = counts[key]
      next if current >= needed

      remaining_needed = needed - current
      possible = candidates.count do |build_id|
        build = GameData::PokemonBuild.get(build_id)
        value = dimension == :tag ? build.tag : build.tier
        normalize_string(value) == key && !selected.include?(build_id)
      end

      return false if possible < remaining_needed
      return false if remaining_needed > slots_left
    end

    true
  end

  def self.candidate_score(build, state, options)
    score = 0

    options[:tag_requirements].each do |tag, required|
      key = normalize_string(tag)
      if normalize_string(build.tag) == key && state[:tag_counts][key] < required
        score += 10 + (required - state[:tag_counts][key])
      end
    end

    options[:tier_requirements].each do |tier, required|
      key = normalize_string(tier)
      if normalize_string(build.tier) == key && state[:tier_counts][key] < required
        score += 10 + (required - state[:tier_counts][key])
      end
    end

    # When using a BST target, favor candidates near the requested average.
    if options[:target_bst]
      distance = (build.total_base_stats.to_i - options[:target_bst]).abs
      score += [10 - (distance / 10), 0].max
    end

    score
  end

  #=============================================================================
  # Slot-specific BST Targets
  #=============================================================================

  def self.solve_target_distribution(team_size, candidates, options)
    targets = options[:bst_targets].dup
    targets = targets.first(team_size) if targets.length > team_size

    if targets.length < team_size
      raise_generator_error(
        "bst_targets must contain at least {1} values for a team of that size.",
        team_size
      )
    end

    # Each target is treated as an approximate target. The tolerance can be
    # specified with :bst_target_tolerance; otherwise 25 BST is used.
    tolerance = options[:bst_target_tolerance]

    best_team = nil
    best_score = Float::INFINITY

    options[:max_attempts].times do
      shuffled_targets = targets.first(team_size).shuffle
      selected = []
      state = build_initial_state(options)
      score = solve_target_slots(
        shuffled_targets,
        0,
        candidates,
        selected,
        state,
        options,
        tolerance,
        0
      )

      if score && score < best_score
        best_score = score
        best_team = selected.dup
        break if best_score == 0
      end
    end

    return best_team if best_team

    raise_generator_error(
      "Unable to create a team satisfying the requested BST distribution."
    )
  end

  def self.solve_target_slots(targets, index, candidates, selected, state, options, tolerance, score)
    return score if index >= targets.length && constraints_satisfied?(selected, state, options)
    return nil if index >= targets.length

    target = targets[index].to_i
    ranked = candidates.shuffle.sort_by do |build_id|
      build = GameData::PokemonBuild.get(build_id)
      (build.total_base_stats.to_i - target).abs
    end

    ranked.each do |build_id|
      build = GameData::PokemonBuild.get(build_id)
      distance = (build.total_base_stats.to_i - target).abs
      next if tolerance && distance > tolerance
      next unless candidate_allowed?(build, selected, state, options)

      add_to_state(build, state, selected, options)
      result = solve_target_slots(
        targets,
        index + 1,
        candidates,
        selected,
        state,
        options,
        tolerance,
        score + distance
      )
      return result if result
      remove_from_state(build, state, selected, options)
    end

    nil
  end

  #=============================================================================
  # Option Handling
  #=============================================================================

  def self.normalize_options(options)
    options = options.dup

    options[:tags] = Array(options[:tags]) if options[:tags]
    options[:tiers] = Array(options[:tiers]) if options[:tiers]
    options[:excluded_tags] = Array(options[:excluded_tags]) if options[:excluded_tags]
    options[:excluded_species] = Array(options[:excluded_species]) if options[:excluded_species]

    if !options[:legendary].nil?
      options[:legendary] = !!options[:legendary]
    end
    if !options[:mythical].nil?
      options[:mythical] = !!options[:mythical]
    end

    unless options[:mega_limit].nil?
      options[:mega_limit] = options[:mega_limit].to_i
    end
    options[:unique_items] = !!options[:unique_items] unless options[:unique_items].nil?

    options[:tag_requirements] = normalize_requirements(options[:tag_requirements])
    options[:tier_requirements] = normalize_requirements(options[:tier_requirements])

    if options[:monotype]
      options[:monotype] = options[:monotype].to_sym
    end

    if options[:bst_range]
      options[:bst_range] = options[:bst_range].map(&:to_i)
    end

    if options[:target_bst]
      options[:target_bst] = options[:target_bst].to_i
      options[:bst_distribution] = 50 if options[:bst_distribution].nil?

      if options[:bst_distribution].is_a?(Hash)
        options[:bst_distribution] = {
          min: options[:bst_distribution][:min].to_i,
          max: options[:bst_distribution][:max].to_i
        }
      else
        options[:bst_distribution] = options[:bst_distribution].to_i
      end
    end

    if options[:bst_targets]
      options[:bst_targets] = options[:bst_targets].map(&:to_i)
      options[:bst_target_tolerance] = 25 if options[:bst_target_tolerance].nil?
      options[:bst_target_tolerance] = options[:bst_target_tolerance].to_i
    end

    options[:max_attempts] = (options[:max_attempts] || DEFAULT_ATTEMPTS).to_i.clamp(1, 1000)
    options
  end

  def self.normalize_requirements(requirements)
    return {} unless requirements

    requirements.each_with_object({}) do |(key, value), result|
      result[key.to_s] = value.to_i
    end.reject { |_key, value| value <= 0 }
  end

  def self.validate_options!(team_size, options)
    if options[:bst_range]
      unless options[:bst_range].length == 2 && options[:bst_range][0] <= options[:bst_range][1]
        raise_generator_error("bst_range must be [minimum, maximum].")
      end
    end

    if options[:monotype] && !TYPES.include?(options[:monotype].to_sym)
      raise_generator_error("Unknown Pokémon type '{1}'.", options[:monotype])
    end

    if options[:bst_targets]
      if options[:bst_targets].empty?
        raise_generator_error("bst_targets cannot be empty.")
      end
      if options[:bst_target_tolerance] < 0
        raise_generator_error("bst_target_tolerance cannot be negative.")
      end
    end

    if !options[:mega_limit].nil? && options[:mega_limit] < 0
      raise_generator_error("mega_limit cannot be negative.")
    end

    required_tags = options[:tag_requirements].values.sum
    required_tiers = options[:tier_requirements].values.sum
    if required_tags > team_size && options[:tag_requirements].keys.length == 1
      # A single tag requirement cannot consume more slots than the team has.
      raise_generator_error("Tag requirements require more Pokémon than the team size.")
    end
    if required_tiers > team_size && options[:tier_requirements].keys.length == 1
      raise_generator_error("Tier requirements require more Pokémon than the team size.")
    end
  end

  def self.normalize_string(value)
    value.to_s.upcase
  end

  def self.raise_generator_error(message, *args)
    if defined?(_INTL)
      raise _INTL(message, *args)
    end
    raise format(message, *args)
  end
end