extends GdUnitTestSuite
# Integration test: the Blood Oath Cavern runs on the real data. The father's record comes first,
# then the guard. Breaking the oath needs the steps in order. A wrong step or striking the guard
# resets the seal and adds a curse stack. The stairs open only after the seal breaks.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
]
const RELIC_TEXT: String = "亡父之骨不是遺物，而是刑具。"
const SEAL_TEXT: String = "我不再替王室守這個謊。"
const GUARD_WAIT_TEXT: String = "守衛還沒有甦醒。"
const SEAL_WAIT_TEXT: String = "通道還被封在石地之下。"
const RESET_TEXT: String = "退後重來"
const VOICE_TEXT: String = "請不要救我"


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
		"event_flags": {"obsidian_gate_open": true, "passage_entered": true, "path_to_next_layer_open": true},
	})


## Moves to the furnace on day five and returns the arrival message.
func _enter_furnace(flow: DayOneFlow) -> String:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 4)
	return flow.perform("go:血誓熔窟")


func _read_record(flow: DayOneFlow) -> void:
	_enter_furnace(flow)
	flow.perform("read:father_record")


func test_the_record_shows_the_father_and_the_guard_wakes() -> void:
	var flow := _flow()
	_enter_furnace(flow)

	var message: String = flow.perform("read:father_record")

	assert_bool(flow.event_flag("father_record_read")).is_true()
	assert_bool(message.contains(RELIC_TEXT)).is_true()
	assert_bool(message.contains("空盔甲正在聚合")).is_true()


func test_striking_the_guard_before_it_wakes_is_refused() -> void:
	var flow := _flow()
	_enter_furnace(flow)

	var message: String = flow.perform("oath:strike")

	assert_str(message).is_equal(GUARD_WAIT_TEXT)
	assert_int(flow.curse_stacks("freya")).is_equal(0)


func test_striking_the_guard_adds_a_curse_stack_and_resets_the_seal() -> void:
	var flow := _flow()
	_read_record(flow)
	flow.perform("oath:lower")
	var stacks: int = flow.curse_stacks("freya")

	var message: String = flow.perform("oath:strike")

	assert_bool(message.contains(RESET_TEXT)).is_true()
	assert_bool(flow.event_flag("freya_lowered")).is_false()
	assert_int(flow.curse_stacks("freya")).is_equal(stacks + 1)


func test_breaking_the_oath_in_order_weakens_the_curse_without_curing_it() -> void:
	var flow := _flow()
	_read_record(flow)
	for index: int in range(3):
		flow.perform("oath:strike")
	flow.perform("oath:lower")
	flow.perform("oath:cover")
	flow.perform("oath:barrier")
	flow.perform("oath:chain")

	var message: String = flow.perform("oath:pierce")

	assert_bool(flow.event_flag("oath_seal_broken")).is_true()
	assert_bool(flow.event_flag("blood_oath_armor_destroyed")).is_true()
	assert_bool(flow.event_flag("father_bone_fragment_recovered")).is_true()
	assert_bool(message.contains(SEAL_TEXT)).is_true()
	assert_int(flow.curse_stacks("freya")).is_equal(1)


func test_lowering_the_sword_again_after_a_reset_replays_its_text() -> void:
	var flow := _flow()
	_read_record(flow)
	flow.perform("oath:lower")
	flow.perform("oath:pierce")

	var message: String = flow.perform("oath:lower")

	assert_bool(message.contains("放下亡父之骨")).is_true()


func test_piercing_before_the_chains_is_a_wrong_step() -> void:
	var flow := _flow()
	_read_record(flow)
	flow.perform("oath:lower")
	flow.perform("oath:cover")
	var stacks: int = flow.curse_stacks("freya")

	var message: String = flow.perform("oath:pierce")

	assert_bool(message.contains(RESET_TEXT)).is_true()
	assert_bool(flow.event_flag("oath_seal_broken")).is_false()
	assert_bool(flow.event_flag("freya_lowered")).is_false()
	assert_int(flow.curse_stacks("freya")).is_equal(stacks + 1)


func test_striking_the_guard_names_the_next_step_as_a_hint() -> void:
	var flow := _flow()
	_read_record(flow)

	var message: String = flow.perform("oath:strike")

	assert_bool(message.contains("提示")).is_true()
	assert_bool(message.contains("放下亡父之骨")).is_true()


func test_the_stairs_are_closed_until_the_seal_breaks() -> void:
	var flow := _flow()
	_read_record(flow)

	var message: String = flow.perform("descend:stairs")

	assert_str(message).is_equal(SEAL_WAIT_TEXT)
	assert_bool(flow.event_flag("princess_voice_heard")).is_false()


func test_the_stairs_on_day_five_play_the_voice_and_keep_the_novel_line() -> void:
	var flow := _flow()
	_read_record(flow)
	flow.perform("oath:lower")
	flow.perform("oath:cover")
	flow.perform("oath:barrier")
	flow.perform("oath:chain")
	flow.perform("oath:pierce")

	var message: String = flow.perform("descend:stairs")

	assert_bool(flow.event_flag("princess_voice_heard")).is_true()
	assert_bool(flow.event_flag("descent_stairs_revealed")).is_true()
	assert_bool(message.contains(VOICE_TEXT)).is_true()
	assert_bool(message.contains("第五日，尚未結束")).is_true()


func test_the_stairs_after_day_five_do_not_claim_day_five() -> void:
	var flow := _flow()
	_read_record(flow)
	flow.perform("oath:lower")
	flow.perform("oath:cover")
	flow.perform("oath:barrier")
	flow.perform("oath:chain")
	flow.perform("oath:pierce")
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)

	var message: String = flow.perform("descend:stairs")

	assert_bool(message.contains(VOICE_TEXT)).is_true()
	assert_bool(message.contains("第五日，尚未結束")).is_false()
