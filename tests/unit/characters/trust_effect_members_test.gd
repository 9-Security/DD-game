extends GdUnitTestSuite
# Unit tests for finding which members an active synergy effect applies to.


func _board() -> TrustBoard:
	return TrustBoard.new(["eron", "freya", "richter", "inry"], 50, 0, 100)


func test_effect_members_are_listed_only_when_the_synergy_is_active() -> void:
	# Arrange
	var board := _board()
	var synergies := [{"members": ["eron", "freya"], "min_trust": 60, "effect": "berserk_block"}]

	# Act / Assert: both at 50, inactive
	assert_int(board.members_with_effect(synergies, "berserk_block").size()).is_equal(0)

	board.change("eron", 10)
	board.change("freya", 10)
	var members := board.members_with_effect(synergies, "berserk_block")
	assert_bool(members.has("freya")).is_true()
	assert_bool(members.has("eron")).is_true()


func test_other_effects_are_not_listed() -> void:
	# Arrange
	var board := _board()
	board.change("eron", 20)
	board.change("freya", 20)
	var synergies := [{"members": ["eron", "freya"], "min_trust": 60, "effect": "berserk_block"}]

	# Act / Assert
	assert_int(board.members_with_effect(synergies, "something_else").size()).is_equal(0)
