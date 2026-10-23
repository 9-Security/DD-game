extends GdUnitTestSuite
# Integration test: the balance data gates the passage behind the gate flag, and the chapter two
# events include its arrival. The passage must not add day-three content.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATH: String = "res://assets/data/events/chapter2.json"


func test_balance_gates_the_passage_behind_the_gate_flag() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var requirements: Dictionary = parsed.get("location_requirements", {})
	var passage: Dictionary = requirements.get("門後通道", {})
	assert_str(str(passage.get("flag", ""))).is_equal("obsidian_gate_open")
	var gate: Dictionary = requirements.get("黑曜石之門", {})
	assert_int(int(gate.get("min_day", 0))).is_equal(2)


func test_chapter_two_has_a_passage_arrival_event() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var day_two_arrival: Dictionary = {}
	var later_arrival: Dictionary = {}
	for event: Dictionary in parsed["events"]:
		assert_int(EventRunner.validate(event).size()).is_equal(0)
		var trigger: Dictionary = event["trigger"]
		if trigger.get("action", "") != "go:門後通道":
			continue
		if trigger.has("day"):
			day_two_arrival = event
		if trigger.has("min_day"):
			later_arrival = event
	assert_bool(day_two_arrival.is_empty()).is_false()
	assert_bool(later_arrival.is_empty()).is_false()
	var texts: String = ""
	for effect: Dictionary in day_two_arrival["effects"]:
		texts += str(effect.get("text", ""))
	assert_bool(texts.contains("第二日尚未結束")).is_true()
