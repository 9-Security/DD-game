extends GdUnitTestSuite
# Integration test: when the time limit ends, the flow reports it, refuses further actions, and a
# save taken earlier can still be restored, so the player is never stuck with no way forward.


func _flow() -> DayOneFlow:
	return DayOneFlow.new([{"id": "eron", "name": "艾洛恩", "atk": 10}], [0.0], {})


func test_time_up_is_reported_once_the_clock_runs_out() -> void:
	var flow := _flow()
	assert_bool(flow.is_time_up()).is_false()

	flow.clock.spend(DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY)

	assert_bool(flow.is_time_up()).is_true()
	assert_str(flow.perform("move")).contains("時限已到")


func test_a_save_from_before_the_time_limit_can_still_be_restored() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(flow.snapshot()))
	flow.clock.spend(DayClock.TOTAL_DAYS * DayClock.SEGMENTS_PER_DAY)

	var restored := _flow()

	assert_bool(restored.restore(saved)).is_true()
	assert_bool(restored.is_time_up()).is_false()
