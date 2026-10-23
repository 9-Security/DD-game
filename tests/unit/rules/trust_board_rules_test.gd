extends GdUnitTestSuite
# Unit tests for character trust values and team synergies.


func _board() -> TrustBoard:
	return TrustBoard.new(["eron", "freya", "richter", "inry"], 50, 0, 100)


func test_trust_starts_at_configured_value() -> void:
	# Arrange / Act
	var board := _board()

	# Assert
	assert_int(board.get_trust("eron")).is_equal(50)


func test_trust_is_clamped_to_its_range() -> void:
	# Arrange
	var board := _board()

	# Act
	board.change("eron", 80)
	board.change("freya", -80)

	# Assert
	assert_int(board.get_trust("eron")).is_equal(100)
	assert_int(board.get_trust("freya")).is_equal(0)


func test_unknown_character_is_ignored() -> void:
	# Arrange
	var board := _board()

	# Act
	var result := board.change("nobody", 10)

	# Assert
	assert_int(result).is_equal(-1)


func test_synergy_activates_only_when_every_member_meets_threshold() -> void:
	# Arrange
	var board := _board()
	var synergies := [{"members": ["eron", "freya"], "min_trust": 60, "effect": "berserk_block"}]
	board.change("eron", 20)  # 70

	# Act / Assert: freya is still at 50
	assert_int(board.active_synergies(synergies).size()).is_equal(0)

	board.change("freya", 10)  # 60
	assert_int(board.active_synergies(synergies).size()).is_equal(1)
	assert_str(board.active_synergies(synergies)[0]).is_equal("berserk_block")
