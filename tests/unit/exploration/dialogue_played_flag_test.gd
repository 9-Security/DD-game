extends GdUnitTestSuite
# Unit tests for the dialogue played flag: a scene is recorded once and the record survives a snapshot.


func _flow() -> DayOneFlow:
	return DayOneFlow.new([], [0.0], {"events": []})


func test_scene_is_not_played_before_it_is_marked() -> void:
	var flow := _flow()

	assert_bool(flow.dialogue_played("ch2_dialogue_confess_eron")).is_false()


func test_marked_scene_reports_as_played() -> void:
	var flow := _flow()

	flow.mark_dialogue_played("ch2_dialogue_confess_eron")

	assert_bool(flow.dialogue_played("ch2_dialogue_confess_eron")).is_true()
	assert_bool(flow.dialogue_played("ch2_dialogue_confess_freya")).is_false()


func test_played_scene_stays_played_after_a_snapshot_restore() -> void:
	var flow := _flow()
	flow.mark_dialogue_played("ch2_dialogue_confess_eron")
	var restored := _flow()

	var ok := restored.restore(flow.snapshot())

	assert_bool(ok).is_true()
	assert_bool(restored.dialogue_played("ch2_dialogue_confess_eron")).is_true()
