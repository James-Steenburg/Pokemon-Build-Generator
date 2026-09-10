#===============================================================================
# Generated Team Criteria
#-------------------------------------------------------------------------------
# Pokémon Essentials v21.1
#
# PBS file:
#   PBS/generated_teams_criterion.txt
#
# Example:
#
# [STEEL_OU]
# team_size = 6
# tier = OU
# mega_limit = 1
# unique_items = true
# no_duplicate_species = true
# monotype = STEEL
#
# The criteria object exposes #options so it can be passed directly to:
#
#   PokemonBuildGenerator.random_team(criteria.team_size, criteria.options)
#
#===============================================================================

module GameData
  class GeneratedTeam
    extend GameData::ClassMethodsSymbols
    include GameData::InstanceMethods

    DATA_FILENAME     = "generated_teams_criterion.dat"
    PBS_BASE_FILENAME = "generated_teams_criterion"
    DATA = {}

    SCHEMA = {
      "SectionName"          => [:id, "s"],
      "team_size"            => [:team_size, "i"],
      "tier"                 => [:tier, "s"],
      "tiers"                => [:tiers, "s"],
      "tag"                  => [:tag, "s"],
      "tags"                 => [:tags, "s"],
      "excluded_tags"        => [:excluded_tags, "s"],
      "excluded_species"     => [:excluded_species, "s"],
      "tag_requirements"     => [:tag_requirements, "s"],
      "tier_requirements"    => [:tier_requirements, "s"],
      "monotype"             => [:monotype, "s"],
      "mega_limit"           => [:mega_limit, "i"],
      "unique_items"         => [:unique_items, "b"],
      "no_duplicate_species"=> [:no_duplicate_species, "b"],
      "legendary"            => [:legendary, "b"],
      "mythical"              => [:mythical, "b"],
      "bst_range"            => [:bst_range, "s"],
      "target_bst"           => [:target_bst, "i"],
      "bst_distribution"     => [:bst_distribution, "s"],
      "bst_targets"          => [:bst_targets, "s"],
      "bst_target_tolerance" => [:bst_target_tolerance, "i"],
      "max_attempts"         => [:max_attempts, "i"]
    }

    attr_reader :id
    attr_reader :team_size
    attr_reader :options

    def initialize(hash)
      @id        = hash[:id]
      @team_size = hash[:team_size] || 6

      # Keep only the options understood by PokemonBuildGenerator.
      @options = hash.dup
      @options.delete(:id)
      @options.delete(:team_size)

      # Normalize values here so callers don't need to know how the PBS
      # representation is stored.
      @options[:tier] = @options[:tier].to_s.upcase.to_sym if @options[:tier]
      @options[:tiers] = Array(@options[:tiers]).map { |v| v.to_s.upcase.to_sym } if @options[:tiers]
      @options[:tag] = @options[:tag].to_s.upcase.to_sym if @options[:tag]
      @options[:tags] = Array(@options[:tags]).map { |v| v.to_s.upcase.to_sym } if @options[:tags]
      @options[:excluded_tags] = Array(@options[:excluded_tags]).map { |v| v.to_s.upcase.to_sym } if @options[:excluded_tags]
      @options[:excluded_species] = Array(@options[:excluded_species]).map { |v| v.to_s.upcase.to_sym } if @options[:excluded_species]
      @options[:monotype] = @options[:monotype].to_s.upcase.to_sym if @options[:monotype]
      @options[:bst_range] = Array(@options[:bst_range]).map(&:to_i) if @options[:bst_range]
      @options[:bst_targets] = Array(@options[:bst_targets]).map(&:to_i) if @options[:bst_targets]
    end
  end
end

#===============================================================================
# Generated Team PBS Compiler
#===============================================================================

