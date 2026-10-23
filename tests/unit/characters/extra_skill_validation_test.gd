extends GdUnitTestSuite
# Unit tests for the optional extra_skills block. Each extra skill is obtained by
# reaching a level, as a side-quest reward, or either. Validation is a pure function.


func _base() -> Dictionary:
	return {
		"id": "richter",
		"identity": {"name": "里克特・安布羅斯", "role": "trap_explorer"},
		"stats": {"hp": 85, "mp": 50, "atk": 10, "def": 5, "spd": 13},
		"skills": ["rune_trap"],
	}


func _extra(skill_id: String, sources: Array) -> Dictionary:
	return {
		"id": skill_id,
		"name": "測試技能",
		"description": "測試用描述",
		"unlock": {"sources": sources},
	}


func test_character_without_extra_skills_is_still_valid() -> void:
	# Arrange
	var data := _base()

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_extra_skill_unlocked_by_level_or_quest_reward_passes() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_analysis", ["level", "quest_reward"])]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_unknown_unlock_source_is_reported() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_analysis", ["by_magic"])]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("extra_skills[0].unlock.sources must contain only: level, quest_reward")).is_true()


func test_empty_unlock_source_list_is_reported() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_analysis", [])]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("extra_skills[0].unlock.sources must contain only: level, quest_reward")).is_true()


func test_extra_skill_reusing_a_base_skill_id_is_reported() -> void:
	# Arrange
	var data := _base()
	data["extra_skills"] = [_extra("rune_trap", ["level"])]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("duplicate skill id: rune_trap")).is_true()


func test_extra_skill_missing_a_name_is_reported() -> void:
	# Arrange
	var data := _base()
	var skill := _extra("rune_analysis", ["level"])
	skill.erase("name")
	data["extra_skills"] = [skill]

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("extra_skills[0] missing field: name")).is_true()
