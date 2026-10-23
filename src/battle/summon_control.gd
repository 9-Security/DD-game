class_name SummonControl
extends RefCounted
## Inry's summon control: a failed summon can go wrong, and the outcome is drawn
## from a fixed 40/30/30 split. Rules come from design/GAME_DESIGN_MASTER.md section 3.2.
## Random rolls are supplied by the caller so every result is deterministic.

const BASE_FAILURE_CHANCE: float = 0.15
const LOW_MP_PENALTY: float = 0.10
## MP share below which the failure chance rises.
const LOW_MP_RATIO: float = 0.30

const POSITIVE_SHARE: float = 0.40
const NEUTRAL_SHARE: float = 0.30


## Failure chance for a summon, given current and maximum MP.
static func failure_chance(current_mp: int, max_mp: int) -> float:
	var chance: float = BASE_FAILURE_CHANCE
	if max_mp > 0 and float(current_mp) / float(max_mp) < LOW_MP_RATIO:
		chance += LOW_MP_PENALTY
	return chance


## True when the roll falls inside the failure chance.
static func is_failure(roll: float, chance: float) -> bool:
	return roll < chance


## Maps a roll in [0, 1) to "positive", "neutral" or "negative".
static func outcome_for_roll(roll: float) -> String:
	if roll < POSITIVE_SHARE:
		return "positive"
	if roll < POSITIVE_SHARE + NEUTRAL_SHARE:
		return "neutral"
	return "negative"
