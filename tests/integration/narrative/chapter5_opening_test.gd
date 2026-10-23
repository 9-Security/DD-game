extends GdUnitTestSuite
# Integration test: the day-five opening runs on the real data. The Blood Oath Furnace opens on
# day five after the garden guardian is released. Its opening shows the royal decree found by Freya.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
]
const FURNACE_REFUSAL: String = "天亮前不宜深入熔窟"
const DECREE_TEXT: String = "一份密令"
const RELIC_TEXT: String = "亡父之骨不是遺物，而是刑具。"


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


## Completes chapters three and four without failures, leaving the flow in the garden.
func _release_guardian(flow: DayOneFlow) -> void:
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
	flow.perform("go:失聲之庭")
	flow.perform("commune:tree")
	flow.perform("release:stabilize")
	flow.perform("release:chain_one")
	flow.perform("release:chain_two")
	flow.perform("release:core")


## Spends time until the given day has started.
func _advance_to_day(flow: DayOneFlow, day: int) -> void:
	var target: int = (day - 1) * DayClock.SEGMENTS_PER_DAY
	var remaining: int = target - flow.clock.get_elapsed()
	if remaining > 0:
		flow.clock.spend(remaining)


func test_furnace_is_refused_before_day_five() -> void:
	var flow := _flow()
	_release_guardian(flow)

	var message: String = flow.perform("go:血誓熔窟")

	assert_bool(message.contains(FURNACE_REFUSAL)).is_true()
	assert_bool(flow.event_flag("lava_entered")).is_false()


func test_furnace_opens_on_day_five_and_shows_the_decree() -> void:
	var flow := _flow()
	_release_guardian(flow)
	_advance_to_day(flow, 5)

	var message: String = flow.perform("go:血誓熔窟")

	assert_str(flow.location()).is_equal("血誓熔窟")
	assert_bool(flow.event_flag("lava_entered")).is_true()
	assert_bool(flow.event_flag("decree_found")).is_true()
	assert_bool(message.contains(DECREE_TEXT)).is_true()
	assert_bool(message.contains(RELIC_TEXT)).is_true()


func test_furnace_stays_closed_until_the_guardian_is_released() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 4)

	var message: String = flow.perform("go:血誓熔窟")

	assert_str(flow.location()).is_empty()
	assert_bool(message.contains("石牆仍然閉合")).is_true()
