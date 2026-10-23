extends GdUnitTestSuite
# Integration test: the day-one encounter data file parses and validates.

const ENCOUNTER_PATH: String = "res://assets/data/encounters/day1.json"


func test_day_one_encounters_parse_and_validate() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_PATH))
	assert_bool(parsed is Dictionary).is_true()
	for entry: Dictionary in parsed["entries"]:
		assert_int(Encounter.validate(entry).size()).is_equal(0)