module Compiler
  module_function

  #def compile_generated_teams(path = "PBS/generated_teams_criterion.txt")
  def compile_generated_teams(path = nil)
    path = File.join(
      "Plugins",
      "Pokemon Build Generator",
      "PBS",
      "generated_teams_criterion.txt"
    )
    
    #puts "=== Generated Team Compiler ==="
    #puts "Plugin PBS: #{path}"
    #puts "Exists?: #{File.exist?(path)}"

    return unless FileTest.exist?(path)

    # If the compiled file exists and is newer than the PBS file,
    # there is nothing to do.
    dat_file = "Data/generated_teams_criterion.dat"
    if File.exist?(dat_file) && File.mtime(dat_file) >= File.mtime(path)
      return
    end


    GameData::GeneratedTeam::DATA.clear

    File.open(path, "rb") do |f|
      FileLineData.file = path

      pbEachFileSection(f) do |contents, section_name|
        FileLineData.setSection(section_name, nil, nil)

        hash = { :id => section_name.strip.to_sym }

        #-------------------------
        # Basic values
        #-------------------------
        if contents["team_size"]
          with_generated_team_section(section_name, "team_size", contents["team_size"]) do
            hash[:team_size] = contents["team_size"].strip.to_i
          end
        else
          hash[:team_size] = 6
        end

        if contents["tier"]
          with_generated_team_section(section_name, "tier", contents["tier"]) do
            hash[:tier] = contents["tier"].strip.to_sym
          end
        end

        if contents["tiers"]
          with_generated_team_section(section_name, "tiers", contents["tiers"]) do
            hash[:tiers] = parse_generated_team_list(contents["tiers"])
          end
        end

        if contents["tag"]
          with_generated_team_section(section_name, "tag", contents["tag"]) do
            hash[:tag] = contents["tag"].strip.to_sym
          end
        end

        if contents["tags"]
          with_generated_team_section(section_name, "tags", contents["tags"]) do
            hash[:tags] = parse_generated_team_list(contents["tags"])
          end
        end

        if contents["excluded_tags"]
          with_generated_team_section(section_name, "excluded_tags", contents["excluded_tags"]) do
            hash[:excluded_tags] = parse_generated_team_list(contents["excluded_tags"])
          end
        end

        if contents["excluded_species"]
          with_generated_team_section(section_name, "excluded_species", contents["excluded_species"]) do
            hash[:excluded_species] = parse_generated_team_list(contents["excluded_species"])
          end
        end

        if contents["tag_requirements"]
          with_generated_team_section(section_name, "tag_requirements", contents["tag_requirements"]) do
            hash[:tag_requirements] = parse_generated_team_requirements(contents["tag_requirements"])
          end
        else
          hash[:tag_requirements] = {}
        end

        if contents["tier_requirements"]
          with_generated_team_section(section_name, "tier_requirements", contents["tier_requirements"]) do
            hash[:tier_requirements] = parse_generated_team_requirements(contents["tier_requirements"])
          end
        else
          hash[:tier_requirements] = {}
        end

        if contents["monotype"]
          with_generated_team_section(section_name, "monotype", contents["monotype"]) do
            hash[:monotype] = contents["monotype"].strip.to_sym
          end
        end

        if contents["mega_limit"]
          with_generated_team_section(section_name, "mega_limit", contents["mega_limit"]) do
            hash[:mega_limit] = contents["mega_limit"].strip.to_i
          end
        end

        #-------------------------
        # Boolean values
        #-------------------------
        {
          "unique_items"          => :unique_items,
          "no_duplicate_species"  => :no_duplicate_species,
          "legendary"             => :legendary,
          "mythical"              => :mythical
        }.each do |key, symbol|
          if contents[key]
            with_generated_team_section(section_name, key, contents[key]) do
              hash[symbol] = parse_generated_team_bool(contents[key])
            end
          end
        end

        #-------------------------
        # BST values
        #-------------------------
        if contents["bst_range"]
          with_generated_team_section(section_name, "bst_range", contents["bst_range"]) do
            hash[:bst_range] = parse_generated_team_integer_list(contents["bst_range"], 2, "bst_range")
          end
        end

        if contents["target_bst"]
          with_generated_team_section(section_name, "target_bst", contents["target_bst"]) do
            hash[:target_bst] = contents["target_bst"].strip.to_i
          end
        end

        if contents["bst_distribution"]
          with_generated_team_section(section_name, "bst_distribution", contents["bst_distribution"]) do
            hash[:bst_distribution] = parse_generated_team_distribution(contents["bst_distribution"])
          end
        end

        if contents["bst_targets"]
          with_generated_team_section(section_name, "bst_targets", contents["bst_targets"]) do
            hash[:bst_targets] = parse_generated_team_integer_list(contents["bst_targets"], nil, "bst_targets")
          end
        end

        if contents["bst_target_tolerance"]
          with_generated_team_section(section_name, "bst_target_tolerance", contents["bst_target_tolerance"]) do
            hash[:bst_target_tolerance] = contents["bst_target_tolerance"].strip.to_i
          end
        end

        if contents["max_attempts"]
          with_generated_team_section(section_name, "max_attempts", contents["max_attempts"]) do
            hash[:max_attempts] = contents["max_attempts"].strip.to_i
          end
        end

        validate_generated_team(hash)
        GameData::GeneratedTeam.register(hash)
      end
    end

    GameData::GeneratedTeam.save
  end

  def with_generated_team_section(section_name, key, value)
    FileLineData.setSection(section_name, key, value)
    yield
  end

  def parse_generated_team_bool(value)
    case value.strip.downcase
    when "true", "yes", "1"
      true
    when "false", "no", "0"
      false
    else
      raise _INTL("Expected true or false, got '{1}'.", value) +
            "\n" + FileLineData.linereport
    end
  end

  def parse_generated_team_list(value)
    value.split(",").map { |entry| entry.strip }.reject(&:empty?)
  end

  def parse_generated_team_integer_list(value, expected_length, key)
    values = value.split(",").map { |entry| entry.strip.to_i }
    if expected_length && values.length != expected_length
      raise _INTL(
        "{1} must contain exactly {2} values.",
        key,
        expected_length
      ) + "\n" + FileLineData.linereport
    end
    values
  end

  def parse_generated_team_requirements(value)
    result = {}

    value.split(",").each do |entry|
      entry = entry.strip
      next if entry.empty?

      parts = entry.split(":")
      if parts.length != 2
        raise _INTL(
          "Invalid generated team requirement '{1}'. Use NAME:NUMBER.",
          entry
        ) + "\n" + FileLineData.linereport
      end

      key = parts[0].strip
      amount = parts[1].strip.to_i

      if key.empty? || amount <= 0
        raise _INTL(
          "Invalid generated team requirement '{1}'.",
          entry
        ) + "\n" + FileLineData.linereport
      end

      result[key] = amount
    end

    result
  end

  def parse_generated_team_distribution(value)
    values = value.split(",").map { |entry| entry.strip.to_i }

    if values.length == 1
      return values[0]
    end

    if values.length == 2
      return { :min => values[0], :max => values[1] }
    end

    raise _INTL(
      "bst_distribution must be one value or two comma-separated values."
    ) + "\n" + FileLineData.linereport
  end

  def validate_generated_team(hash)
    id = hash[:id]

    if hash[:team_size].to_i < 1 || hash[:team_size].to_i > PokemonBuildGenerator::MAX_TEAM_SIZE
      raise _INTL(
        "Generated team '{1}' has an invalid team_size.",
        id
      ) + "\n" + FileLineData.linereport
    end

    if hash[:tier] && hash[:tiers]
      raise _INTL(
        "Generated team '{1}' cannot use both tier and tiers.",
        id
      ) + "\n" + FileLineData.linereport
    end

    if hash[:tag] && hash[:tags]
      raise _INTL(
        "Generated team '{1}' cannot use both tag and tags.",
        id
      ) + "\n" + FileLineData.linereport
    end

    if hash[:monotype] && !PokemonBuildGenerator::TYPES.include?(hash[:monotype].to_sym)
      raise _INTL(
        "Generated team '{1}' has an unknown monotype '{2}'.",
        id,
        hash[:monotype]
      ) + "\n" + FileLineData.linereport
    end

    if hash[:mega_limit] && hash[:mega_limit] < 0
      raise _INTL(
        "Generated team '{1}' has a negative mega_limit.",
        id
      ) + "\n" + FileLineData.linereport
    end

    if hash[:bst_range]
      unless hash[:bst_range].length == 2 && hash[:bst_range][0] <= hash[:bst_range][1]
        raise _INTL(
          "Generated team '{1}' has an invalid bst_range.",
          id
        ) + "\n" + FileLineData.linereport
      end
    end

    if hash[:bst_distribution]
      if hash[:bst_distribution].is_a?(Hash)
        if hash[:bst_distribution][:min] < 0 || hash[:bst_distribution][:max] < 0
          raise _INTL(
            "Generated team '{1}' has a negative bst_distribution value.",
            id
          ) + "\n" + FileLineData.linereport
        end
      elsif hash[:bst_distribution].to_i < 0
        raise _INTL(
          "Generated team '{1}' has a negative bst_distribution value.",
          id
        ) + "\n" + FileLineData.linereport
      end
    end

    if hash[:bst_targets] && hash[:bst_targets].empty?
      raise _INTL(
        "Generated team '{1}' has empty bst_targets.",
        id
      ) + "\n" + FileLineData.linereport
    end

    if hash[:bst_target_tolerance] && hash[:bst_target_tolerance] < 0
      raise _INTL(
        "Generated team '{1}' has negative bst_target_tolerance.",
        id
      ) + "\n" + FileLineData.linereport
    end

    if hash[:max_attempts] && (hash[:max_attempts] < 1 || hash[:max_attempts] > 1000)
      raise _INTL(
        "Generated team '{1}' has an invalid max_attempts value.",
        id
      ) + "\n" + FileLineData.linereport
    end
  end
end

#===============================================================================
# Add Generated Team compilation to the normal PBS compilation process.
#===============================================================================

module Compiler
  class << self
    unless method_defined?(:generated_teams_original_compile_pbs_files)
      alias generated_teams_original_compile_pbs_files compile_pbs_files
    end

    def compile_pbs_files(*args)
      generated_teams_original_compile_pbs_files(*args)
      compile_generated_teams
    end
  end
end
