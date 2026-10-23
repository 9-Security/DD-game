extends GdUnitTestSuite
# Unit tests for balance rule validation (values come from assets/data/rules/balance.json).


func _valid() -> Dictionary:
	return {
		"difficulty": {
			"strict": {"starting_herbs": 3, "starting_food": 4, "rest_food_cost": 1},
			"assisted": {"starting_herbs": 6, "starting_food": 8, "rest_food_cost": 0},
		},
		"trust": {"min": 0, "max": 100, "start": 50},
	}


func test_valid_rules_have_no_errors() -> void:
	# Arrange / Act
	var errors := GameRules.validate(_valid())

	# Assert
	assert_int(errors.size()).is_equal(0)


func test_missing_strict_difficulty_is_reported() -> void:
	# Arrange
	var data := _valid()
	data["difficulty"].erase("strict")

	# Act
	var errors := GameRules.validate(data)

	# Assert
	assert_bool(errors.has("difficulty.strict is required")).is_true()


func test_negative_supply_is_reported() -> void:
	# Arrange
	var data := _valid()
	data["difficulty"]["strict"]["starting_food"] = -1

	# Act
	var errors := GameRules.validate(data)

	# Assert
	assert_bool(errors.has("difficulty.strict.starting_food must be a non-negative integer")).is_true()


func test_start_trust_outside_range_is_reported() -> void:
	# Arrange
	var data := _valid()
	data["trust"]["start"] = 150

	# Act
	var errors := GameRules.validate(data)

	# Assert
	assert_bool(errors.has("trust.start must be between trust.min and trust.max")).is_true()
