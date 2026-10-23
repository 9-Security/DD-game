extends GdUnitTestSuite
# Unit tests for the damage formula (design/GAME_DESIGN_MASTER.md section 4.2).
# The random roll is injected so every case is deterministic.


func test_base_attack_returns_expected_damage() -> void:
	# Arrange: 16 attack, 1.0 multiplier, 10 defense -> 16 - 10 * 0.5 = 11
	# Act
	var damage := DamageCalculator.calculate(16, 1.0, 10, 0.0)

	# Assert
	assert_int(damage).is_equal(11)


func test_damage_never_drops_below_one() -> void:
	# Arrange: defense far above attack would produce a negative base
	# Act
	var damage := DamageCalculator.calculate(1, 1.0, 100, 0.0)

	# Assert
	assert_int(damage).is_equal(1)


func test_positive_roll_increases_damage_by_ten_percent() -> void:
	# Arrange: base 11 * 1.10 = 12.1 -> rounds to 12
	# Act
	var damage := DamageCalculator.calculate(16, 1.0, 10, 0.10)

	# Assert
	assert_int(damage).is_equal(12)


func test_negative_roll_decreases_damage_by_ten_percent() -> void:
	# Arrange: base 11 * 0.90 = 9.9 -> rounds to 10
	# Act
	var damage := DamageCalculator.calculate(16, 1.0, 10, -0.10)

	# Assert
	assert_int(damage).is_equal(10)


func test_roll_outside_plus_minus_ten_percent_is_clamped() -> void:
	# Arrange: a roll of 0.5 must behave like 0.10
	# Act
	var damage := DamageCalculator.calculate(16, 1.0, 10, 0.5)

	# Assert
	assert_int(damage).is_equal(12)


func test_skill_multiplier_scales_attack_before_defense() -> void:
	# Arrange: 16 * 1.5 = 24, minus 10 * 0.5 = 5 -> 19
	# Act
	var damage := DamageCalculator.calculate(16, 1.5, 10, 0.0)

	# Assert
	assert_int(damage).is_equal(19)
