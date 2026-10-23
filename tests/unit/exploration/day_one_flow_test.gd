extends GdUnitTestSuite
# Unit tests for the day-one action flow (move, explore, rest, tutorial battle).


func _party(attack: int) -> Array:
	return [{"name": "test-member", "atk": attack}]


func test_move_spends_one_segment() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(16), [0.0])

	# Act
	flow.perform("move")

	# Assert
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_NOON)


func test_rest_spends_two_segments() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(16), [0.0])

	# Act
	flow.perform("rest")

	# Assert
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_NIGHT)


func test_unknown_action_spends_no_time() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(16), [0.0])

	# Act
	var message := flow.perform("dance")

	# Assert
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_MORNING)
	assert_bool(message.contains("未知")).is_true()


func test_tutorial_battle_can_only_be_fought_once() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(16), [0.0])

	# Act
	flow.perform("battle")
	var second_message := flow.perform("battle")

	# Assert
	assert_bool(flow.battle_done).is_true()
	assert_bool(second_message.contains("已結束")).is_true()
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_NOON)


func test_strong_party_wins_tutorial_battle() -> void:
	# Arrange: 40 attack per round against 30 hp (def 2 with zero roll -> 39 damage)
	var flow := DayOneFlow.new(_party(40), [0.0])

	# Act
	var message := flow.perform("battle")

	# Assert
	assert_bool(message.contains("勝利")).is_true()


func test_completing_night_reports_day_end() -> void:
	# Arrange: morning -> noon -> night -> next day morning
	var flow := DayOneFlow.new(_party(16), [0.0])
	flow.perform("move")
	flow.perform("explore")

	# Act
	var message := flow.perform("move")

	# Assert
	assert_int(flow.clock.day).is_equal(2)
	assert_bool(message.contains("第 1 日結束")).is_true()


func test_actions_are_rejected_after_time_expires() -> void:
	# Arrange: spend the whole week in one call
	var flow := DayOneFlow.new(_party(16), [0.0])
	flow.clock.spend(DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY)

	# Act
	var message := flow.perform("move")

	# Assert
	assert_bool(flow.clock.is_expired()).is_true()
	assert_bool(message.contains("時限")).is_true()


func test_status_text_shows_day_and_segment() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(16), [0.0])

	# Act
	var text := flow.status_text()

	# Assert
	assert_bool(text.contains("第 1 日")).is_true()
	assert_bool(text.contains("晨")).is_true()
