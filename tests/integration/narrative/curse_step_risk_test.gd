extends GdUnitTestSuite
# Integration test: the blood curse raises the chance that a puzzle step fails. Each stack adds
# a fixed chance, capped. The roll is injected, so each test decides the outcome.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
]
const CURSE_TEXT: String = "血之詛咒擾亂了你的動作"


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
		"event_flags": {"obsidian_gate_open": true, "passage_entered": true},
	})


## Reaches the hall with Kaen's name found, then adds three curse stacks through three failed
## seal attempts. Each failure resets the seal, so the seal starts again from the first step.
func _hall_with_three_stacks(flow: DayOneFlow) -> void:
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	flow.perform("read:kaen")
	for index: int in range(3):
		flow.perform("seal:read")


func test_a_low_roll_makes_a_step_fail_when_the_curse_has_stacks() -> void:
	var flow := _flow([0.0])
	_hall_with_three_stacks(flow)

	var message: String = flow.perform("seal:draw")

	assert_bool(message.contains(CURSE_TEXT)).is_true()
	assert_bool(flow.event_flag("seal_drawn")).is_false()


func test_a_high_roll_lets_the_same_step_succeed() -> void:
	var flow := _flow([0.99])
	_hall_with_three_stacks(flow)

	flow.perform("seal:draw")

	assert_bool(flow.event_flag("seal_drawn")).is_true()


func test_a_curse_failure_resets_the_seal_but_adds_no_curse_stack() -> void:
	var flow := _flow([0.0])
	_hall_with_three_stacks(flow)
	var stacks: int = flow.curse_stacks("freya")

	flow.perform("seal:draw")

	assert_int(flow.curse_stacks("freya")).is_equal(stacks)


func test_without_curse_stacks_the_roll_does_not_matter() -> void:
	var flow := _flow([0.0])
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)
	flow.perform("go:咒牆迷廊")
	flow.perform("read:first_name")
	flow.perform("read:second_name")
	flow.perform("go:名冊廊廳")
	flow.perform("read:kaen")

	flow.perform("seal:draw")

	assert_bool(flow.event_flag("seal_drawn")).is_true()


func test_a_curse_failure_does_not_run_the_step_events() -> void:
	var flow := _flow([0.0])
	_hall_with_three_stacks(flow)

	var message: String = flow.perform("seal:draw")

	# The draw event narrates the spirits; a failed attempt must not show that narration.
	assert_bool(message.contains("在半空描出凱恩之名的筆畫")).is_false()
