extends GdUnitTestSuite
# Integration test: the blood curse raises the chance that Freya's sword steps fail in the
# cavern. Each stack adds 5%, capped at 25%. Only "oath:lower" and "oath:pierce" are affected.
# The roll is injected, so each test decides the outcome.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
]
const CURSE_TEXT: String = "血之詛咒擾亂了你的動作"
const LOWER_NARRATION: String = "芙蕾雅放下亡父之骨"


func _flow(step_rolls: Array) -> DayOneFlow:
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
		"step_rolls": step_rolls,
		"event_flags": {"obsidian_gate_open": true, "passage_entered": true, "path_to_next_layer_open": true},
	})


## Reads the record in the cavern, then adds curse stacks through strikes at the guard. Each
## strike adds one stack and resets the oath.
func _read_record_and_add_stacks(flow: DayOneFlow, stacks: int) -> void:
	if not flow.event_flag("father_record_read"):
		flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 4)
		flow.perform("go:血誓熔窟")
		flow.perform("read:father_record")
	var missing: int = stacks - flow.curse_stacks("freya")
	for index: int in range(maxi(missing, 0)):
		flow.perform("oath:strike")


func test_seal_steps_are_not_affected_by_the_curse() -> void:
	var flow := _flow([0.0])
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	flow.perform("read:kaen")
	flow.perform("seal:read")
	flow.perform("seal:read")
	flow.perform("seal:read")

	flow.perform("seal:draw")

	assert_bool(flow.event_flag("seal_drawn")).is_true()
	assert_float(flow.step_curse_risk("seal:draw")).is_equal(0.0)


func test_the_risk_is_five_percent_per_stack_capped_at_25_percent() -> void:
	var flow := _flow([0.99])
	_read_record_and_add_stacks(flow, 3)
	assert_float(flow.step_curse_risk("oath:lower")).is_equal_approx(0.15, 0.001)
	assert_float(flow.step_curse_risk("oath:cover")).is_equal(0.0)

	_read_record_and_add_stacks(flow, 10)
	assert_float(flow.step_curse_risk("oath:pierce")).is_equal_approx(0.25, 0.001)


func test_a_low_roll_fails_the_sword_step_when_the_curse_has_stacks() -> void:
	var flow := _flow([0.0])
	_read_record_and_add_stacks(flow, 3)

	var message: String = flow.perform("oath:lower")

	assert_bool(message.contains(CURSE_TEXT)).is_true()
	assert_bool(flow.event_flag("freya_lowered")).is_false()


func test_a_high_roll_lets_the_sword_step_succeed() -> void:
	var flow := _flow([0.99])
	_read_record_and_add_stacks(flow, 3)

	flow.perform("oath:lower")

	assert_bool(flow.event_flag("freya_lowered")).is_true()


func test_a_curse_failure_adds_no_curse_stack() -> void:
	var flow := _flow([0.0])
	_read_record_and_add_stacks(flow, 3)
	var stacks: int = flow.curse_stacks("freya")

	flow.perform("oath:lower")

	assert_int(flow.curse_stacks("freya")).is_equal(stacks)


func test_a_curse_failure_does_not_run_the_step_events() -> void:
	var flow := _flow([0.0])
	_read_record_and_add_stacks(flow, 3)

	var message: String = flow.perform("oath:lower")

	assert_bool(message.contains(LOWER_NARRATION)).is_false()


func test_without_curse_stacks_the_roll_does_not_matter() -> void:
	var flow := _flow([0.0])
	_read_record_and_add_stacks(flow, 0)

	flow.perform("oath:lower")

	assert_bool(flow.event_flag("freya_lowered")).is_true()
