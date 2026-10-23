class_name Skirmish
extends RefCounted
## One-sided skirmish resolver: the whole party attacks a single enemy each round
## until the enemy falls, the round limit is reached, or the party is empty.
## Rolls are consumed in order and cycled, so the outcome is deterministic.
##
## Each party member is a Dictionary:
##   "atk": int (required)
##   "attack_tag": String (optional, default "physical"), matched against the affinity table
##   "curse": BloodCurse (optional). Each round adds one stack. A full curse makes that
##            round berserk, so the member does not attack, unless the synergy blocks it.
##   "can_block_berserk": bool (optional). True when an active synergy blocks berserk.
##
## options (optional):
##   "enemy_tags": Array of tags on the enemy.
##   "affinity": matchup table, see Affinity.multiplier().

## Default round limit before the skirmish is treated as a loss.
const DEFAULT_ROUND_LIMIT: int = 20
const DEFAULT_ATTACK_TAG: String = "physical"


## enemy_hp: enemy hit points at the start of the skirmish.
## enemy_def: enemy defense used by the damage formula.
## rolls: variance values in [-0.10, 0.10]; cycled when exhausted (empty means 0.0).
## Returns { "won", "rounds", "enemy_hp_left", "berserk_rounds", "blocked_berserk" }.
static func resolve(
		party: Array,
		enemy_hp: int,
		enemy_def: int,
		rolls: Array,
		round_limit: int = DEFAULT_ROUND_LIMIT,
		options: Dictionary = {}) -> Dictionary:
	var hp: int = enemy_hp
	var rounds: int = 0
	var roll_index: int = 0
	var berserk_rounds: int = 0
	var blocked_berserk: int = 0
	var enemy_tags: Array = options.get("enemy_tags", [])
	var affinity: Dictionary = options.get("affinity", {})

	while hp > 0 and rounds < round_limit and not party.is_empty():
		rounds += 1
		for member: Dictionary in party:
			var roll: float = 0.0
			if not rolls.is_empty():
				roll = float(rolls[roll_index % rolls.size()])
			roll_index += 1

			var curse: BloodCurse = member.get("curse", null)
			if curse != null:
				curse.add_stack()
				if curse.consume_full_curse():
					if bool(member.get("can_block_berserk", false)):
						blocked_berserk += 1
					else:
						berserk_rounds += 1
						continue

			var tag: String = str(member.get("attack_tag", DEFAULT_ATTACK_TAG))
			var multiplier: float = Affinity.multiplier(tag, enemy_tags, affinity)
			hp -= DamageCalculator.calculate(int(member["atk"]), multiplier, enemy_def, roll)
			if hp <= 0:
				break

	return {
		"won": hp <= 0,
		"rounds": rounds,
		"enemy_hp_left": maxi(hp, 0),
		"berserk_rounds": berserk_rounds,
		"blocked_berserk": blocked_berserk,
	}
