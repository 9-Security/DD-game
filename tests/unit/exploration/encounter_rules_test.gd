extends GdUnitTestSuite
# Unit tests for encounters: which approaches are offered and how each one resolves.

const AFFINITY: Dictionary = {
	"weak_multiplier": 1.5,
	"resist_multiplier": 0.5,
	"matchups": {"purify": {"weak": ["restless_spirit"], "resist": []}},
}
const APPROACH_SKILLS: Dictionary = {
	"persuade": ["beast_speech"],
	"puzzle": ["rune_trap"],
	"summon": ["summon_gray_wolf"],
}


func _entry() -> Dictionary:
	return {
		"id": "spirit_gate",
		"text": "怨靈擋住去路。",
		"enemy_hp": 30,
		"enemy_def": 0,
		"enemy_tags": ["restless_spirit"],
		"approaches": ["combat", "persuade", "puzzle", "summon"],
		"persuade_threshold": 0.5,
	}


func _member(atk: int, tag: String) -> Dictionary:
	return {"atk": atk, "attack_tag": tag, "curse": null, "can_block_berserk": false}


func test_only_approaches_with_a_matching_skill_are_offered() -> void:
	# Arrange
	var encounter := Encounter.new(_entry())

	# Act
	var options := encounter.available(["beast_speech", "rune_trap"], APPROACH_SKILLS)

	# Assert
	assert_bool(options.has("persuade")).is_true()
	assert_bool(options.has("puzzle")).is_true()
	assert_bool(options.has("summon")).is_false()
	assert_bool(options.has("combat")).is_true()


func test_persuade_succeeds_when_roll_meets_threshold() -> void:
	# Arrange
	var encounter := Encounter.new(_entry())

	# Act
	var result := encounter.resolve("persuade", [_member(1, "physical")], [0.9], AFFINITY, {})

	# Assert
	assert_str(result["outcome"]).is_equal("persuaded")


func test_failed_persuade_falls_back_to_a_fight() -> void:
	# Arrange
	var encounter := Encounter.new(_entry())

	# Act
	var result := encounter.resolve("persuade", [_member(40, "physical")], [0.1], AFFINITY, {})

	# Assert
	assert_bool(result["persuade_failed"]).is_true()
	assert_str(result["outcome"]).is_equal("won")


func test_puzzle_is_solved_without_a_fight() -> void:
	# Arrange
	var encounter := Encounter.new(_entry())

	# Act
	var result := encounter.resolve("puzzle", [_member(1, "physical")], [0.0], AFFINITY, {})

	# Assert
	assert_str(result["outcome"]).is_equal("solved")
	assert_int(result["rounds"]).is_equal(0)


func test_summon_adds_one_member_for_the_fight() -> void:
	# Arrange: 1 attack alone needs 30 rounds, but the summon adds 39 per round
	var encounter := Encounter.new(_entry())
	var summon := {"atk": 40, "attack_tag": "light", "curse": null, "can_block_berserk": false}

	# Act
	var result := encounter.resolve("summon", [_member(1, "physical")], [0.0], AFFINITY, summon)

	# Assert
	assert_str(result["outcome"]).is_equal("won")
	assert_int(result["rounds"]).is_equal(1)


func test_combat_reports_weakness_hits() -> void:
	# Arrange: purify against a restless spirit is weak, so each hit counts once
	var encounter := Encounter.new(_entry())

	# Act
	var result := encounter.resolve("combat", [_member(10, "purify")], [0.0], AFFINITY, {})

	# Assert
	assert_int(result["weak_hits"]).is_greater(0)


func test_entry_without_combat_still_needs_enemy_stats_when_a_fight_is_possible() -> void:
	# Arrange
	var bad := _entry()
	bad.erase("enemy_hp")

	# Act
	var errors := Encounter.validate(bad)

	# Assert
	assert_bool(errors.has("enemy_hp must be greater than 0 when a fight is possible")).is_true()
