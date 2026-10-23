extends GdUnitTestSuite
# Unit tests for the optional extra_skills block (skills kept for later upgrades or
# acquisition). Validation is a pure function over a Dictionary.


func _base() -> Dictionary:
	return {
		"id": "richter",
		"identity": {"name": "里克特・安布羅斯", "role": "trap_explorer"},
		"stats": {"hp": 85, "mp": 50, "atk": 10, "def": 5, "spd": 13},
		"skills": ["rune_trap"],
	}


func _extra(skill_id: String, unlock_type: String) -> Dictionary:
	return {
		"id": skill_id,
		"name": "測試技能",
		"description": "測試用描述",
		"unlock": {"type": unlock_type},
	}


func test_character_without_extra_skills_is_still_valid() -> void:
	# Arrange
	var data := _base()

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_valid_extra_skill_with_unassigned_unlock_passes() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_analysis", "unassigned")]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_unknown_unlock_type_is_reported() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_analysis", "by_magic")]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("extra_skills[0].unlock.type must be one of: level, story_flag, upgrade, unassigned")).is_true()


func test_extra_skill_reusing_a_base_skill_id_is_reported() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_trap", "unassigned")]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("duplicate skill id: rune_trap")).is_true()


func test_extra_skill_missing_a_name_is_reported() -> void:
	# Arrange
	var data := _base()
	var skill := _extra("rune_analysis", "unassigned")
	skill.erase("name")
	data["extra_skills"] = [skill]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("extra_skills[0] missing field: name")).is_true()
