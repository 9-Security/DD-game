extends GdUnitTestSuite
# Integration test: chapter seven and the three endings on the real data. The stairs advance the
# story to day six. The return has a safe route and a shortcut; the shortcut's risk makes ending C.
# The common line needs the evidence, the orders, the explanation and Liana's consent, in order.
# Ending A needs the king's own step; ending B needs the four earlier results. A and B exclude
# each other, and once an ending is reached no further action is possible.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
	"res://assets/data/events/chapter6.json",
	"res://assets/data/events/chapter7.json",
]


func _flow(step_rolls: Array, extra_flags: Dictionary = {}) -> DayOneFlow:
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var events: Array = []
	for path: String in EVENTS_PATHS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		events.append_array(parsed["events"])
	var flags: Dictionary = {
		"obsidian_gate_open": true, "passage_entered": true, "path_to_next_layer_open": true,
		"descent_stairs_revealed": true,
	}
	flags.merge(extra_flags)
	return DayOneFlow.new([
		{"id": "freya", "name": "芙蕾雅", "atk": 10, "curse": true},
		{"id": "eron", "name": "艾洛恩", "atk": 10},
	], [0.0], {
		"events": events,
		"location_requirements": balance["location_requirements"],
		"location_actions": balance["location_actions"],
		"sequences": balance["sequences"],
		"step_rolls": step_rolls,
		"event_flags": flags,
	})


## Every earlier result the good endings need.
func _all_results() -> Dictionary:
	return {"chapter3_sealed": true, "oath_seal_broken": true, "translucent_seed_received": true}


## Reaches the heart with the whole herb, on day six, with the spirits calmed and the truth seen.
func _at_heart_with_herb(flow: DayOneFlow) -> void:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 5)
	flow.perform("go:墜星之心")
	flow.perform("cross:test")
	flow.perform("cross:go")
	flow.perform("inry:stop_force")
	flow.perform("inry:listen")
	flow.perform("read:oath_truth")
	flow.perform("harvest:assess")
	flow.perform("harvest:whole")


## Returns by the safe road, then gives the common line its explanation and Liana's consent.
func _at_palace_with_consent(flow: DayOneFlow) -> void:
	flow.perform("return:safe")
	flow.perform("palace:evidence")
	flow.perform("palace:orders")
	flow.perform("palace:tell_liana")
	flow.perform("palace:liana_consent")


func test_the_stairs_advance_the_story_to_day_six() -> void:
	var flow := _flow([0.99])
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 4)
	flow.perform("go:血誓熔窟")
	flow.perform("read:father_record")
	flow.perform("oath:lower")
	flow.perform("oath:cover")
	flow.perform("oath:barrier")
	flow.perform("oath:chain")
	flow.perform("oath:pierce")
	flow.perform("descend:stairs")

	assert_int(flow.clock.day).is_equal(6)


func test_the_safe_road_reaches_the_palace_on_time() -> void:
	var flow := _flow([0.99])
	_at_heart_with_herb(flow)

	flow.perform("return:safe")

	assert_str(flow.location()).is_equal("王宮藥室")
	assert_bool(flow.event_flag("palace_arrived")).is_true()
	assert_bool(flow.event_flag("return_late")).is_false()
	assert_bool(flow.is_over()).is_false()


func test_the_shortcut_reaches_the_palace_on_time_when_the_roll_is_safe() -> void:
	var flow := _flow([0.99])
	_at_heart_with_herb(flow)

	flow.perform("return:shortcut")

	assert_bool(flow.event_flag("palace_arrived")).is_true()
	assert_bool(flow.event_flag("return_late")).is_false()


func test_a_shortcut_that_falls_short_makes_ending_c() -> void:
	var flow := _flow([0.0])
	_at_heart_with_herb(flow)

	var message: String = flow.perform("return:shortcut")

	assert_bool(flow.event_flag("return_late")).is_true()
	assert_bool(flow.event_flag("ending_c")).is_true()
	assert_str(flow.ending_id()).is_equal("END_C")
	assert_bool(flow.is_over()).is_true()
	assert_bool(message.contains("第八日")).is_true()


func test_the_common_line_must_run_in_order() -> void:
	var flow := _flow([0.99])
	_at_heart_with_herb(flow)
	flow.perform("return:safe")

	flow.perform("palace:orders")

	assert_bool(flow.event_flag("royal_orders_presented")).is_false()


func test_liana_consent_needs_the_explanation_first() -> void:
	var flow := _flow([0.99])
	_at_heart_with_herb(flow)
	flow.perform("return:safe")
	flow.perform("palace:evidence")
	flow.perform("palace:orders")

	flow.perform("palace:liana_consent")

	assert_bool(flow.event_flag("liana_consent_recorded")).is_false()


func test_ending_a_needs_the_kings_own_step() -> void:
	var flow := _flow([0.99], _all_results())
	_at_heart_with_herb(flow)
	_at_palace_with_consent(flow)

	flow.perform("final:ritual_a")

	assert_bool(flow.event_flag("ending_a")).is_false()
	assert_bool(flow.is_over()).is_false()


func test_ending_a_after_the_kings_own_step() -> void:
	var flow := _flow([0.99], _all_results())
	_at_heart_with_herb(flow)
	_at_palace_with_consent(flow)

	flow.perform("final:king_volunteers")
	flow.perform("final:ritual_a")

	assert_str(flow.ending_id()).is_equal("END_A")
	assert_bool(flow.is_over()).is_true()


func test_ending_b_needs_all_four_earlier_results() -> void:
	var results: Dictionary = _all_results()
	results.erase("oath_seal_broken")
	var flow := _flow([0.99], results)
	_at_heart_with_herb(flow)
	_at_palace_with_consent(flow)

	flow.perform("final:break_oath")

	assert_bool(flow.event_flag("ending_b")).is_false()


func test_ending_b_with_all_results_and_consent() -> void:
	var flow := _flow([0.99], _all_results())
	_at_heart_with_herb(flow)
	_at_palace_with_consent(flow)

	flow.perform("final:break_oath")

	assert_str(flow.ending_id()).is_equal("END_B")


func test_a_and_b_exclude_each_other() -> void:
	var flow := _flow([0.99], _all_results())
	_at_heart_with_herb(flow)
	_at_palace_with_consent(flow)
	flow.perform("final:king_volunteers")
	flow.perform("final:ritual_a")

	flow.perform("final:break_oath")

	assert_bool(flow.event_flag("ending_b")).is_false()
	assert_str(flow.ending_id()).is_equal("END_A")


func test_running_out_of_time_without_an_ending_is_still_over() -> void:
	var flow := _flow([0.99])
	flow.clock.spend(DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY)

	assert_bool(flow.is_over()).is_true()
	assert_str(flow.ending_id()).is_empty()
