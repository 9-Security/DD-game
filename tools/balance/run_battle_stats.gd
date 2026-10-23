extends SceneTree
# Development tool: runs the real TurnBattle many times per enemy with a baseline policy and prints
# win rate, rounds and party HP lost. Run: godot --headless -s res://tools/balance/run_battle_stats.gd
# Not part of the game.

const BATTLES: int = 300
const ROLLS_PER_BATTLE: int = 400


func _initialize() -> void:
	var skill_file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/battle/skills.json"))
	var enemies: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/battle/enemies.json"))
	var party_total: int = 0
	var party_template: Array = []
	for id: String in ["eron", "freya", "richter", "inry"]:
		var character: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/characters/%s.json" % id))
		var skill_id: String = str(skill_file["representative"][id])
		var stacks: int = 0 if id == "freya" else -1
		var member: Dictionary = BattleSetup.party_member(character, skill_id, stacks)
		party_total += int(member["max_hp"])
		party_template.append(member)
	for key: String in ["tutorial", "stone_flower_beast", "blood_oath_armor", "mirror_freya"]:
		var stats: Dictionary = _run(party_template, enemies[key], skill_file["skills"], party_total)
		print("%-20s win %5.1f%%  rounds %4.1f  party HP lost %5.1f%%" % [key, stats["win"] * 100.0, stats["rounds"], stats["loss"] * 100.0])
	quit(0)


func _run(template: Array, enemy: Dictionary, skills: Dictionary, party_total: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var wins: int = 0
	var rounds: int = 0
	var hp_left: int = 0
	for battle: int in range(BATTLES):
		var rolls: Array = []
		for index: int in range(ROLLS_PER_BATTLE):
			rolls.append(rng.randf_range(-0.1, 0.1))
		var party: Array = template.duplicate(true)
		var fight := TurnBattle.new(party, enemy.duplicate(true), rolls, Skirmish.DEFAULT_ROUND_LIMIT, skills)
		var guard: int = 0
		while fight.outcome() == "":
			guard += 1
			if guard > 2000:
				push_error("battle did not end: outcome empty after %d actions" % guard)
				return {"win": 0.0, "rounds": 0.0, "loss": 0.0}
			var actor: String = fight.turn_order()[0]
			var member: Dictionary = _member(party, actor)
			var skill: Dictionary = skills[str(member["skill"])]
			var target: String = ""
			var command: String = "attack"
			if fight.member_mp(actor) >= int(skill["cost"]):
				command = "skill"
				if skill["kind"] == "heal":
					target = _lowest_hurt_ally(party, fight)
					if target == "":
						command = "attack"
			fight.act(actor, command, target)
		if fight.outcome() == "won":
			wins += 1
			rounds += fight.rounds
			for member: Dictionary in party:
				hp_left += maxi(0, fight.member_hp(str(member["id"])))
	return {
		"win": float(wins) / BATTLES,
		"rounds": float(rounds) / maxi(wins, 1),
		"loss": 1.0 - float(hp_left) / maxi(wins, 1) / float(party_total),
	}


func _member(party: Array, id: String) -> Dictionary:
	for member: Dictionary in party:
		if str(member["id"]) == id:
			return member
	return {}


func _lowest_hurt_ally(party: Array, fight: TurnBattle) -> String:
	var target: String = ""
	var lowest: int = 1 << 30
	for member: Dictionary in party:
		var id: String = str(member["id"])
		var hp: int = fight.member_hp(id)
		if hp > 0 and hp < int(member["max_hp"]) and hp < lowest:
			lowest = hp
			target = id
	return target
