extends GdUnitTestSuite
# Unit tests for encounters inside the day-one flow.

const ENCOUNTER: Dictionary = {
	"id": "spirit_gate",
	"text": "怨靈擋住去路。",
	"enemy_hp": 30,
	"enemy_def": 0,
	"enemy_tags": ["restless_spirit"],
	"approaches": ["combat", "persuade"],
	"persuade_threshold": 0.5,
}
const APPROACH_SKILLS: Dictionary = {"persuade": ["beast_speech"]}


func _party() -> Array:
	return [{"id": "eron", "name": "e", "atk": 40}]


func _options(extra: Dictionary = {}) -> Dictionary:
	var options := {
		"encounters": [ENCOUNTER],
		"party_skills": {"eron": ["beast_speech"]},
		"approach_skills": APPROACH_SKILLS,
		"encounter_rolls": [0.9],
	}
	options.merge(extra, true)
	return options


func test_explore_starts_an_encounter_and_lists_its_approaches() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], _options())

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_bool(message.contains("怨靈擋住去路。")).is_true()
	assert_bool(flow.pending_approaches().has("persuade")).is_true()


func test_other_actions_are_refused_while_an_encounter_is_pending() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], _options())
	flow.perform("explore")
	var segment_before := flow.clock.segment

	# Act
	var message := flow.perform("move")

	# Assert
	assert_bool(message.contains("請先選擇應對方式")).is_true()
	assert_int(flow.clock.segment).is_equal(segment_before)


func test_choosing_an_offered_approach_resolves_and_clears_the_encounter() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], _options())
	flow.perform("explore")

	# Act
	var message := flow.perform("approach:persuade")

	# Assert
	assert_bool(message.contains("說服")).is_true()
	assert_int(flow.pending_approaches().size()).is_equal(0)


func test_an_approach_that_is_not_offered_is_refused() -> void:
	# Arrange: summon is not in the encounter's list
	var flow := DayOneFlow.new(_party(), [0.0], _options())
	flow.perform("explore")

	# Act
	var message := flow.perform("approach:summon")

	# Assert
	assert_bool(message.contains("無法使用")).is_true()
	assert_bool(flow.pending_approaches().has("combat")).is_true()


func test_a_won_combat_encounter_grants_trust() -> void:
	# Arrange
	var trust := TrustBoard.new(["eron"], 50, 0, 100)
	var flow := DayOneFlow.new(_party(), [0.0], _options({"trust": trust, "trust_gain": 10}))
	flow.perform("explore")

	# Act
	flow.perform("approach:combat")

	# Assert
	assert_int(trust.get_trust("eron")).is_equal(60)


func test_encounters_are_used_in_order_and_not_repeated() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], _options())
	flow.perform("explore")
	flow.perform("approach:persuade")

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_bool(message.contains("怨靈擋住去路。")).is_false()
