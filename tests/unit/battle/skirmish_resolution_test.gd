extends GdUnitTestSuite
# Unit tests for the one-sided skirmish resolver used by the day-one tutorial battle.
# Rolls are injected and cycled, so every outcome is deterministic.


func _member(attack: int) -> Dictionary:
	return {"name": "test-member", "atk": attack}


func test_single_attacker_defeats_enemy_in_expected_rounds() -> void:
	# Arrange: 16 attack vs 0 defense, zero roll -> 16 damage per round; 30 hp needs 2 rounds
	var party: Array = [_member(16)]

	# Act
	var result := Skirmish.resolve(party, 30, 0, [0.0])

	# Assert
	assert_bool(result["won"]).is_true()
	assert_int(result["rounds"]).is_equal(2)
	assert_int(result["enemy_hp_left"]).is_equal(0)


func test_enemy_survives_when_party_cannot_finish_within_round_limit() -> void:
	# Arrange: 1 attack vs 0 defense -> 1 damage per round, round limit is 3 by default
	var party: Array = [_member(1)]

	# Act
	var result := Skirmish.resolve(party, 30, 0, [0.0], 3)

	# Assert
	assert_bool(result["won"]).is_false()
	assert_int(result["rounds"]).is_equal(3)
	assert_int(result["enemy_hp_left"]).is_equal(27)


func test_all_members_attack_each_round() -> void:
	# Arrange: two members with 10 attack each -> 20 damage per round; 40 hp needs 2 rounds
	var party: Array = [_member(10), _member(10)]

	# Act
	var result := Skirmish.resolve(party, 40, 0, [0.0])

	# Assert
	assert_bool(result["won"]).is_true()
	assert_int(result["rounds"]).is_equal(2)


func test_empty_party_cannot_win() -> void:
	# Arrange
	var party: Array = []

	# Act
	var result := Skirmish.resolve(party, 30, 0, [0.0])

	# Assert
	assert_bool(result["won"]).is_false()
	assert_int(result["rounds"]).is_equal(0)
