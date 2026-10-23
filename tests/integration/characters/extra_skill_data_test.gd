extends GdUnitTestSuite
# Integration test: each character file keeps its remaining settings skills as extra
# skills, merged settings skills are recorded with their target, and skill IDs are unique.

const CHARACTER_DIR: String = "res://assets/data/characters/"
## Extra skills after merging the five overlapping pairs (see design/characters/CHARACTER_BIBLE.md 7a).
const EXPECTED_EXTRA_COUNTS: Dictionary = {"eron": 3, "freya": 3, "richter": 4, "inry": 5}
const EXPECTED_MERGED_COUNTS: Dictionary = {"eron": 2, "freya": 2, "richter": 1, "inry": 0}


func _load(character_id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CHARACTER_DIR + character_id + ".json"))


func test_each_character_keeps_its_extra_skills() -> void:
	for character_id: String in EXPECTED_EXTRA_COUNTS:
		var parsed := _load(character_id)
		assert_int((parsed["extra_skills"] as Array).size()).is_equal(EXPECTED_EXTRA_COUNTS[character_id])


func test_merged_skills_are_recorded_with_their_target() -> void:
	for character_id: String in EXPECTED_MERGED_COUNTS:
		var parsed := _load(character_id)
		var merged: Array = parsed.get("merged_skills", [])
		assert_int(merged.size()).is_equal(EXPECTED_MERGED_COUNTS[character_id])
		for entry: Dictionary in merged:
			assert_bool((parsed["skills"] as Array).has(entry["into"])).is_true()


func test_skill_ids_are_unique_across_all_lists() -> void:
	for character_id: String in EXPECTED_EXTRA_COUNTS:
		var parsed := _load(character_id)
		var seen: Dictionary = {}
		var all_ids: Array = (parsed["skills"] as Array).duplicate()
		for skill: Dictionary in parsed["extra_skills"]:
			all_ids.append(skill["id"])
		for entry: Dictionary in parsed.get("merged_skills", []):
			all_ids.append(entry["id"])
		for skill_id: String in all_ids:
			assert_bool(seen.has(skill_id)).is_false()
			seen[skill_id] = true


func test_every_extra_skill_offers_level_or_quest_reward() -> void:
	for character_id: String in EXPECTED_EXTRA_COUNTS:
		var parsed := _load(character_id)
		for skill: Dictionary in parsed["extra_skills"]:
			assert_bool(skill.has("description")).is_true()
			assert_array((skill["unlock"]["sources"] as Array)).is_equal(["level", "quest_reward"])
