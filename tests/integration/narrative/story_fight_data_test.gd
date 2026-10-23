extends GdUnitTestSuite
# Integration test: the chapter four and five final steps use the real data. The guardian's
# fight opens on the final step; winning completes it with its event, losing resets the sequence.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
]


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _events() -> Array:
	var events: Array = []
	for path: String in EVENTS_PATHS:
		events.append_array(_json(path)["events"])
	return events


func _flow(event_flags: Dictionary, segments: int) -> DayOneFlow:
	var balance := _json(BALANCE_PATH)
	var flow := DayOneFlow.new([
		{"id": "freya", "name": "f", "atk": 16, "curse": true},
		{"id": "eron", "name": "e", "atk": 8},
		{"id": "richter", "name": "r", "atk": 10},
		{"id": "inry", "name": "i", "atk": 6},
	], [0.0], {
		"sequences": balance["sequences"],
		"location_requirements": balance["location_requirements"],
		"location_actions": balance["location_actions"],
		"events": _events(),
		"battle_enemies": _json(ENEMIES_PATH),
		"event_flags": event_flags,
	})
	flow.clock.spend(segments)
	return flow


func test_the_guardian_core_opens_a_fight_on_the_final_release_step() -> void:
	var flow := _flow({"chapter3_exit": true, "path_to_next_layer_open": true}, DayClock.SEGMENTS_PER_DAY * 3)
	flow.perform("go:失聲之庭")
	flow.perform("commune:tree")
	flow.perform("release:stabilize")
	flow.perform("release:chain_one")
	flow.perform("release:chain_two")

	flow.perform("release:core")

	assert_bool(flow.story_fight_pending()).is_true()
	assert_str(str(flow.story_fight_enemy()["name"])).is_equal("石花巨獸")
	assert_bool(flow.event_flag("guardian_core_broken_safely")).is_false()


func test_winning_the_guardian_fight_completes_the_release() -> void:
	var flow := _flow({"chapter3_exit": true, "path_to_next_layer_open": true}, DayClock.SEGMENTS_PER_DAY * 3)
	flow.perform("go:失聲之庭")
	flow.perform("commune:tree")
	flow.perform("release:stabilize")
	flow.perform("release:chain_one")
	flow.perform("release:chain_two")
	flow.perform("release:core")

	flow.finish_story_fight("won")

	assert_bool(flow.event_flag("guardian_core_broken_safely")).is_true()


func test_losing_the_guardian_fight_resets_the_release_sequence() -> void:
	var flow := _flow({"chapter3_exit": true, "path_to_next_layer_open": true}, DayClock.SEGMENTS_PER_DAY * 3)
	flow.perform("go:失聲之庭")
	flow.perform("commune:tree")
	flow.perform("release:stabilize")
	flow.perform("release:chain_one")
	flow.perform("release:chain_two")
	flow.perform("release:core")

	flow.finish_story_fight("lost")

	assert_bool(flow.event_flag("release_chain_two")).is_false()
	assert_bool(flow.event_flag("guardian_core_broken_safely")).is_false()
