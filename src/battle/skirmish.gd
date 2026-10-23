class_name Skirmish
extends RefCounted
## One-sided skirmish resolver: the whole party attacks a single enemy each round
## until the enemy falls, the round limit is reached, or the party is empty.
## Rolls are consumed in order and cycled, so the outcome is deterministic.

## Default round limit before the skirmish is treated as a loss.
const DEFAULT_ROUND_LIMIT: int = 20


## party: Array of Dictionaries, each with an "atk" int key.
## enemy_hp: enemy hit points at the start of the skirmish.
## enemy_def: enemy defense used by the damage formula.
## rolls: variance values in [-0.10, 0.10]; cycled when exhausted (empty means 0.0).
## Returns { "won": bool, "rounds": int, "enemy_hp_left": int }.
static func resolve(
		party: Array,
		enemy_hp: int,
		enemy_def: int,
		rolls: Array,
		round_limit: int = DEFAULT_ROUND_LIMIT) -> Dictionary:
	var hp: int = enemy_hp
	var rounds: int = 0
	var roll_index: int = 0

	while hp > 0 and rounds < round_limit and not party.is_empty():
		rounds += 1
		for member: Dictionary in party:
			var roll: float = 0.0
			if not rolls.is_empty():
				roll = float(rolls[roll_index % rolls.size()])
			roll_index += 1

			hp -= DamageCalculator.calculate(int(member["atk"]), 1.0, enemy_def, roll)
			if hp <= 0:
				break

	return {
		"won": hp <= 0,
		"rounds": rounds,
		"enemy_hp_left": maxi(hp, 0),
	}
