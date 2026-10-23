extends GdUnitTestSuite
# Unit tests for building battle members from character data and the first-version skill file.

const SKILLS_PATH: String = "res://assets/data/battle/skills.json"
const CHARACTER_IDS: Array[String] = ["eron", "freya", "richter", "inry"]


func _skill_file() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SKILLS_PATH))


func _character(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/characters/%s.json" % id))


func test_every_v1_character_has_a_representative_skill_that_is_defined() -> void:
	var file := _skill_file()
	for id: String in CHARACTER_IDS:
		var skill_id: String = str(file["representative"][id])
		assert_bool((file["skills"] as Dictionary).has(skill_id)).is_true()


func test_a_party_member_takes_its_stats_from_the_character_data() -> void:
	var member := BattleSetup.party_member(_character("eron"), "life_resonance")

	assert_int(int(member["hp"])).is_equal(90)
	assert_int(int(member["max_hp"])).is_equal(90)
	assert_int(int(member["mp"])).is_equal(60)
	assert_int(int(member["atk"])).is_equal(8)
	assert_int(int(member["def"])).is_equal(6)
	assert_int(int(member["speed"])).is_equal(9)
	assert_str(str(member["skill"])).is_equal("life_resonance")


func test_a_party_member_is_named_after_its_identity() -> void:
	var member := BattleSetup.party_member(_character("richter"), "rune_trap")

	assert_str(str(member["name"])).is_equal("里克特・安布羅斯")
	assert_str(str(member["id"])).is_equal("richter")
