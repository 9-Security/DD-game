extends GdUnitTestSuite
# Unit tests for Inry's summon control (design/GAME_DESIGN_MASTER.md section 3.2).
# Rolls are injected so every outcome is deterministic.


func test_failure_chance_is_base_rate_at_healthy_mp() -> void:
	# Arrange: MP 60 of 90 is above the 30 percent threshold

	# Act
	var chance := SummonControl.failure_chance(60, 90)

	# Assert
	assert_float(chance).is_equal_approx(0.15, 0.0001)


func test_failure_chance_rises_when_mp_drops_below_thirty_percent() -> void:
	# Arrange: MP 20 of 90 is about 22 percent

	# Act
	var chance := SummonControl.failure_chance(20, 90)

	# Assert
	assert_float(chance).is_equal_approx(0.25, 0.0001)


func test_failure_roll_below_chance_counts_as_failure() -> void:
	# Arrange / Act
	var failed := SummonControl.is_failure(0.10, 0.15)

	# Assert
	assert_bool(failed).is_true()


func test_failure_roll_at_or_above_chance_is_success() -> void:
	# Arrange / Act
	var failed := SummonControl.is_failure(0.15, 0.15)

	# Assert
	assert_bool(failed).is_false()


func test_low_roll_gives_positive_outcome() -> void:
	# Arrange / Act
	var outcome := SummonControl.outcome_for_roll(0.10)

	# Assert
	assert_str(outcome).is_equal("positive")


func test_middle_roll_gives_neutral_outcome() -> void:
	# Arrange / Act
	var outcome := SummonControl.outcome_for_roll(0.50)

	# Assert
	assert_str(outcome).is_equal("neutral")


func test_high_roll_gives_negative_outcome() -> void:
	# Arrange / Act
	var outcome := SummonControl.outcome_for_roll(0.90)

	# Assert
	assert_str(outcome).is_equal("negative")


func test_outcome_boundaries_follow_forty_thirty_thirty_split() -> void:
	# Arrange / Act / Assert: 40 percent positive, then 30 percent neutral, then 30 percent negative
	assert_str(SummonControl.outcome_for_roll(0.39)).is_equal("positive")
	assert_str(SummonControl.outcome_for_roll(0.40)).is_equal("neutral")
	assert_str(SummonControl.outcome_for_roll(0.69)).is_equal("neutral")
	assert_str(SummonControl.outcome_for_roll(0.70)).is_equal("negative")
