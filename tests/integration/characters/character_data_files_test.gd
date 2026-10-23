extends GdUnitTestSuite
# Integration test: every character file shipped in assets/data/characters/
# must parse as JSON and pass CharacterData validation.

const CHARACTER_DIR: String = "res://assets/data/characters/"
const EXPECTED_IDS: Array[String] = ["eron", "freya", "richter", "inry"]


func test_all_four_party_members_exist_and_validate() -> void:
	for character_id: String in EXPECTED_IDS:
		var path := CHARACTER_DIR + character_id + ".json"
		assert_bool(FileAccess.file_exists(path)).is_true()

		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_bool(parsed is Dictionary).is_true()

		var errors := CharacterData.validate(parsed)
		assert_int(errors.size()).is_equal(0)
		assert_str(parsed["id"]).is_equal(character_id)


func test_character_stats_match_design_document() -> void:
	# Values from design/GAME_DESIGN_MASTER.md section 3.1
	var expected := {
		"eron": {"hp": 90, "mp": 60, "atk": 8, "def": 6, "spd": 9},
		"freya": {"hp": 130, "mp": 20, "atk": 16, "def": 10, "spd": 6},
		"richter": {"hp": 85, "mp": 50, "atk": 10, "def": 5, "spd": 13},
		"inry": {"hp": 80, "mp": 90, "atk": 6, "def": 4, "spd": 10},
	}
	for character_id: String in EXPECTED_IDS:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHARACTER_DIR + character_id + ".json"))
		var stats: Dictionary = parsed["stats"]
		# JSON numbers parse as float in Godot; compare each stat as an int.
		for stat_name: String in expected[character_id]:
			assert_int(int(stats[stat_name])).is_equal(expected[character_id][stat_name])
