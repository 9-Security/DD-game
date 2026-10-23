extends GdUnitTestSuite
# Unit tests for a sequence's final step that is fought on the battle screen. Winning completes the
# step and runs its event; losing resets the sequence and costs its failure time; retreating changes
# nothing. Without an enemy configured the step completes as before.

const SEQUENCE: Dictionary = {
	"id": "seal_test",
	"requires": "",
	"steps": [
		{"action": "first:act", "flag": "first_done"},
		{"action": "last:act", "flag": "last_done"},
	],
	"battle": {"enemy": "beast", "text": "獸擋住了去路。"},
	"failure": {"text": "你們退後重來。", "segments": 1},
	"cost": 1,
}
const EVENT: Dictionary = {
	"id": "last_event",
	"trigger": {"action": "last:act"},
	"conditions": [],
	"effects": [{"type": "set_flag", "flag": "sealed", "value": true}],
}
const ENEMIES: Dictionary = {"beast": {"name": "獸", "hp": 20, "max_hp": 20, "def": 0, "atk": 3}}


func _party() -> Array:
	return [{"id": "eron", "name": "e", "atk": 10}]


func _flow(enemies: Dictionary = ENEMIES) -> DayOneFlow:
	var flow := DayOneFlow.new(_party(), [0.0], {
		"sequences": [SEQUENCE],
		"events": [EVENT],
		"battle_enemies": enemies,
		"location_actions": {"測試地": ["first:act", "last:act"]},
	})
	flow.perform("go:測試地")
	return flow


func test_the_final_step_opens_a_fight_instead_of_succeeding() -> void:
	var flow := _flow()
	flow.perform("first:act")
	var start := flow.clock.get_elapsed()

	var message := flow.perform("last:act")

	assert_str(message).contains("獸擋住了去路")
	assert_bool(flow.story_fight_pending()).is_true()
	assert_bool(flow.event_flag("sealed")).is_false()
	assert_int(flow.clock.get_elapsed()).is_equal(start)


func test_a_non_final_step_never_opens_a_fight() -> void:
	var flow := _flow()

	flow.perform("first:act")

	assert_bool(flow.story_fight_pending()).is_false()


func test_the_fight_enemy_carries_its_stats() -> void:
	var flow := _flow()
	flow.perform("first:act")
	flow.perform("last:act")

	var enemy := flow.story_fight_enemy()

	assert_str(str(enemy["name"])).is_equal("獸")
	assert_int(int(enemy["hp"])).is_equal(20)


func test_winning_completes_the_step_and_runs_its_event() -> void:
	var flow := _flow()
	flow.perform("first:act")
	var start := flow.clock.get_elapsed()
	flow.perform("last:act")

	flow.finish_story_fight("won")

	assert_bool(flow.story_fight_pending()).is_false()
	assert_bool(flow.event_flag("sealed")).is_true()
	assert_int(flow.clock.get_elapsed()).is_equal(start + 1)


func test_losing_resets_the_sequence_and_costs_its_failure_time() -> void:
	var flow := _flow()
	flow.perform("first:act")
	var start := flow.clock.get_elapsed()
	flow.perform("last:act")

	flow.finish_story_fight("lost")

	assert_bool(flow.event_flag("first_done")).is_false()
	assert_bool(flow.event_flag("sealed")).is_false()
	assert_int(flow.clock.get_elapsed()).is_equal(start + 1)


func test_retreating_changes_nothing_and_the_fight_can_be_started_again() -> void:
	var flow := _flow()
	flow.perform("first:act")
	var start := flow.clock.get_elapsed()
	flow.perform("last:act")

	flow.finish_story_fight("fled")

	assert_bool(flow.event_flag("first_done")).is_true()
	assert_bool(flow.event_flag("sealed")).is_false()
	assert_int(flow.clock.get_elapsed()).is_equal(start)
	flow.perform("last:act")
	assert_bool(flow.story_fight_pending()).is_true()


func test_without_a_configured_enemy_the_final_step_completes_as_before() -> void:
	var flow := _flow({})
	flow.perform("first:act")

	flow.perform("last:act")

	assert_bool(flow.story_fight_pending()).is_false()
	assert_bool(flow.event_flag("sealed")).is_true()
