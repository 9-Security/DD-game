extends GdUnitTestSuite
# Integration test: every character file keeps the setting-v1.0 skills as extra skills,
# with unique IDs that do not repeat the starting skills.

const CHARACTER_DIR: String = "res://assets/data/characters/"
const EXPECTED_EXTRA_COUNTS: Dictionary = {"eron": 5, "freya": 5, "richter": 5, "inry": 5}


func test_each_character_keeps_its_extra_skills() -> void:
	for character_id: String in EXPECTED_EXTRA_COUNTS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHARACTER_DIR + character_id + ".json"))
		assert_bool(parsed.has("extra_skills")).is_true()
		assert_int((parsed["extra_skills"] as Array).size()).is_equal(EXPECTED_EXTRA_COUNTS[character_id])


func test_skill_ids_are_unique_across_base_and_extra() -> void:
	for character_id: String in EXPECTED_EXTRA_COUNTS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHARACTER_DIR + character_id + ".json"))
		var seen: Dictionary = {}
		var all_ids: Array = parsed["skills"].duplicate()
		for skill: Dictionary in parsed["extra_skills"]:
			all_ids.append(skill["id"])
		for skill_id: String in all_ids:
			assert_bool(seen.has(skill_id)).is_false()
			seen[skill_id] = true


func test_every_extra_skill_has_a_description_and_unlock_type() -> void:
	for character_id: String in EXPECTED_EXTRA_COUNTS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHARACTER_DIR + character_id + ".json"))
		for skill: Dictionary in parsed["extra_skills"]:
			assert_bool(skill.has("description")).is_true()
			assert_bool((skill["unlock"] as Dictionary).has("type")).is_true()
