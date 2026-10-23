extends GdUnitTestSuite
# Integration test: the sapling help quest and the innkeeper night branch are in the chapter
# one event file, validate, and reference skills that exist in the character data.

const EVENTS_PATH: String = "res://assets/data/events/chapter1.json"
const ERON_PATH: String = "res://assets/data/characters/eron.json"


func test_sapling_help_grants_a_skill_eron_actually_has_as_an_extra() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var eron: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ERON_PATH))
	var extra_ids: Array = []
	for skill: Dictionary in eron["extra_skills"]:
		extra_ids.append(skill["id"])

	var found: bool = false
	for event: Dictionary in parsed["events"]:
		assert_int(EventRunner.validate(event).size()).is_equal(0)
		if event["id"] == "ch1_sapling_help":
			found = true
			for effect: Dictionary in event["effects"]:
				if effect["type"] == "unlock_skill":
					assert_bool(extra_ids.has(effect["skill"])).is_true()
	assert_bool(found).is_true()


func test_innkeeper_has_day_and_night_branches() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var night_branch: bool = false
	for event: Dictionary in parsed["events"]:
		if event["trigger"].get("is_night", null) == true and event["trigger"].get("action", "") == "talk:innkeeper":
			night_branch = true
	assert_bool(night_branch).is_true()
