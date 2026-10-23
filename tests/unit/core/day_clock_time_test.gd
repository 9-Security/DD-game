extends GdUnitTestSuite
# Unit tests for the seven-day clock (design/GAME_DESIGN_MASTER.md section 2).


func test_new_clock_starts_on_day_one_morning() -> void:
	# Arrange
	var clock := DayClock.new()

	# Act
	# (no action: checking the initial state)

	# Assert
	assert_int(clock.day).is_equal(1)
	assert_int(clock.segment).is_equal(DayClock.SEGMENT_MORNING)
	assert_bool(clock.is_expired()).is_false()


func test_spend_one_segment_moves_from_morning_to_noon() -> void:
	# Arrange
	var clock := DayClock.new()

	# Act
	var boundaries := clock.spend(1)

	# Assert
	assert_int(clock.segment).is_equal(DayClock.SEGMENT_NOON)
	assert_int(clock.day).is_equal(1)
	assert_int(boundaries).is_equal(0)


func test_spend_past_night_advances_day_and_reports_one_boundary() -> void:
	# Arrange
	var clock := DayClock.new()
	clock.spend(2)  # morning -> night

	# Act
	var boundaries := clock.spend(1)  # night -> next day morning

	# Assert
	assert_int(clock.day).is_equal(2)
	assert_int(clock.segment).is_equal(DayClock.SEGMENT_MORNING)
	assert_int(boundaries).is_equal(1)


func test_rest_cost_of_two_segments_can_cross_one_day_boundary() -> void:
	# Arrange
	var clock := DayClock.new()
	clock.spend(1)  # morning -> noon

	# Act
	var boundaries := clock.spend(2)  # noon -> night -> next morning

	# Assert
	assert_int(clock.day).is_equal(2)
	assert_int(clock.segment).is_equal(DayClock.SEGMENT_MORNING)
	assert_int(boundaries).is_equal(1)


func test_spending_through_day_seven_night_marks_clock_expired() -> void:
	# Arrange
	var clock := DayClock.new()
	var total_segments := DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY

	# Act
	clock.spend(total_segments)

	# Assert
	assert_bool(clock.is_expired()).is_true()


func test_spend_after_expired_changes_nothing() -> void:
	# Arrange
	var clock := DayClock.new()
	clock.spend(DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY)

	# Act
	var boundaries := clock.spend(1)

	# Assert
	assert_bool(clock.is_expired()).is_true()
	assert_int(boundaries).is_equal(0)


func test_spend_with_zero_or_negative_cost_is_rejected() -> void:
	# Arrange
	var clock := DayClock.new()

	# Act
	var zero_boundaries := clock.spend(0)
	var negative_boundaries := clock.spend(-3)

	# Assert
	assert_int(clock.segment).is_equal(DayClock.SEGMENT_MORNING)
	assert_int(zero_boundaries).is_equal(0)
	assert_int(negative_boundaries).is_equal(0)
