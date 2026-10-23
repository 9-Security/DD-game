extends GdUnitTestSuite
# Unit tests for applying the result of an interactive battle to the day flow.


func _party() -> Array:
	return [
		{"id": "freya", "name": "f", "atk": 1, "curse": true},
		{"id": "eron", "name": "e", "atk": 40},
	]


func _options() -> Dictionary:
	return {"trust_gain": 10, "trust": TrustBoard.new(["eron", "freya"], 50, 0, 100)}


func test_a_battle_can_start_once_before_the_flow_has_fought() -> void:
	var flow := DayOneFlow.new(_party(), [0.0], _options())

	assert_bool(flow.can_start_battle()).is_true()


func test_a_won_battle_spends_time_and_raises_trust() -> void:
	var options := _options()
	var flow := DayOneFlow.new(_party(), [0.0], options)

	var message := flow.finish_battle("won")

	assert_int(flow.clock.segment).is_equal(1)
	assert_int(options["trust"].get_trust("eron")).is_equal(60)
	assert_str(message).contains("戰鬥勝利")


func test_a_lost_battle_spends_time_but_gives_no_trust() -> void:
	var options := _options()
	var flow := DayOneFlow.new(_party(), [0.0], options)

	flow.finish_battle("lost")

	assert_int(options["trust"].get_trust("eron")).is_equal(50)


func test_the_tutorial_battle_can_only_be_finished_once() -> void:
	var flow := DayOneFlow.new(_party(), [0.0], _options())
	flow.finish_battle("won")

	var second := flow.finish_battle("won")

	assert_bool(flow.can_start_battle()).is_false()
	assert_str(second).contains("教學戰鬥已結束")


func test_a_fled_battle_counts_as_finished_without_reward() -> void:
	var options := _options()
	var flow := DayOneFlow.new(_party(), [0.0], options)

	flow.finish_battle("fled")

	assert_bool(flow.battle_done).is_true()
	assert_int(options["trust"].get_trust("eron")).is_equal(50)
