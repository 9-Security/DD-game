extends GdUnitTestSuite
# Unit tests for the interactive turn-based battle: turn order, the four commands, the v1 skills,
# and the win, loss and round-limit outcomes. Rolls are fixed so every result is deterministic.


func _member(id: String, speed: int, hp: int, atk: int, def: int, skill: String) -> Dictionary:
	return {"id": id, "name": id, "hp": hp, "max_hp": hp, "mp": 60, "atk": atk, "def": def, "speed": speed, "skill": skill}


func _skills() -> Dictionary:
	return {
		"life_resonance": {"cost": 15, "kind": "heal", "amount": 20},
		"iron_guard": {"cost": 10, "kind": "guard", "multiplier": 0.25},
		"rune_trap": {"cost": 15, "kind": "mark", "multiplier": 1.5},
		"mana_surge": {"cost": 40, "kind": "attack", "multiplier": 2.0},
	}


func _enemy(hp: int, atk: int) -> Dictionary:
	return {"name": "enemy", "hp": hp, "max_hp": hp, "def": 0, "atk": atk}


func _battle(party: Array, enemy: Dictionary, rolls: Array = [0.0], round_limit: int = 20) -> TurnBattle:
	return TurnBattle.new(party, enemy, rolls, round_limit, _skills())


func test_turn_order_follows_speed_from_high_to_low() -> void:
	var battle := _battle([
		_member("slow", 5, 50, 1, 0, "iron_guard"),
		_member("fast", 12, 50, 1, 0, "iron_guard"),
		_member("mid", 9, 50, 1, 0, "iron_guard"),
	], _enemy(500, 1))

	assert_array(battle.turn_order()).is_equal(["fast", "mid", "slow"])


func test_attack_damages_the_enemy_by_the_damage_formula() -> void:
	var battle := _battle([_member("eron", 9, 90, 10, 0, "life_resonance")], _enemy(100, 1))

	var result := battle.act("eron", "attack")

	assert_bool(result["ok"]).is_true()
	assert_int(battle.enemy_hp()).is_equal(90)


func test_defend_halves_the_enemy_hit_that_follows_it() -> void:
	# Once every living member has acted, the enemy strikes: 20 attack - 0 defense, halved by the guard.
	var battle := _battle([_member("eron", 9, 90, 1, 0, "life_resonance")], _enemy(100, 20))

	battle.act("eron", "defend")

	assert_int(battle.member_hp("eron")).is_equal(90 - 10)


func test_retreat_succeeds_when_the_roll_is_not_negative() -> void:
	var battle := _battle([_member("eron", 9, 90, 1, 0, "life_resonance")], _enemy(100, 1), [0.0])

	battle.act("eron", "retreat")

	assert_str(battle.outcome()).is_equal("fled")


func test_retreat_that_fails_gives_the_enemy_an_extra_attack() -> void:
	var battle := _battle([_member("eron", 9, 90, 1, 0, "life_resonance")], _enemy(100, 20), [-0.05])

	battle.act("eron", "retreat")

	assert_str(battle.outcome()).is_empty()
	assert_int(battle.member_hp("eron")).is_less(90)


func test_a_skill_without_enough_mp_is_refused() -> void:
	var member := _member("freya", 6, 130, 16, 10, "iron_guard")
	member["mp"] = 5
	var battle := _battle([member], _enemy(100, 1))

	var result := battle.act("freya", "skill")

	assert_bool(result["ok"]).is_false()


func test_life_resonance_heals_an_ally_but_not_above_max_hp() -> void:
	var wounded := _member("freya", 6, 130, 16, 10, "iron_guard")
	wounded["hp"] = 125
	var battle := _battle([_member("eron", 12, 90, 1, 0, "life_resonance"), wounded], _enemy(500, 1))

	battle.act("eron", "skill", "freya")

	assert_int(battle.member_hp("freya")).is_equal(130)


