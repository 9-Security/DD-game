extends GdUnitTestSuite
# Integration test: the Kaen seal is solved by collaboration in a fixed order. A wrong step
# resets the seal, costs one segment, and adds one blood curse stack to Freya.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
]
const ORDER_TEXT: String = "線條失去平衡"
const NAME_FIRST_TEXT: String = "你還沒有辨認凱恩的名字。"


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


## Moves to the registry hall on day three with both names read and Kaen's name found.
func _reach_hall_with_kaen(flow: DayOneFlow) -> void:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	flow.perform("read:kaen")


func test_steps_in_order_seal_the_name_and_open_the_exit() -> void:
	var flow := _flow()
	_reach_hall_with_kaen(flow)

	flow.perform("seal:draw")
	flow.perform("seal:link")
	flow.perform("seal:read")
	var message: String = flow.perform("seal:kaen")

	assert_bool(flow.event_flag("chapter3_sealed")).is_true()
	assert_bool(flow.event_flag("dagger_engraved")).is_true()
	assert_bool(message.contains("沒有擦去任何名字")).is_true()


func test_a_wrong_step_resets_the_seal_and_costs_time_and_a_curse_stack() -> void:
	var flow := _flow()
	_reach_hall_with_kaen(flow)
	flow.perform("seal:draw")
	var elapsed: int = flow.clock.get_elapsed()
	var stacks: int = flow.curse_stacks("freya")

	var message: String = flow.perform("seal:read")

	assert_bool(message.contains(ORDER_TEXT)).is_true()
	assert_bool(flow.event_flag("seal_drawn")).is_false()
	assert_bool(flow.event_flag("seal_failed")).is_true()
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed + 1)
	assert_int(flow.curse_stacks("freya")).is_equal(stacks + 1)


func test_a_seal_that_was_never_failed_does_not_set_the_flag() -> void:
	var flow := _flow()
	_reach_hall_with_kaen(flow)

	flow.perform("seal:draw")

	assert_bool(flow.event_flag("seal_failed")).is_false()


func test_kaen_seal_before_its_name_is_read_is_refused_without_penalty() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	var elapsed: int = flow.clock.get_elapsed()
	var stacks: int = flow.curse_stacks("freya")

	var message: String = flow.perform("seal:draw")

	assert_str(message).is_equal(NAME_FIRST_TEXT)
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed)
	assert_int(flow.curse_stacks("freya")).is_equal(stacks)


func test_redoing_a_step_after_a_reset_replays_its_text() -> void:
	var flow := _flow()
	_reach_hall_with_kaen(flow)
	flow.perform("seal:draw")
	flow.perform("seal:read")

	var message: String = flow.perform("seal:draw")

	assert_bool(message.contains("光靈")).is_true()


func test_repeating_a_finished_step_costs_nothing() -> void:
	var flow := _flow()
	_reach_hall_with_kaen(flow)
	flow.perform("seal:draw")
	var elapsed: int = flow.clock.get_elapsed()

	var message: String = flow.perform("seal:draw")

	assert_bool(message.contains("已經完成")).is_true()
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed)
	assert_bool(flow.event_flag("seal_drawn")).is_true()
