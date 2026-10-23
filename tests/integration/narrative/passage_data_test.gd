extends GdUnitTestSuite
# Integration test: the balance data gates the passage behind the gate flag, and the chapter two
# events include its arrival. The passage must not add day-three content.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATH: String = "res://assets/data/events/chapter2.json"


func test_balance_gates_the_passage_behind_the_gate_flag() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var requirements: Dictionary = parsed.get("location_requirements", {})
	assert_str(str(requirements.get("門後通道", ""))).is_equal("obsidian_gate_open")


func test_chapter_two_has_a_passage_arrival_event() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var found: bool = false
	for event: Dictionary in parsed["events"]:
		assert_int(EventRunner.validate(event).size()).is_equal(0)
		if event["trigger"].get("action", "") == "go:門後通道":
			found = true
	assert_bool(found).is_true()