func test_rune_trap_raises_the_damage_of_the_next_hit_on_the_enemy() -> void:
	var battle := _battle([_member("richter", 13, 85, 10, 5, "rune_trap")], _enemy(100, 1))

	battle.act("richter", "skill")
	battle.act("richter", "attack")

	# Trap marks the enemy at 1.5x; the attack then deals 10 * 1.5 = 15 damage.
	assert_int(battle.enemy_hp()).is_equal(100 - 15)


func test_mana_surge_deals_double_attack_damage() -> void:
	var battle := _battle([_member("inry", 10, 80, 10, 4, "mana_surge")], _enemy(100, 1))

	battle.act("inry", "skill")

	assert_int(battle.enemy_hp()).is_equal(100 - 20)


func test_defeating_the_enemy_wins_the_battle() -> void:
	var battle := _battle([_member("eron", 9, 90, 50, 0, "life_resonance")], _enemy(10, 1))

	battle.act("eron", "attack")

	assert_str(battle.outcome()).is_equal("won")


func test_the_whole_party_falling_loses_the_battle() -> void:
	var battle := _battle([_member("eron", 9, 1, 1, 0, "life_resonance")], _enemy(100, 500))

	battle.act("eron", "defend")

	assert_str(battle.outcome()).is_equal("lost")


func test_reaching_the_round_limit_loses_the_battle() -> void:
	var battle := _battle([_member("eron", 9, 90, 1, 0, "life_resonance")], _enemy(100, 0), [0.0], 2)

	battle.act("eron", "defend")
	battle.act("eron", "defend")

	assert_str(battle.outcome()).is_equal("lost")


func test_the_enemy_attacks_the_living_member_with_the_lowest_hp() -> void:
	var battle := _battle([
		_member("eron", 9, 90, 1, 0, "life_resonance"),
		_member("freya", 6, 40, 1, 0, "iron_guard"),
	], _enemy(500, 20))

	battle.act("eron", "defend")
	battle.act("freya", "defend")

	assert_int(battle.member_hp("freya")).is_less(40)
	assert_int(battle.member_hp("eron")).is_equal(90)


func test_an_action_out_of_turn_is_refused() -> void:
	var battle := _battle([
		_member("fast", 12, 50, 1, 0, "iron_guard"),
		_member("slow", 5, 50, 1, 0, "iron_guard"),
	], _enemy(500, 1))

	var result := battle.act("slow", "defend")

	assert_bool(result["ok"]).is_false()


func test_member_mp_reports_the_mp_left_after_a_skill() -> void:
	var battle := _battle([_member("inry", 10, 80, 10, 4, "mana_surge")], _enemy(500, 1))

	battle.act("inry", "skill")

	assert_int(battle.member_mp("inry")).is_equal(60 - 40)


func _cursed_member(id: String, stacks: int) -> Dictionary:
	var member := _member(id, 12, 130, 16, 10, "iron_guard")
	member["curse_stacks"] = stacks
	return member


func test_a_cursed_member_gains_one_stack_on_each_turn() -> void:
	var battle := _battle([_cursed_member("freya", 0)], _enemy(500, 1))

	battle.act("freya", "defend")

	assert_int(battle.curse_stacks("freya")).is_equal(1)


func test_a_full_curse_makes_the_turn_berserk_and_resets_the_stacks() -> void:
	var battle := _battle([_cursed_member("freya", 4)], _enemy(100, 1))

	var result := battle.act("freya", "attack")

	assert_bool(result["ok"]).is_true()
	assert_str(str(result["message"])).contains("狂亂")
	assert_int(battle.enemy_hp()).is_equal(100)
	assert_int(battle.curse_stacks("freya")).is_equal(0)


func test_a_refused_action_does_not_add_a_curse_stack() -> void:
	var member := _cursed_member("freya", 2)
	member["mp"] = 0
	var battle := _battle([member], _enemy(100, 1))

	battle.act("freya", "skill")

	assert_int(battle.curse_stacks("freya")).is_equal(2)


func test_a_member_without_a_curse_has_no_curse_stacks() -> void:
	var battle := _battle([_member("eron", 9, 90, 1, 0, "life_resonance")], _enemy(500, 1))

	battle.act("eron", "defend")

	assert_int(battle.curse_stacks("eron")).is_equal(0)
