extends GdUnitTestSuite
# Unit tests for merged_skills: settings skills folded into a starting skill.


func _base() -> Dictionary:
	return {
		"id": "freya",
		"identity": {"name": "芙蕾雅・雷恩", "role": "frontline"},
		"stats": {"hp": 130, "mp": 20, "atk": 16, "def": 10, "spd": 6},
		"skills": ["greatsword_slash", "blood_rage"],
	}


func _merged(skill_id: String, into: String) -> Dictionary:
	return {
		"id": skill_id,
		"name": "血怒",
		"description": "消耗生命換取戰鬥能力",
		"into": into,
	}


func test_merged_skill_pointing_at_a_starting_skill_passes() -> void:
	# Arrange
	var data := _base()
	data["merged_skills"] = [_merged("blood_fury", "blood_rage")]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_merged_skill_must_point_at_a_starting_skill() -> void:
	# Arrange
	var data := _base()
	data["merged_skills"] = [_merged("blood_fury", "not_a_skill")]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("merged_skills[0].into must name a starting skill: not_a_skill")).is_true()


func test_merged_skill_missing_its_description_is_reported() -> void:
	# Arrange
	var data := _base()
	var entry := _merged("blood_fury", "blood_rage")
	entry.erase("description")
	data["merged_skills"] = [entry]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("merged_skills[0] missing field: description")).is_true()


func test_merged_skill_reusing_an_existing_id_is_reported() -> void:
	# Arrange
	var data := _base()
	data["merged_skills"] = [_merged("greatsword_slash", "blood_rage")]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("duplicate skill id: greatsword_slash")).is_true()
