extends GdUnitTestSuite
# Unit tests for encounter fights played on the interactive battle screen. Combat and summon always
# fight; persuade fights only when the roll fails; puzzles never fight. A retreat keeps the encounter.

const ENCOUNTER: Dictionary = {
	"id": "spirit_gate",
	"name": "怨靈",
	"text": "怨靈擋住去路。",
	"enemy_hp": 30,
	"enemy_def": 0,
	"enemy_atk": 6,
	"enemy_tags": ["restless_spirit"],
	"approaches": ["combat", "persuade", "puzzle"],
	"persuade_threshold": 0.5,
}
const APPROACH_SKILLS: Dictionary = {"persuade": ["beast_speech"]}


func _party() -> Array:
	return [{"id": "eron", "name": "e", "atk": 40}]


func _options(rolls: Array) -> Dictionary:
	return {
		"encounters": [ENCOUNTER],
		"party_skills": {"eron": ["beast_speech"]},
		"approach_skills": APPROACH_SKILLS,
		"encounter_rolls": rolls,
	}


func _started(rolls: Array) -> DayOneFlow:
	var flow := DayOneFlow.new(_party(), [0.0], _options(rolls))
	flow.perform("explore")
	return flow


func test_a_combat_approach_opens_an_interactive_fight() -> void:
	var flow := _started([0.9])

	assert_bool(flow.prepare_encounter_fight("combat")).is_true()


func test_a_puzzle_approach_needs_no_fight() -> void:
	var flow := _started([0.9])

	assert_bool(flow.prepare_encounter_fight("puzzle")).is_false()


func test_a_persuade_that_succeeds_needs_no_fight() -> void:
	var flow := _started([0.9])

	assert_bool(flow.prepare_encounter_fight("persuade")).is_false()


func test_a_persuade_that_fails_opens_a_fight() -> void:
	var flow := _started([0.1])

	assert_bool(flow.prepare_encounter_fight("persuade")).is_true()


func test_the_encounter_enemy_carries_its_stats() -> void:
	var flow := _started([0.9])

	var enemy := flow.encounter_enemy()

	assert_str(str(enemy["name"])).is_equal("怨靈")
	assert_int(int(enemy["hp"])).is_equal(30)
	assert_int(int(enemy["def"])).is_equal(0)
	assert_int(int(enemy["atk"])).is_equal(6)


func test_a_won_fight_clears_the_encounter_and_says_so() -> void:
	var flow := _started([0.9])
	flow.prepare_encounter_fight("combat")

	var message := flow.finish_encounter_fight("won")

	assert_bool(flow.pending_approaches().is_empty()).is_true()
	assert_str(message).contains("戰鬥勝利")


func test_a_fled_fight_keeps_the_encounter_open() -> void:
	var flow := _started([0.9])
	flow.prepare_encounter_fight("combat")

	flow.finish_encounter_fight("fled")

	assert_bool(flow.pending_approaches().is_empty()).is_false()


func test_finishing_a_fight_writes_the_curse_stacks_back() -> void:
	var flow := _started([0.9])
	flow.prepare_encounter_fight("combat")

	flow.finish_encounter_fight("lost", {"freya": 2})

	assert_bool(flow.pending_approaches().is_empty()).is_true()
