extends GdUnitTestSuite
# Unit tests for character data validation (design/GAME_DESIGN_MASTER.md section 9.3).
# Validation is a pure function over a Dictionary, so no file access is needed.


func _valid_character() -> Dictionary:
	return {
		"id": "freya",
		"identity": {"name": "芙蕾雅・雷恩", "role": "frontline"},
		"stats": {"hp": 130, "mp": 20, "atk": 16, "def": 10, "spd": 6},
		"skills": ["greatsword_slash", "blood_rage"],
	}


func test_valid_character_produces_no_errors() -> void:
	# Arrange
	var data := _valid_character()

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_missing_id_is_reported() -> void:
	# Arrange
	var data := _valid_character()
	data.erase("id")

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("missing field: id")).is_true()


func test_zero_hp_is_reported_as_out_of_range() -> void:
	# Arrange
	var data := _valid_character()
	data["stats"]["hp"] = 0

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("stats.hp must be greater than 0")).is_true()


func test_empty_skill_list_is_reported() -> void:
	# Arrange
	var data := _valid_character()
	data["skills"] = []

	# Act
	var errors := CharacterData.validate(data)

	# Assert
	assert_bool(errors.has("skills must contain at least one entry")).is_true()
