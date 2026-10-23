extends GdUnitTestSuite
# Unit tests for affinity, blood curse and berserk handling inside the skirmish resolver.
# Rolls are zero so damage is exact.

const TABLE: Dictionary = {
	"weak_multiplier": 1.5,
	"resist_multiplier": 0.5,
	"matchups": {"purify": {"weak": ["restless_spirit"], "resist": []}},
}


func test_weakness_increases_damage_per_hit() -> void:
	# Arrange: 10 attack with a purify tag against a restless spirit = 15 per hit; 30 hp needs 2 hits
	var party: Array = [{"atk": 10, "attack_tag": "purify"}]
	var options := {"enemy_tags": ["restless_spirit"], "affinity": TABLE}

	# Act
	var result := Skirmish.resolve(party, 30, 0, [0.0], 20, options)

	# Assert
	assert_bool(result["won"]).is_true()
	assert_int(result["rounds"]).is_equal(2)


func test_neutral_tag_leaves_damage_unchanged() -> void:
	# Arrange: physical has no matchup, so 10 damage per hit; 30 hp needs 3 hits
	var party: Array = [{"atk": 10}]
	var options := {"enemy_tags": ["restless_spirit"], "affinity": TABLE}

	# Act
	var result := Skirmish.resolve(party, 30, 0, [0.0], 20, options)

	# Assert
	assert_int(result["rounds"]).is_equal(3)


func test_blood_curse_triggers_berserk_after_five_rounds_when_not_blocked() -> void:
	# Arrange: a party member that never kills the enemy, so five rounds pass
	var curse := BloodCurse.new()
	var party: Array = [{"atk": 1, "curse": curse, "can_block_berserk": false}]

	# Act
	var result := Skirmish.resolve(party, 999, 0, [0.0], 5)

	# Assert: the fifth round is berserk, which consumes the full curse
	assert_int(result["berserk_rounds"]).is_equal(1)
	assert_int(result["rounds"]).is_equal(5)
	assert_int(curse.stacks).is_equal(0)


func test_berserk_skips_the_attack_on_the_turn_it_triggers() -> void:
	# Arrange: six rounds, so the fifth round is berserk and the sixth is normal
	var curse := BloodCurse.new()
	var party: Array = [{"atk": 1, "curse": curse, "can_block_berserk": false}]

	# Act
	var result := Skirmish.resolve(party, 999, 0, [0.0], 6)

	# Assert
	assert_int(result["berserk_rounds"]).is_equal(1)
	assert_int(result["enemy_hp_left"]).is_equal(999 - 5)


func test_synergy_block_prevents_berserk_and_is_reported() -> void:
	# Arrange
	var curse := BloodCurse.new()
	var party: Array = [{"atk": 1, "curse": curse, "can_block_berserk": true}]

	# Act
	var result := Skirmish.resolve(party, 999, 0, [0.0], 6)

	# Assert
	assert_int(result["berserk_rounds"]).is_equal(0)
	assert_int(result["blocked_berserk"]).is_equal(1)
