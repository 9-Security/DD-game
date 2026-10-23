extends GdUnitTestSuite
# Integration test: chapter four runs on the real data. The garden opens on day four after the
# labyrinth exit. The guardian is released in order without being killed, and the seed is given.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
]
const GARDEN_REFUSAL: String = "迷廊的出口還沒有走完"
const ORDER_TEXT: String = "重新來過"


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


## Completes chapter three on day three, leaving the flow at the labyrinth exit.
func _finish_chapter_three(flow: DayOneFlow) -> void:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	flow.perform("read:kaen")
	flow.perform("seal:draw")
	flow.perform("seal:link")
	flow.perform("seal:read")
	flow.perform("seal:kaen")
	flow.perform("go:出口門廊")


## Moves to the garden on day four.
func _enter_garden(flow: DayOneFlow) -> void:
	_finish_chapter_three(flow)
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)
	flow.perform("go:失聲之庭")


func test_garden_is_refused_before_the_labyrinth_exit() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 3)

	var message: String = flow.perform("go:失聲之庭")

	assert_bool(message.contains(GARDEN_REFUSAL)).is_true()
	assert_bool(flow.event_flag("garden_entered")).is_false()


func test_entering_the_garden_shows_the_guardian_is_not_hostile() -> void:
	var flow := _flow()
	_enter_garden(flow)

	assert_bool(flow.event_flag("garden_entered")).is_true()
	assert_bool(flow.event_flag("guardian_nonhostility_recognized")).is_true()


func test_release_in_order_breaks_the_core_and_keeps_the_guardian_alive() -> void:
	var flow := _flow()
	_enter_garden(flow)

	flow.perform("commune:tree")
	flow.perform("release:stabilize")
	flow.perform("release:chain_one")
	flow.perform("release:chain_two")
	var message: String = flow.perform("release:core")

	assert_bool(flow.event_flag("guardian_core_broken_safely")).is_true()
	assert_bool(flow.event_flag("translucent_seed_received")).is_true()
	assert_bool(message.contains("黑色晶核碎裂了")).is_true()
	assert_bool(message.contains("神喻草能編織靈魂")).is_true()


func test_a_skipped_step_resets_the_release_and_costs_time_without_a_curse() -> void:
	var flow := _flow()
	_enter_garden(flow)
	flow.perform("commune:tree")
	var elapsed: int = flow.clock.get_elapsed()
	var stacks: int = flow.curse_stacks("freya")

	var message: String = flow.perform("release:chain_one")

	assert_bool(message.contains(ORDER_TEXT)).is_true()
	assert_bool(flow.event_flag("ancient_tree_memory_offered")).is_false()
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed + 1)
	assert_int(flow.curse_stacks("freya")).is_equal(stacks)
