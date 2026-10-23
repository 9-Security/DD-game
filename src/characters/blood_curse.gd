class_name BloodCurse
extends RefCounted
## Freya's blood curse: stacks build up with each Blood Rage, weaken her maximum HP,
## raise the chance of losing control, and cause one turn of berserk at full stacks.
## Rule values come from design/GAME_DESIGN_MASTER.md section 3.2.

const MAX_STACKS: int = 5
## Maximum HP lost per stack, as a fraction of the base maximum.
const HP_LOSS_PER_STACK: float = 0.05
## Added chance of losing control per stack.
const CONTROL_LOSS_PER_STACK: float = 0.02

var stacks: int = 0


## Adds one stack, capped at MAX_STACKS. Returns the new stack count.
func add_stack() -> int:
	stacks = mini(stacks + 1, MAX_STACKS)
	return stacks


## Removes every stack. Used by Eron's purifying breath.
func purify() -> void:
	stacks = 0


## Multiplier applied to the base maximum HP.
func max_hp_multiplier() -> float:
	return 1.0 - stacks * HP_LOSS_PER_STACK


## Chance that Freya loses control on a turn.
func loss_of_control_chance() -> float:
	return stacks * CONTROL_LOSS_PER_STACK


## True when the curse is full and Freya is berserk on the next turn.
func is_berserk() -> bool:
	return stacks >= MAX_STACKS


## If the curse is full, consumes it (stacks reset) and returns true.
## The reset is a project decision: the design fixes the trigger, not the aftermath.
func consume_full_curse() -> bool:
	if not is_berserk():
		return false
	stacks = 0
	return true
