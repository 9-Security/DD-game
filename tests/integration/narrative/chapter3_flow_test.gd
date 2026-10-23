extends GdUnitTestSuite
# Integration test: chapter three runs on the real data. The labyrinth opens on day three, either
# name order opens the registry route, and sealing the Kaen name without erasing it opens the exit.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
]
const OATH: String = "「以一人之魂，穩萬民之國；以王嗣之名，續墜星之燈。」"
const WRONG_PLACE: String = "這裡沒有可以進行這個行動的地方。"


func _flow() -> DayOneFlow:
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var events: Array = []
	for path: String in EVENTS_PATHS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		events.append_array(parsed["events"])
	return DayOneFlow.new([{"id": "eron", "name": "艾洛恩", "atk": 10}], [0.0], {
		"events": events,
		"location_requirements": balance["location_requirements"],
		"location_actions": balance["location_actions"],
		"sequences": balance["sequences"],
		"event_flags": {"obsidian_gate_open": true, "passage_entered": true},
	})


## Moves the party to the labyrinth on day three.
func _enter_labyrinth(flow: DayOneFlow) -> void:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")


func test_labyrinth_is_refused_on_day_two() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)

	var message: String = flow.perform("go:咒牆迷廊")

	assert_bool(message.contains("天亮前不宜深入")).is_true()
	assert_str(flow.location()).is_empty()


func test_either_name_order_opens_the_registry_route() -> void:
	var flow := _flow()
	_enter_labyrinth(flow)

	flow.perform("read:second_name")
	assert_bool(flow.event_flag("registry_route_open")).is_false()
	flow.perform("read:first_name")

	assert_bool(flow.event_flag("registry_route_open")).is_true()
	var message: String = flow.perform("go:名冊廊廳")
	assert_str(flow.location()).is_equal("名冊廊廳")
	assert_bool(message.contains("中央的石牆")).is_true()


func test_sealing_keeps_the_name_and_opens_the_exit() -> void:
	var flow := _flow()
	_enter_labyrinth(flow)
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")

	var oath_message: String = flow.perform("read:kaen")
	flow.perform("seal:draw")
	flow.perform("seal:link")
	flow.perform("seal:read")
	var elapsed: int = flow.clock.get_elapsed()
	var seal_message: String = flow.perform("seal:kaen")

	assert_bool(flow.event_flag("kaen_found")).is_true()
	assert_bool(flow.event_flag("chapter3_sealed")).is_true()
	assert_bool(flow.event_flag("dagger_engraved")).is_true()
	assert_bool(seal_message.contains("沒有擦去任何名字")).is_true()
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed)
	assert_bool(oath_message.contains("凱恩")).is_true()

	var exit_message: String = flow.perform("go:出口門廊")
	assert_bool(flow.event_flag("chapter3_exit")).is_true()
	assert_bool(exit_message.contains("植物氣息")).is_true()


func test_oath_is_read_on_entering_the_hall_with_its_original_wording() -> void:
	var flow := _flow()
	_enter_labyrinth(flow)
	flow.perform("read:first_name")
	flow.perform("read:second_name")

	var message: String = flow.perform("go:名冊廊廳")

	assert_bool(flow.event_flag("oath_read")).is_true()
	assert_bool(message.contains(OATH)).is_true()


func test_name_reading_is_refused_outside_its_location_without_spending_time() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	var elapsed: int = flow.clock.get_elapsed()

	var message: String = flow.perform("read:first_name")

	assert_str(message).is_equal(WRONG_PLACE)
	assert_bool(flow.event_flag("path_left_open")).is_false()
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed)
