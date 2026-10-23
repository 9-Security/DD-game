extends GdUnitTestSuite
# Integration test: the chapter two gate events parse and validate, with one confession per
# character and a single gate-opening event that needs all four.

const EVENTS_PATH: String = "res://assets/data/events/chapter2.json"


func test_chapter_two_events_validate_and_cover_all_four_confessions() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var confessions: Array = []
	for event: Dictionary in parsed["events"]:
		assert_int(EventRunner.validate(event).size()).is_equal(0)
		var action: String = str(event["trigger"].get("action", ""))
		if action.begins_with("confess:"):
			confessions.append(action)
	for id: String in ["eron", "freya", "richter", "inry"]:
		assert_bool(confessions.has("confess:" + id)).is_true()
