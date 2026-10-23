extends GdUnitTestSuite
# Integration test: the Heart of the Fallen Star runs on the real data. It opens on day six after
# the stairs. The floating steps, the spirits, the oath truth and the whole herb come in order.
# Plucking a leaf cracks the heart, and the party must take the whole plant.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
	"res://assets/data/events/chapter6.json",
]
const NO_GROUND_TEXT: String = "沒有地面"
const CRACK_TEXT: String = "裂縫"
const OATH_TEXT: String = "以一人之魂，穩萬民之國"


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
		"step_rolls": [],
		"event_flags": {
			"obsidian_gate_open": true, "passage_entered": true, "path_to_next_layer_open": true,
			"descent_stairs_revealed": true, "princess_voice_heard": true,
		},
	})


## Moves to the heart on day six and returns the arrival message.
func _enter_heart(flow: DayOneFlow) -> String:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 5)
	return flow.perform("go:墜星之心")


func _cross(flow: DayOneFlow) -> void:
	flow.perform("cross:test")
	flow.perform("cross:go")


func _listen(flow: DayOneFlow) -> void:
	flow.perform("inry:stop_force")
	flow.perform("inry:listen")


func test_the_heart_is_refused_on_day_five() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 4)

	var message: String = flow.perform("go:墜星之心")

	assert_str(flow.location()).is_empty()
	assert_bool(message.contains("今日還不能抵達")).is_true()


func test_arrival_on_day_six_shows_the_empty_void_and_the_herb() -> void:
	var flow := _flow()

	var message: String = _enter_heart(flow)

	assert_str(flow.location()).is_equal("墜星之心")
	assert_bool(flow.event_flag("heart_entered")).is_true()
	assert_bool(message.contains(NO_GROUND_TEXT)).is_true()


func test_a_skipped_floating_step_resets_the_crossing() -> void:
	var flow := _flow()
	_enter_heart(flow)

	var message: String = flow.perform("cross:go")

	assert_bool(flow.event_flag("steps_crossed")).is_false()
	assert_bool(message.contains("退回原處")).is_true()


func test_the_spirits_need_the_crossing_first() -> void:
	var flow := _flow()
	_enter_heart(flow)

	var message: String = flow.perform("inry:stop_force")

	assert_bool(message.contains("跨過浮空的石階")).is_true()
	assert_bool(flow.event_flag("force_stopped")).is_false()


func test_forcing_the_seal_makes_the_chaos_worse() -> void:
	var flow := _flow()
	_enter_heart(flow)
	_cross(flow)
	var elapsed: int = flow.clock.get_elapsed()

	var message: String = flow.perform("inry:seal_force")

	assert_bool(message.contains("更亂")).is_true()
	assert_bool(flow.event_flag("spirits_listened")).is_false()
	assert_int(flow.clock.get_elapsed()).is_equal(elapsed + 1)


func test_listening_calms_the_spirits_in_order() -> void:
	var flow := _flow()
	_enter_heart(flow)
	_cross(flow)

	_listen(flow)

	assert_bool(flow.event_flag("spirits_listened")).is_true()


func test_the_oath_truth_needs_the_spirits_calmed() -> void:
	var flow := _flow()
	_enter_heart(flow)
	_cross(flow)

	flow.perform("read:oath_truth")

	assert_bool(flow.event_flag("royal_oath_truth_confirmed")).is_false()


func test_the_oath_truth_is_shown_once_the_spirits_are_calm() -> void:
	var flow := _flow()
	_enter_heart(flow)
	_cross(flow)
	_listen(flow)

	var message: String = flow.perform("read:oath_truth")

	assert_bool(flow.event_flag("royal_oath_truth_confirmed")).is_true()
	assert_bool(message.contains(OATH_TEXT)).is_true()


func test_plucking_a_leaf_cracks_the_heart_and_keeps_the_herb() -> void:
	var flow := _flow()
	_enter_heart(flow)
	_cross(flow)
	_listen(flow)
	flow.perform("read:oath_truth")

	var message: String = flow.perform("harvest:pluck")

	assert_bool(message.contains(CRACK_TEXT)).is_true()
	assert_bool(flow.event_flag("herb_secured")).is_false()


func test_taking_the_whole_herb_secures_it_and_the_party_can_return() -> void:
	var flow := _flow()
	_enter_heart(flow)
	_cross(flow)
	_listen(flow)
	flow.perform("read:oath_truth")
	flow.perform("harvest:assess")

	flow.perform("harvest:whole")
	assert_bool(flow.event_flag("herb_seven_leaves_preserved")).is_true()
	assert_bool(flow.event_flag("herb_secured")).is_true()

	flow.perform("return:safe")
	assert_str(flow.location()).is_equal("王宮藥室")
