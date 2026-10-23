extends GdUnitTestSuite
# Integration test: the chapter one event file parses, validates, and covers the
# mandatory events agreed in design/narrative/CHAPTER1_EVENTS.md.

const EVENTS_PATH: String = "res://assets/data/events/chapter1.json"
const MANDATORY_IDS: Array[String] = [
	"ch1_sapling_clue", "ch1_royal_convoy_lie", "ch1_village_no_children",
	"ch1_innkeeper_bell", "ch1_night_lamp_spirit", "ch1_royal_seal",
]


func test_chapter_one_events_validate() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	for event: Dictionary in parsed["events"]:
		assert_int(EventRunner.validate(event).size()).is_equal(0)


func test_every_mandatory_event_is_present() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var ids: Array = []
	for event: Dictionary in parsed["events"]:
		ids.append(event["id"])
	for event_id: String in MANDATORY_IDS:
		assert_bool(ids.has(event_id)).is_true()
