class_name DamageCalculator
extends RefCounted
## Damage formula from design/GAME_DESIGN_MASTER.md section 4.2.
## The random roll is supplied by the caller so the result is deterministic.

## Maximum random variance applied to the base damage (plus or minus).
const ROLL_LIMIT: float = 0.10
## Damage can never fall below this value.
const MIN_DAMAGE: int = 1
## Share of the target's defense that reduces incoming damage.
const DEFENSE_FACTOR: float = 0.5


## Calculates final damage for one hit.
## attack: attacker's attack stat
## multiplier: skill multiplier (1.0 for a basic attack)
## defense: target's defense stat
## roll: random variance in [-ROLL_LIMIT, ROLL_LIMIT]; values outside are clamped
static func calculate(attack: int, multiplier: float, defense: int, roll: float) -> int:
	var clamped_roll: float = clampf(roll, -ROLL_LIMIT, ROLL_LIMIT)
	var base: float = attack * multiplier - defense * DEFENSE_FACTOR
	var final_value: float = base * (1.0 + clamped_roll)
	return maxi(MIN_DAMAGE, roundi(final_value))
