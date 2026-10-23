extends GdUnitTestSuite
# Integration test: a save taken in the middle of chapter three (after a seal failure) restores
# the location, the failure flag, and the seal progress, and the party can finish the seal.
# The snapshot is passed through JSON, as the save file does.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
]


func _flow() -> DayOneFlow:
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var events: Array = []
	for path: String in EVENTS_PATHS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		events.append_array(parsed["events"])
	return DayOneFlow.new([
		{"id": "freya", "name": "芙蕾雅", "atk": 10, "curse": true},
		{"id": "eron", "name": "艾洛恩", "atk": 10},
	], [0.0], {
		"events": events,
		"location_requirements": balance["location_requirements"],
		"location_actions": balance["location_actions"],
		"sequences": balance["sequences"],
		"event_flags": {"obsidian_gate_open": true, "passage_entered": true},
	})


func test_a_mid_seal_save_restores_progress_and_the_seal_can_finish() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	flow.perform("read:kaen")
	flow.perform("seal:link")
	flow.perform("seal:draw")
	# The save file is JSON, so numbers come back as floats. Go through JSON like the real save.
	var data: Dictionary = JSON.parse_string(JSON.stringify(flow.snapshot()))

	var restored := _flow()
	var ok: bool = restored.restore(data)

	assert_bool(ok).is_true()
	assert_str(restored.location()).is_equal("名冊廊廳")
	assert_bool(restored.event_flag("seal_failed")).is_true()
	assert_bool(restored.event_flag("seal_drawn")).is_true()
	assert_bool(restored.step_done("seal:draw")).is_true()
	restored.perform("seal:link")
	restored.perform("seal:read")
	var message: String = restored.perform("seal:kaen")
	assert_bool(restored.event_flag("chapter3_sealed")).is_true()
	assert_bool(message.contains("沒有擦去任何名字")).is_true()
