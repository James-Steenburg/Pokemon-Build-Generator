# ===============================================================================
# Random Team Generator
#
# Pokémon Essentials v21.1 — Implementation Guide
# ===============================================================================
# This guide explains how to install and use the Random Team Generator plugin in a Pokémon Essentials v21.1 project.
#
#
# ===============================================================================  
# 1. Install the Plugin
# =============================================================================== 
# Copy the Plugin folder Pokemon Build Generator into your Project's Plugins folder.
# Copy the Pokemon Build Generator/Graphics folder to your Project's Graphics folder.
# 
# 
# -------------------------------------------------------------------------------
# What is included:
# 
# The scripts should be loaded in this order:
# 001_PokemonBuildData.rb
# 002_PokemonBuildGenerator.rb
# 003_GeneratedTeamData.rb
# 004_RandomTeamState.rb
# 005_RandomTeamHandler.rb
# 
# 
# The plugin also requires these PBS files:
# 
# PBS/
# ├── pokemon_builds.txt
# └── generated_teams_criterion.txt
# 
# - pokemon_builds.txt contains the individual Pokémon builds that can be selected.
# - generated_teams_criterion.txt defines the rules used when creating a random team.
# 
# 
# The plugin also references these Graphics files where are expected to be in your Project's Graphics folder:
# 
# Graphics/
# ├── Battle animations
#     ├── ball_RENTALBALL.png
#     └── ball_RENTALBALL_open.png
# └── Items
#     └── RENTALBALL.png
# 
#
# A Tools folder is also included for converting Smogon Sets/ json files to PBS format. 
# There are a few sample source files included. 
# Note: these files are not used by Pokemon Essentials and can be deleted if preferred.   
#
# Tools/
# ├── Py_ConvertSmogonToPBS.py
# ├── pokemon_builds.txt
# ├── SmogonSource8.txt
# ├── SmogonSource9.txt
# └── SmogonSourceSample.txt
#
#
# =============================================================================== 
# 2. Create Team Criteria
# =============================================================================== 
# Open: PBS/generated_teams_criterion.txt
# 
# Each section defines one set of rules that can be used to generate a team. This ruleset can be reused as often as you would like
# 
# For example:
# 
# [STEEL_OU]
# team_size = 6
# tier = OU
# monotype = STEEL
# mega_limit = 1
# unique_items = true
# no_duplicate_species = true
# 
# This creates a criteria set named:
# 
# STEEL_OU
# 
# It tells the generator to create:
# 
# * A team of 6 Pokémon
# * Only Pokémon in the OU tier
# * Only Steel-type Pokémon
# * No more than 1 Mega Pokémon
# * No duplicate held items
# * No duplicate species
# 
# You can create as many criteria sections as you want.
# =============================================================================== 
# 3. Available Criteria
# =============================================================================== 
# The generator supports the following settings:
# 
# -------------------------------------------------------------------------------
# 3.1. Team (Required)
# 
#   Size: 1 to 6
# 
# -------------------------------------------------------------------------------
# 3.2. Tier (Optional)
#
#   Currently Supported Tiers (See Smogon for more info.)
#       OU, UU, RU, NU, PU, ZU
#       NFE, LC, UBERS, MONOTYPE, DOUBLES
#       VGC, OTHER
# 
#   Use one tier:
#       tier = OU
# 
#   Or several tiers:
#       tiers = OU, UU, RU
#
# -------------------------------------------------------------------------------
# 3.3. Tags (Optional)
# 
#   Require a specific tag:
#       tag = OFFENSIVE
#   Or allow several:
#       tags = OFFENSIVE, DEFENSIVE, SUPPORT
#   You can also exclude tags:
#       excluded_tags = SUPPORT
#
# -------------------------------------------------------------------------------
# 3.4. Species Restrictions (Optional)
#
#   Exclude specific Pokémon:
#       excluded_species = BLISSEY, CHANSEY
# 
# -------------------------------------------------------------------------------
# 3.5. Monotype (Optional) 
#
#   Require every selected Pokémon to have the specified type:
#       monotype = WATER
#   
#   Valid types are:
#       NORMAL
#       FIRE
#       WATER
#       ELECTRIC
#       GRASS
#       ICE
#       FIGHTING
#       POISON
#       GROUND
#       FLYING
#       PSYCHIC
#       BUG
#       ROCK
#       GHOST
#       DRAGON
#       DARK
#       STEEL
#       FAIRY
# 
# -------------------------------------------------------------------------------
# 3.6. Mega Pokémon (Optional)
#   
#   Limit the number of Mega Pokémon:
#       mega_limit = 1
#   Or prevents Mega Pokémon from being selected.
#       mega_limit = 0
#
# -------------------------------------------------------------------------------
# 3.7. Duplicate Items (Optional)
#
#   Prevent multiple Pokémon from holding the same item:
#      unique_items = true
#
# -------------------------------------------------------------------------------
# 3.8. Duplicate Species (Optional)
#
#   Prevent the same species from appearing more than once:
#      no_duplicate_species = true
#
# -------------------------------------------------------------------------------
# 3.9. Legendary and Mythical Pokémon (Optional)
#
#   Only Legendary Pokémon:
#       legendary = true
#   Exclude Legendary Pokémon:
#       legendary = false
#   Only Mythical Pokémon:
#       mythical = true
#   Exclude Mythical Pokémon:
#       mythical = false
#
# -------------------------------------------------------------------------------
# 3.10. Base Stat Total Restrictions (Optional)
#
#   You can restrict Pokémon by Base Stat Total.
#
#   BST Range
#       bst_range = 400, 500
#           (Only Pokémon with a BST between 400 and 500 can be selected.)
#
#   This can be useful for creating intentionally weaker teams:
#       
#       [WEAK_TEAM]
#       team_size = 6
#       bst_range = 300, 400
#       no_duplicate_species = true
#
# -------------------------------------------------------------------------------
# 3.11. BST Targets (Optional)
#
#   You can also specify a desired BST for each team slot.
#       bst_targets = 350, 375, 400, 425, 450, 475
#   The generator attempts to find Pokémon close to those values.
#   You can control the acceptable difference with:
#       bst_target_tolerance = 25
#   For example, a target of 400 with a tolerance of 25 allows Pokémon with BSTs from approximately 375–425.
#
# -------------------------------------------------------------------------------
# 3.12. Tag Requirements (Optional)
#
#   You can require a minimum number of Pokémon with particular tags.
#       tag_requirements = OFFENSIVE:2, DEFENSIVE:2
#
#   For example:
#
#       [BALANCED_TEAM]
#       team_size = 6
#       tier = OU
#       no_duplicate_species = true
#       tag_requirements = OFFENSIVE:2, DEFENSIVE:2
#
#   This requires at least:
#       * 2 Offensive Pokémon
#       * 2 Defensive Pokémon
#   The remaining two Pokémon can have any valid tag.
#
# -------------------------------------------------------------------------------
# 3.13. Tier Requirements (Optional)
#
#   You can similarly require specific numbers of Pokémon from particular tiers.
#       tier_requirements = OU:3, UU:2
#
#   For example:
#
#       [MIXED_TEAM]
#       team_size = 6
#       tiers = OU, UU, RU
#       no_duplicate_species = true
#       tier_requirements = OU:3, UU:2
#
#   This guarantees at least 3 OU Pokémon and 2 UU Pokémon.
#
# =============================================================================== 
# 4. Using a Criteria Set in an RPG Maker Event
# =============================================================================== 
#
#   Once your criteria have been created, you can select them from an RPG Maker event.
#   
#   Add a **Script** command to your event:
#       RandomTeamGenerator.start(:STEEL_OU,30)
#           The numeric second argument sets the level of the Pokémon being generated. 
#   
#   Or you can short-hand it:
#       RTG.start(:STEEL_OU,30)
#
#   Then start the trainer battle normally.
#
#   For example:
#       Script：
#           RTG.start(:STEEL_OU,30)
#           Trainer Battle：Camper
#   
#   The plugin will see that `STEEL_OU` was selected and automatically generate the trainer's party when the trainer is loaded.
#
# ===============================================================================
# 5. Reusing the Same Trainer
# ===============================================================================
#
#   The same trainer can therefore be used with different criteria.
#
#   For example:
#       Script：
#           RandomTeamGenerator.start(:STEEL_OU,30)
#           Trainer Battle：GeneratedMale
#
#       Later:
#       Script：
#           RandomTeamGenerator.start(:MIXED_TEAM,30)
#           Trainer Battle：GeneratedMale
#
#   The trainer type remains the same; only the generation criteria changes.
#
# ===============================================================================
# 11. Creating Your Own Presets
# ===============================================================================
# 
#   A good way to organize a project is to create presets for common battle types.
#
#   For example:
#       [STANDARD_OU]
#       team_size = 6
#       tier = OU
#       no_duplicate_species = true
#       unique_items = true
#       
#       [MONO_FIRE]
#       team_size = 6
#       monotype = FIRE
#       no_duplicate_species = true
#       
#       [WEAK_TRAINER]
#       team_size = 3
#       bst_range = 250, 400
#       no_duplicate_species = true
#       
#       [ELITE_TRAINER]
#       team_size = 6
#       tier = OU
#       mega_limit = 1
#       unique_items = true
#       no_duplicate_species = true
#       tag_requirements = OFFENSIVE:2, DEFENSIVE:2
#
#   Then your RPG Maker events only need to select the appropriate preset.
#
# ===============================================================================
# 12. Important: Criteria Are One-Time
# ===============================================================================
#
#   The criteria selected by:
#       RandomTeamGenerator.start(:STEEL_OU,30)
#
#   is intended for the **next generated trainer**.
#   After the trainer's party is generated, the plugin clears the criteria automatically.
#   This means you don't need to manually reset it after every battle.
#
# ===============================================================================
# 13. Troubleshooting
# ===============================================================================
#
#   "Undefined generated team criteria"
#   If you see an error such as:
#       Undefined generated team criteria 'STEEL_OU'
#
#   check that `PBS/generated_teams.txt` contains:
#       [STEEL_OU]
#   and that the PBS files have been recompiled.
#
# -------------------------------------------------------------------------------
#   No Pokémon Builds Match
#   If generation fails with:
#       No Pokémon Builds match the requested filters.
#   Your criteria are probably too restrictive.
#   For example, this may be impossible:
#       team_size = 6
#       monotype = ICE
#       tier = OU
#       legendary = true
#       mega_limit = 0
#   Try relaxing one or more restrictions.
#
# -------------------------------------------------------------------------------
#   Unable to Create a Team
#
#   If the generator reports that it cannot satisfy the requested constraints, check combinations such as:
#       no_duplicate_species = true
#       unique_items = true
#       tag_requirements = ...
#       tier_requirements = ...
#       bst_range = ...
#
#   The constraint solver must find a single team satisfying **all** of the requested rules.
#
# ===============================================================================
# 14. Quick Example - Team Generation
# ===============================================================================
# PBS
#
#   [ANY_SIX]
#   team_size = 6
#
#   [STEEL_ELITE]
#   team_size = 6
#   monotype = STEEL
#   tier = OU
#   mega_limit = 1
#   unique_items = true
#   no_duplicate_species = true
#   tag_requirements = OFFENSIVE:2, DEFENSIVE:2
#
# RPG Maker Event
#
#   Script：
#       RTG.start(:STEEL_ELITE,100)
#       Trainer Battle：GeneratedM
#
#   Or to create a team of any six pokemon at level 30 with no requirements as a rental team to the player:
#       RTG.rent(:ANY_SIX,30)
#   To give the player any six but not as rental pokemon, use:
#       RTG.give(:ANY_SIX,30)
#
# ===============================================================================
# 14. Quick Example - Singular Builds
# ===============================================================================
# PBS 
#
#   Below is an example build derived from Smogon using the Python convert script
#   Builds may be called by their key, then converted to the pkmn object for further use as seen below.
#      
#   build = GameData::PokemonBuild.get(:PB_000030)
#   pkmn = build.to_pokemon
#
#   [PB_000030]
#   species = PIKACHU
#   form = 0
#   tier = NFE
#   tag = OFFENSIVE
#   item = LIGHTBALL
#   nature = TIMID
#   ability = LIGHTNINGROD
#   evs = 0, 0, 0, 252, 4, 252
#   ivs = 31, 31, 31, 31, 31, 31
#   moves = THUNDERBOLT, SURF, VOLTSWITCH, KNOCKOFF
#   total_base_stats = 320
#
#   
# ===============================================================================
#   That's all that is required.
#   The plugin handles 
#       filtering the available Pokémon builds, 
#       solving the constraints, 
#       generating the Pokémon, 
#       and assigning the resulting team to the trainer.
