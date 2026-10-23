extends GdUnitTestSuite
# Unit tests for camp-only saving and snapshot restore (design/GAME_DESIGN_MASTER.md
# sections 2.1 and 2.2: saves are allowed only at camp, and rewinding is not allowed).


func _party() -> Array:
	return [{"name": "test-member", "atk": 16}]


func test_saving_is_not_allowed_before_first_rest() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0])

	# Act
	flow.perform("move")

	# Assert
	assert_bool(flow.can_save()).is_false()


func test_rest_enables_saving_and_next_move_disables_it() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0])

	# Act
	flow.perform("rest")
	var at_camp := flow.can_save()
	flow.perform("move")

	# Assert
	assert_bool(at_camp).is_true()
	assert_bool(flow.can_save()).is_false()


func test_snapshot_restores_clock_and_battle_state() -> void:
	# Arrange
	var source := DayOneFlow.new(_party(), [0.0])
	source.perform("move")
	source.perform("rest")
	source.perform("battle")
	var snapshot := source.snapshot()

	var target := DayOneFlow.new(_party(), [0.0])

	# Act
	var restored := target.restore(snapshot)

	# Assert
	assert_bool(restored).is_true()
	assert_str(target.status_text()).is_equal(source.status_text())
	assert_bool(target.battle_done).is_true()


func test_restore_rejects_wrong_version_without_changing_state() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0])
	flow.perform("move")
	var before := flow.status_text()
	var bad_snapshot := {"version": 99, "elapsed": 5, "battle_done": false}

	# Act
	var restored := flow.restore(bad_snapshot)

	# Assert
	assert_bool(restored).is_false()
	assert_str(flow.status_text()).is_equal(before)


func test_restore_rejects_elapsed_outside_the_week() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0])
	var total := DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY
	var bad_snapshot := {"version": 1, "elapsed": total + 1, "battle_done": false}

	# Act
	var restored := flow.restore(bad_snapshot)

	# Assert
	assert_bool(restored).is_false()


func test_restore_rejects_missing_battle_flag() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0])
	var bad_snapshot := {"version": 1, "elapsed": 2}

	# Act
	var restored := flow.restore(bad_snapshot)

	# Assert
	assert_bool(restored).is_false()


func test_restored_game_cannot_be_saved_until_next_rest() -> void:
	# Arrange: loading puts the player back at the last save point, not at camp
	var source := DayOneFlow.new(_party(), [0.0])
	source.perform("rest")
	var target := DayOneFlow.new(_party(), [0.0])
	target.restore(source.snapshot())

	# Act
	var can_save := target.can_save()

	# Assert
	assert_bool(can_save).is_false()
