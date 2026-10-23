extends GdUnitTestSuite
# Unit tests for encounter approaches: an approach is usable when a party member
# owns one of the skills mapped to it. Combat is always available.

const APPROACH_SKILLS: Dictionary = {
	"persuade": ["beast_speech"],
	"puzzle": ["rune_trap", "rune_analysis"],
	"summon": ["summon_gray_wolf"],
}


func test_combat_is_always_available() -> void:
	# Arrange / Act
	var options := ApproachRules.available_approaches(["combat"], [], APPROACH_SKILLS)

	# Assert
	assert_bool(options.has("combat")).is_true()


func test_approach_is_offered_when_a_party_skill_matches() -> void:
	# Arrange / Act
	var options := ApproachRules.available_approaches(["persuade", "puzzle"], ["rune_trap"], APPROACH_SKILLS)

	# Assert
	assert_bool(options.has("puzzle")).is_true()
	assert_bool(options.has("persuade")).is_false()


func test_approach_not_listed_by_encounter_is_never_offered() -> void:
	# Arrange / Act
	var options := ApproachRules.available_approaches(["combat"], ["beast_speech"], APPROACH_SKILLS)

	# Assert
	assert_bool(options.has("persuade")).is_false()
