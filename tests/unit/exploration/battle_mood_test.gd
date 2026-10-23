extends GdUnitTestSuite
# Unit tests for the mood the flow reports for music: battle for the action that fought, night for the
# night segment, and nothing otherwise. A battle mood lasts only until the next action.


func _party() -> Array:
	return [
		{"id": "freya", "name": "f", "atk": 1, "curse": true},
		{"id": "eron", "name": "e", "atk": 40},
	]


func test_a_battle_action_sets_the_battle_mood() -> void:
	var flow := DayOneFlow.new(_party(), [0.0], {})

	flow.perform("battle")

	assert_str(flow.mood()).is_equal("battle")


func test_the_battle_mood_ends_with_the_next_action() -> void:
	var flow := DayOneFlow.new(_party(), [0.0], {})
	flow.perform("battle")

	flow.perform("move")

	assert_str(flow.mood()).is_not_equal("battle")


func test_the_night_segment_sets_the_night_mood() -> void:
	var flow := DayOneFlow.new(_party(), [0.0], {})
	flow.clock.spend(2)

	assert_str(flow.mood()).is_equal("night")


func test_daytime_without_a_fight_has_no_mood() -> void:
	var flow := DayOneFlow.new(_party(), [0.0], {})

	assert_str(flow.mood()).is_empty()
