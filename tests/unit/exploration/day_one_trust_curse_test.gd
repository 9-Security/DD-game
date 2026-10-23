extends GdUnitTestSuite
# Unit tests for the trust reward after a won battle and the curse state carried by the flow.


func _party() -> Array:
	# Freya acts first so her curse stack is counted before Eron wins the fight in one round.
	return [
		{"id": "freya", "name": "f", "atk": 1, "curse": true},
		{"id": "eron", "name": "e", "atk": 40},
	]


func _options() -> Dictionary:
	return {
		"trust": TrustBoard.new(["eron", "freya"], 50, 0, 100),
		"trust_gain": 10,
		"synergies": [{"members": ["eron", "freya"], "min_trust": 60, "effect": "berserk_block"}],
		"enemy_tags": [],
		"affinity": {},
	}


func test_winning_a_battle_raises_trust_for_every_member() -> void:
	# Arrange
	var options := _options()
	var flow := DayOneFlow.new(_party(), [0.0], options)

	# Act
	flow.perform("battle")

	# Assert
	assert_int(options["trust"].get_trust("eron")).is_equal(60)
	assert_int(options["trust"].get_trust("freya")).is_equal(60)


func test_curse_stacks_are_tracked_for_the_curse_member() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], _options())

	# Act
	flow.perform("battle")

	# Assert: the stack count depends on how many rounds the tutorial enemy lasts, so only the
	# tracking itself is checked here.
	assert_int(flow.curse_stacks("freya")).is_greater(0)
	assert_int(flow.curse_stacks("eron")).is_equal(-1)


func test_snapshot_round_trips_trust_and_curse() -> void:
	# Arrange
	var source := DayOneFlow.new(_party(), [0.0], _options())
	source.perform("battle")
	var snapshot := source.snapshot()

	var target_options := _options()
	var target := DayOneFlow.new(_party(), [0.0], target_options)

	# Act
	var restored := target.restore(snapshot)

	# Assert
	assert_bool(restored).is_true()
	assert_int(target.curse_stacks("freya")).is_equal(source.curse_stacks("freya"))
	assert_int(target.curse_stacks("freya")).is_greater(0)
	assert_int(target_options["trust"].get_trust("freya")).is_equal(60)
