class_name DayOneFlow
extends RefCounted
## Day-one action flow: connects the seven-day clock to player actions, supply use,
## night events, trust, blood curses and the tutorial skirmish. The UI only displays
## the messages it returns. Saving is allowed only at camp (after a successful rest),
## and loading never rewinds time.

## Segment cost of each player action (design/GAME_DESIGN_MASTER.md section 2.1).
const ACTION_COSTS: Dictionary = {"move": 1, "explore": 1, "rest": 2, "battle": 1}
const SEGMENT_NAMES: Array[String] = ["晨", "午", "夜"]

## Placeholder values for the tutorial enemy. These are not design-document values.
const TUTORIAL_ENEMY_HP: int = 80
const TUTORIAL_ENEMY_DEF: int = 2

## Fallback stats for a night battle entry that does not define its own enemy.
const DEFAULT_NIGHT_ENEMY_HP: int = 20
const DEFAULT_NIGHT_ENEMY_DEF: int = 1

const DEFAULT_ATTACK_TAG: String = "physical"
const WRONG_PLACE_TEXT: String = "這裡沒有可以進行這個行動的地方。"
const BERSERK_EFFECT: String = "berserk_block"

## Version of the snapshot format written by snapshot(). Bump on any change.
const SNAPSHOT_VERSION: int = 7

var clock: DayClock
var battle_done: bool = false
var rest_food_cost: int = 0

var _party: Array
var _rolls: Array
var _at_camp: bool = false
var _supply: SupplyPool
var _night_entries: Array
var _night_rolls: Array
var _night_roll_index: int = 0
var _trust: TrustBoard
var _trust_gain: int = 0
var _synergies: Array
var _enemy_tags: Array
var _affinity: Dictionary
var _attack_tags: Dictionary
var _curses: Dictionary = {}
var _encounters: Array = []
var _encounter_index: int = 0
var _pending: Encounter = null
## The approach of the encounter fight currently on the battle screen, or "" when none.
var _fight_approach: String = ""
var _party_skills: Dictionary = {}
var _approach_skills: Dictionary = {}
var _encounter_rolls: Array = [0.0]
var _location: String = ""
var _events: EventRunner = null
var _night_entered: bool = false
var _battle_this_action: bool = false
var _acquired: Dictionary = {}
var _wounds: Dictionary = {}
var _mirror_counter: Dictionary = {}
## Enemy definitions for fights on the battle screen, keyed by enemy id.
var _battle_enemies: Dictionary = {}
## A story fight waiting on the battle screen: {kind: "sequence" | "mirror", enemy, action, ...}.
var _story_fight: Dictionary = {}
var _location_requirements: Dictionary = {}
var _location_actions: Dictionary = {}
var _sequences: Array = []
var _step_rolls: Array = []
var _step_roll_index: int = 0
var _step_failed: bool = false


## party: Array of Dictionaries with "id", "name", "atk" keys. A member with "curse": true
## gets a blood curse that is tracked by the flow.
## rolls: damage variance values cycled by the skirmish resolver.
## options (all optional):
##   "supply": SupplyPool. Without it, supplies are unlimited.
##   "rest_food_cost": food each rest consumes (strict 1, assisted 0).
##   "night_entries": Array of night pool entries.
##   "night_rolls": rolls in [0, 1) used to pick night entries, cycled.
##   "trust": TrustBoard. Without it, trust and synergies are inactive.
##   "trust_gain": trust each member gains after a won battle.
##   "synergies": Array of synergy definitions (see TrustBoard).
##   "enemy_tags": tags on the tutorial enemy. Night entries may define their own.
##   "affinity": matchup table for Affinity.multiplier().
##   "attack_tags": character ID -> attack tag.
##   "location_requirements": place name -> entry rule, see _entry_block().
##   "location_actions": place name -> Array of "read:" or "seal:" actions allowed there.
##   "step_rolls": rolls in [0, 1) that decide curse-raised step failures, cycled. Empty means no
##     roll-based failure.
##   "sequences": ordered step lists. Each has "id", "requires" (flag, or "" for none),
##     "blocked_text", "steps" ([{"action", "flag", "text", "hint"}]; text is optional, hint names
##     the step for the player after a failure, and the last flag is set by events), and
##     "failure" ({"text", "flag", "segments", "curse_stacks", "curse_target"}) for an out-of-order
##     step. "flag" is set to true when the failure happens. Optional "unsafe" lists actions that
##     always fail while the sequence is open, and "success" ({"curse_weaken", "curse_target"})
##     is applied when the final step succeeds.
func _init(party: Array, rolls: Array, options: Dictionary = {}) -> void:
	clock = DayClock.new()
	_party = party
	_rolls = rolls
	_supply = options.get("supply", null)
	rest_food_cost = int(options.get("rest_food_cost", 0))
	_night_entries = options.get("night_entries", [])
	_night_rolls = options.get("night_rolls", [0.0])
	_trust = options.get("trust", null)
	_trust_gain = int(options.get("trust_gain", 0))
	_synergies = options.get("synergies", [])
	_enemy_tags = options.get("enemy_tags", [])
	_affinity = options.get("affinity", {})
	_attack_tags = options.get("attack_tags", {})
	_party_skills = options.get("party_skills", {})
	_approach_skills = options.get("approach_skills", {})
	_encounter_rolls = options.get("encounter_rolls", [0.0])
	for entry: Variant in options.get("encounters", []):
		_encounters.append(Encounter.new(entry))
	_mirror_counter = options.get("mirror_counter", {})
	_battle_enemies = options.get("battle_enemies", {})
	_location_requirements = options.get("location_requirements", {})
	_location_actions = options.get("location_actions", {})
	_sequences = options.get("sequences", [])
	_step_rolls = options.get("step_rolls", [])
	if options.has("events"):
		_events = EventRunner.new(options["events"], options.get("event_flags", {}))

	for member: Dictionary in party:
		if bool(member.get("curse", false)):
			_curses[str(member.get("id", ""))] = BloodCurse.new()


## Performs a player action and returns a message for the log.
## Performs a player action and returns a message for the log. Narrative events run
## only after an action that actually happened.
func perform(action: String) -> String:
	if is_over():
		return "時限已到，無法再行動。" if is_time_up() else "結局已定，無法再行動。"
	var ran: bool = _can_run(action)
	_night_entered = false
	_battle_this_action = false
	_step_failed = false
	var text: String = _perform_action(action)
	if ran and not _step_failed and _events != null and _story_fight.is_empty():
		text += _run_events(action)
	return text


## True when the tutorial battle can still be started: not yet fought, the story is not over, and
## the battle action is open here. The interactive battle screen checks this before it opens.
func can_start_battle() -> bool:
	return not battle_done and not is_over() and _can_run("battle")


## Applies the result of an interactive battle. outcome is "won", "lost" or "fled".
## stacks: blood-curse stacks after the battle, keyed by member id; written back to the flow.
## Spends the battle's time, marks the tutorial battle as done, and grants the victory reward
## only when the party won. Returns the text for the log.
func finish_battle(outcome: String, stacks: Dictionary = {}) -> String:
	if battle_done:
		return "教學戰鬥已結束。"
	if is_over():
		return "時限已到，無法再行動。" if is_time_up() else "結局已定，無法再行動。"
	for id: String in stacks:
		if _curses.has(id):
			_curses[id].stacks = clampi(int(stacks[id]), 0, BloodCurse.MAX_STACKS)
	var spend_text: String = _spend(ACTION_COSTS["battle"])
	battle_done = true
	_battle_this_action = true
	match outcome:
		"won":
			return "戰鬥勝利。" + _reward_victory() + spend_text
		"fled":
			return "你撤出了戰鬥。" + spend_text
	return "戰鬥失敗，隊伍退出了這場戰鬥。" + spend_text


## Blood-curse stacks of every cursed member, keyed by member id.
func all_curse_stacks() -> Dictionary:
	var stacks: Dictionary = {}
	for id: String in _curses:
		stacks[id] = _curses[id].stacks
	return stacks


## The mood of the current moment for the music: "battle" while the last action fought,
## "night" during the night segment, and "" otherwise. A battle mood ends with the next action.
func mood() -> String:
	if _battle_this_action:
		return "battle"
	if clock.segment == DayClock.SEGMENT_NIGHT:
		return "night"
	return ""


## True once the seven-day limit has run out. No further actions are possible.
func is_time_up() -> bool:
	return clock.is_expired()


## The ending reached, "END_A", "END_B", "END_C", or "" while the story continues.
## Running out of time without another ending reaches END_C, as the manuscript's time-limit rule says.
func ending_id() -> String:
	if event_flag("ending_a"):
		return "END_A"
	if event_flag("ending_b"):
		return "END_B"
	if event_flag("ending_c") or is_time_up():
		return "END_C"
	return ""


## True once an ending has been reached.
func is_ended() -> bool:
	return ending_id() != ""


## True when no further action is possible: time has run out or an ending has been reached.
func is_over() -> bool:
	return is_time_up() or is_ended()


## Current location, empty before the first move.
func location() -> String:
	return _location


## True when the place has no entry requirement, or the requirement is met.
func can_enter(place: String) -> bool:
	return _entry_block(place) == ""


## True when the action belongs to an ordered sequence (a step or an unsafe action).
func is_step(action: String) -> bool:
	return not _sequence_for(action).is_empty()


## True when the step for the action has already been completed. An unsafe action counts as
## done once the sequence's final step has been completed.
func step_done(action: String) -> bool:
	var sequence: Dictionary = _sequence_for(action)
	if sequence.is_empty():
		return false
	var index: int = _step_index(sequence, action)
	if index < 0:
		return event_flag(_final_flag(sequence))
	return event_flag(str(_steps(sequence)[index]["flag"]))


## The hint of the first step before the limit that is not done, or "" when all are done.
func _missing_hint(sequence: Dictionary, limit: int) -> String:
	var steps: Array = _steps(sequence)
	for index: int in range(mini(limit, steps.size())):
		if not event_flag(str(steps[index]["flag"])):
			return str(steps[index].get("hint", ""))
	return ""


func _final_flag(sequence: Dictionary) -> String:
	var steps: Array = _steps(sequence)
	return str(steps[steps.size() - 1]["flag"])


func _is_unsafe(sequence: Dictionary, action: String) -> bool:
	return (sequence.get("unsafe", []) as Array).has(action)


## True when the action is an open, unfinished step that the party can see and try.
func step_visible(action: String) -> bool:
	var sequence: Dictionary = _sequence_for(action)
	if sequence.is_empty() or not _location_allows(action) or step_done(action):
		return false
	return _requirement_met(sequence)


## The ordered sequence that contains the action, or an empty Dictionary.
func _sequence_for(action: String) -> Dictionary:
	for sequence: Dictionary in _sequences:
		if _step_index(sequence, action) >= 0 or _is_unsafe(sequence, action):
			return sequence
	return {}


func _steps(sequence: Dictionary) -> Array:
	return sequence["steps"]


func _step_index(sequence: Dictionary, action: String) -> int:
	var steps: Array = _steps(sequence)
	for index: int in range(steps.size()):
		if str(steps[index]["action"]) == action:
			return index
	return -1


## True when every required flag is set and no forbidden flag is set. Both may be a single name
## or an Array of names.
func _requirement_met(sequence: Dictionary) -> bool:
	for name: String in _names(sequence.get("requires", [])):
		if not event_flag(name):
			return false
	for name: String in _names(sequence.get("forbids", [])):
		if event_flag(name):
			return false
	return true


func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			if str(item) != "":
				result.append(str(item))
	elif str(value) != "":
		result.append(str(value))
	return result


func _prior_steps_done(sequence: Dictionary, index: int) -> bool:
	var steps: Array = _steps(sequence)
	for prior: int in range(index):
		if not event_flag(str(steps[prior]["flag"])):
			return false
	return true


## True when the step can succeed now. Refused or failed steps run no events.
func _sequence_ready(action: String) -> bool:
	var sequence: Dictionary = _sequence_for(action)
	if _is_unsafe(sequence, action):
		return false
	if not _location_allows(action) or not _requirement_met(sequence) or step_done(action):
		return false
	return _prior_steps_done(sequence, _step_index(sequence, action))


## Runs one step. A step out of order fails and resets the sequence.
func _perform_step(action: String) -> String:
	var sequence: Dictionary = _sequence_for(action)
	if sequence.is_empty() or _events == null or not _location_allows(action):
		return WRONG_PLACE_TEXT
	if not _requirement_met(sequence):
		return str(sequence.get("blocked_text", "時機還未到。"))
	if _is_unsafe(sequence, action):
		if event_flag(_final_flag(sequence)):
			return "守衛已經瓦解。"
		return _sequence_failure(sequence, _steps(sequence).size())
	var index: int = _step_index(sequence, action)
	var steps: Array = _steps(sequence)
	var step_flag: String = str(steps[index]["flag"])
	if event_flag(step_flag):
		return "這一步已經完成了。"
	if not _prior_steps_done(sequence, index):
		return _sequence_failure(sequence, index)
	var risk: float = _curse_risk(sequence, action)
	if risk > 0.0 and _next_step_roll() < risk:
		var curse_text: String = str(sequence["curse_risk"].get("text", "血之詛咒擾亂了你的動作。"))
		return _sequence_failure(sequence, 0, curse_text, false)
	var battle: Dictionary = sequence.get("battle", {})
	if index == steps.size() - 1 and _has_enemy(str(battle.get("enemy", ""))):
		# The final step is a fight: it completes only when the battle is won.
		_story_fight = {"kind": "sequence", "enemy": str(battle["enemy"]), "action": action, "sequence": sequence}
		return str(battle.get("text", "敵人擋住了去路。"))
	var late_text: String = ""
	var chance: float = _chance_risk(sequence, action)
	if chance > 0.0 and _next_step_roll() < chance:
		var risk_data: Dictionary = sequence["risk"]
		var late_flag: String = str(risk_data.get("late_flag", ""))
		if late_flag != "":
			_events.flags[late_flag] = true
		late_text = _spend(int(risk_data.get("late_segments", 0)))
	_at_camp = false
	var text: String = ""
	if index < steps.size() - 1:
		_events.flags[step_flag] = true
		text = _step_text(sequence, index)
	else:
		_apply_success(sequence)
	var cost_text: String = _spend(int(sequence.get("cost", 0)))
	if sequence.has("to"):
		_location = str(sequence["to"])
	if text == "":
		text = "你依序行動，線條隨之動了起來。"
	return text + late_text + cost_text


## Chance that the action runs late, from the sequence's "risk" block. Zero for other actions.
func _chance_risk(sequence: Dictionary, action: String) -> float:
	var risk_data: Dictionary = sequence.get("risk", {})
	if risk_data.is_empty() or not (risk_data.get("actions", []) as Array).has(action):
		return 0.0
	return float(risk_data.get("chance", 0.0))


## The narration for a step. It is in the sequence data, so it repeats when the step is redone.
func _step_text(sequence: Dictionary, index: int) -> String:
	return str(_steps(sequence)[index].get("text", ""))


## Effects applied when a sequence's final step succeeds. Weakening never cures the curse.
func _apply_success(sequence: Dictionary) -> void:
	var success: Dictionary = sequence.get("success", {})
	var target: String = str(success.get("curse_target", ""))
	var weaken: int = int(success.get("curse_weaken", 0))
	if weaken > 0 and _curses.has(target):
		var curse: BloodCurse = _curses[target]
		curse.weaken(weaken)


## Chance that a step fails because of the curse: stacks times the per-stack chance, capped.
## Only the steps listed in the sequence's curse_risk actions are affected.
func _curse_risk(sequence: Dictionary, action: String) -> float:
	var risk_data: Dictionary = sequence.get("curse_risk", {})
	if risk_data.is_empty() or not (risk_data.get("actions", []) as Array).has(action):
		return 0.0
	var stacks: int = maxi(curse_stacks(str(risk_data.get("character", ""))), 0)
	return minf(float(risk_data.get("max", 0.0)), stacks * float(risk_data.get("per_stack", 0.0)))


## Public chance that the step fails because of the curse, for the buttons. Zero for other actions.
func step_curse_risk(action: String) -> float:
	var sequence: Dictionary = _sequence_for(action)
	if sequence.is_empty():
		return 0.0
	return _curse_risk(sequence, action)


## The next roll for a curse-raised failure. With no rolls given, the step never fails this way.
func _next_step_roll() -> float:
	if _step_rolls.is_empty():
		return 1.0
	var roll: float = float(_step_rolls[_step_roll_index % _step_rolls.size()])
	_step_roll_index += 1
	return roll


## Resets every step except the last, then applies the failure cost. The hint names the first
## step before the given limit that is not done, so the player knows what to do next. A text
## override replaces the sequence's failure text; stack_penalty false skips the curse stack.
func _sequence_failure(sequence: Dictionary, limit: int, text_override: String = "", stack_penalty: bool = true) -> String:
	_step_failed = true
	var hint: String = _missing_hint(sequence, limit)
	var steps: Array = _steps(sequence)
	for index: int in range(steps.size() - 1):
		_events.flags[str(steps[index]["flag"])] = false
	var failure: Dictionary = sequence.get("failure", {})
	var failure_flag: String = str(failure.get("flag", ""))
	if failure_flag != "":
		_events.flags[failure_flag] = true
	var failure_text: String = text_override if text_override != "" else str(failure.get("text", "你們退後重來。"))
	var text: String = failure_text + _spend(int(failure.get("segments", 0)))
	var target: String = str(failure.get("curse_target", ""))
	var stacks: int = int(failure.get("curse_stacks", 0)) if stack_penalty else 0
	if stacks > 0 and _curses.has(target):
		var curse: BloodCurse = _curses[target]
		for stack: int in range(stacks):
			curse.add_stack()
		text += "血之詛咒被驚動，又加深了一層。"
	if hint != "":
		text += "\n提示：" + hint
	return text


## True when the action is a read or seal action allowed at the current location.
func can_act_here(action: String) -> bool:
	return _location_allows(action)


func _location_allows(action: String) -> bool:
	return (_location_actions.get(_location, []) as Array).has(action)


## Returns the refusal text when the place cannot be entered yet, or "" when it can.
## A requirement may set "min_day" (the day must have started) and/or "flag" (must be set).
func _entry_block(place: String) -> String:
	if not _location_requirements.has(place):
		return ""
	var rule: Dictionary = _location_requirements[place]
	var blocked: String = str(rule.get("blocked_text", "此地尚無法前往。"))
	if rule.has("min_day") and clock.day < int(rule["min_day"]):
		return blocked
	if rule.has("flag") and not event_flag(str(rule["flag"])):
		return blocked
	return ""


## Value of a narrative flag. False when unset or when the chapter has no events.
func event_flag(flag: String) -> bool:
	if _events == null:
		return false
	return bool(_events.flags.get(flag, false))


func _can_run(action: String) -> bool:
	if is_over():
		return false
	if _pending != null:
		return action.begins_with("approach:") and pending_approaches().has(action.trim_prefix("approach:"))
	if action == "rest":
		return can_rest()
	if not _sequence_for(action).is_empty():
		return _sequence_ready(action)
	if action.begins_with("read:"):
		return _location_allows(action)
	if action.begins_with("help:") or action.begins_with("confess:") or action.begins_with("strike:"):
		return true
	if action.begins_with("go:"):
		return can_enter(action.trim_prefix("go:"))
	if action.begins_with("talk:"):
		return true
	return ACTION_COSTS.has(action)


func _run_events(action: String) -> String:
	var result: Dictionary = _events.evaluate({
		"action": action,
		"location": _location,
		"night_entered": _night_entered,
		"is_night": clock.segment == DayClock.SEGMENT_NIGHT,
		"day": clock.day,
	})
	for unlock: Dictionary in result["skill_unlocks"]:
		var owner: String = str(unlock["character"])
		if not _acquired.has(owner):
			_acquired[owner] = []
		if not (_acquired[owner] as Array).has(str(unlock["skill"])):
			(_acquired[owner] as Array).append(str(unlock["skill"]))
	if int(result.get("day_advances", 0)) > 0:
		clock.restore_elapsed(clock.day * DayClock.SEGMENTS_PER_DAY)
	for change: Dictionary in result["trust_changes"]:
		if _trust != null:
			_trust.change(str(change["character"]), int(change["delta"]))
	var text: String = ""
	for message: String in result["messages"]:
		text += "\n" + message
	return text


func _perform_action(action: String) -> String:
	if _pending != null:
		if action.begins_with("approach:"):
			return _resolve_approach(action.trim_prefix("approach:"))
		return "請先選擇應對方式。"
	if not _sequence_for(action).is_empty():
		return _perform_step(action)
	if action.begins_with("read:"):
		if not _location_allows(action):
			return WRONG_PLACE_TEXT
		_at_camp = false
		return "你照著刻痕行動，線條隨之動了起來。"
	if action.begins_with("go:"):
		if clock.is_expired():
			return "時限已到，無法再行動。"
		var place: String = action.trim_prefix("go:")
		var blocked: String = _entry_block(place)
		if blocked != "":
			return blocked
		_at_camp = false
		_location = place
		return "你前往%s。" % _location + _spend(ACTION_COSTS["move"])
	if action.begins_with("help:"):
		if clock.is_expired():
			return "時限已到，無法再行動。"
		_at_camp = false
		return "你停下來照顧幼樹。" + _spend(ACTION_COSTS["move"])
	if action.begins_with("strike:"):
		if _location != "黑曜石之門" or event_flag("obsidian_gate_open") or clock.is_expired():
			return "這裡沒有可以攻擊的鏡面。"
		if not _curses.has("freya"):
			return "只有芙蕾雅能攻擊這面鏡子。"
		_at_camp = false
		var enemy_id: String = str(_mirror_counter.get("enemy", ""))
		if _has_enemy(enemy_id):
			_story_fight = {"kind": "mirror", "enemy": enemy_id, "action": action}
			return "你揮劍擊向銀鏡，鏡中的芙蕾雅舉劍擋下。"
		var damage: int = int(_mirror_counter.get("damage", 0))
		var stacks: int = int(_mirror_counter.get("curse_stacks", 0))
		var spend_text: String = _spend(ACTION_COSTS["move"])
		var curse: BloodCurse = _curses["freya"]
		for index: int in range(stacks):
			curse.add_stack()
		_wounds["freya"] = int(_wounds.get("freya", 0)) + damage
		return "你揮劍擊向銀鏡，鏡中的芙蕾雅反擊。芙蕾雅受傷（-%d）。血之詛咒激化。" % damage + spend_text
	if action.begins_with("confess:"):
		_at_camp = false
		return "你直視鏡中的影像。"
	if action.begins_with("talk:"):
		if clock.is_expired():
			return "時限已到，無法再行動。"
		_at_camp = false
		return "你開口與同伴交談。"
	if not ACTION_COSTS.has(action):
		return "未知行動：%s" % action
	if clock.is_expired():
		return "時限已到，無法再行動。"

	if action == "rest":
		if not can_rest():
			return "食糧不足，無法休息。（可改用輔助難度）"
		if _supply != null and rest_food_cost > 0:
			_supply.consume("food", rest_food_cost)
		_at_camp = true
		return _action_label(action) + _spend(ACTION_COSTS[action])

	# Any action other than a rest leaves camp.
	_at_camp = false
	if action == "battle":
		return _perform_battle()
	var text: String = _action_label(action) + _spend(ACTION_COSTS[action])
	if action == "explore":
		text = _start_encounter(text)
	return text


## True when the party has enough food for a rest.
func can_rest() -> bool:
	if clock.is_expired():
		return false
	return _supply == null or _supply.count("food") >= rest_food_cost


## True when the party is at camp (last action was a successful rest) and may save.
func can_save() -> bool:
	return _at_camp and not clock.is_expired()


## Current supply counts for the HUD. Empty when supplies are unlimited.
func supply_text() -> String:
	if _supply == null:
		return ""
	return "藥草 %d｜食糧 %d" % [_supply.count("herbs"), _supply.count("food")]


## Trust values and curse stacks for the HUD. Empty when neither is tracked.
func party_text() -> String:
	var parts: Array[String] = []
	for member: Dictionary in _party:
		var id: String = str(member.get("id", ""))
		var name: String = str(member.get("name", id))
		if _trust != null and _trust.get_trust(id) >= 0:
			parts.append("%s 信任 %d" % [name, _trust.get_trust(id)])
		if _curses.has(id):
			parts.append("%s 血之詛咒 %d 層" % [name, curse_stacks(id)])
		if wounds(id) > 0:
			parts.append("%s 受傷 %d" % [name, wounds(id)])
	return "｜".join(parts)


## Blood curse stacks for a character, or -1 when that character has no curse.
func curse_stacks(character_id: String) -> int:
	if not _curses.has(character_id):
		return -1
	return (_curses[character_id] as BloodCurse).stacks


## Captures the state needed to resume the game later.
func snapshot() -> Dictionary:
	var data: Dictionary = {
		"version": SNAPSHOT_VERSION,
		"elapsed": clock.get_elapsed(),
		"battle_done": battle_done,
		"rest_food_cost": rest_food_cost,
	}
	if _supply != null:
		data["herbs"] = _supply.count("herbs")
		data["food"] = _supply.count("food")
	if _trust != null:
		var trust: Dictionary = {}
		for member: Dictionary in _party:
			var id: String = str(member.get("id", ""))
			if _trust.get_trust(id) >= 0:
				trust[id] = _trust.get_trust(id)
		data["trust"] = trust
	var stacks: Dictionary = {}
	for id: String in _curses:
		stacks[id] = (_curses[id] as BloodCurse).stacks
	data["curse_stacks"] = stacks
	data["encounter_index"] = _encounter_index
	data["location"] = _location
	data["acquired_skills"] = _acquired.duplicate(true)
	data["wounds"] = _wounds.duplicate()
	if _events != null:
		data["events"] = _events.snapshot()
	return data


## Restores a snapshot. Returns false and changes nothing when the data is invalid.
## A restored game is not at camp, so the player must rest again before saving.
func restore(data: Dictionary) -> bool:
	if _as_int(data.get("version", -1)) != SNAPSHOT_VERSION:
		return false
	if not (data.get("battle_done") is bool):
		return false
	var elapsed: int = _as_int(data.get("elapsed", -1))
	var cost: int = _as_int(data.get("rest_food_cost", -1))
	if elapsed < 0 or cost < 0:
		return false
	var herbs: int = _as_int(data.get("herbs", 0))
	var food: int = _as_int(data.get("food", 0))
	if herbs < 0 or food < 0:
		return false
	if not (data.get("trust", {}) is Dictionary) or not (data.get("curse_stacks", {}) is Dictionary):
		return false
	var encounter_index: int = _as_int(data.get("encounter_index", -1))
	if not (data.get("location", "") is String):
		return false
	if not (data.get("acquired_skills", {}) is Dictionary):
		return false
	if not (data.get("wounds", {}) is Dictionary):
		return false
	for id: String in data.get("wounds", {}):
		if _as_int(data["wounds"][id]) < 0:
			return false
	for owner: String in data.get("acquired_skills", {}):
		if not (data["acquired_skills"][owner] is Array):
			return false
	if _events != null and data.has("events") and not _events.is_snapshot_valid(data["events"]):
		return false
	if encounter_index < 0 or encounter_index > _encounters.size():
		return false

	# Validate every value before changing any state.
	var trust_values: Dictionary = {}
	for id: String in data.get("trust", {}):
		var value: int = _as_int(data["trust"][id])
		if value < 0:
			return false
		trust_values[id] = value
	var stack_values: Dictionary = {}
	for id: String in data.get("curse_stacks", {}):
		var stacks: int = _as_int(data["curse_stacks"][id])
		if stacks < 0 or stacks > BloodCurse.MAX_STACKS or not _curses.has(id):
			return false
		stack_values[id] = stacks

	# restore_elapsed() validates the range and changes nothing when it fails.
	if not clock.restore_elapsed(elapsed):
		return false
	battle_done = data["battle_done"]
	rest_food_cost = cost
	if _supply != null:
		_supply.set_counts(herbs, food)
	if _trust != null:
		for id: String in trust_values:
			_trust.set_trust(id, trust_values[id])
	for id: String in stack_values:
		var curse: BloodCurse = _curses[id]
		curse.stacks = stack_values[id]
	_encounter_index = encounter_index
	_location = str(data.get("location", ""))
	_acquired = (data.get("acquired_skills", {}) as Dictionary).duplicate(true)
	_wounds = (data.get("wounds", {}) as Dictionary).duplicate()
	if _events != null and data.has("events"):
		_events.restore(data["events"])
	_pending = null
	_at_camp = false
	return true


## Short status line shown in the HUD.
func status_text() -> String:
	if clock.is_expired():
		return "時限已到"
	return "第 %d 日｜%s" % [clock.day, SEGMENT_NAMES[clock.segment]]


func _perform_battle() -> String:
	if battle_done:
		return "教學戰鬥已結束。"

	var spend_text: String = _spend(ACTION_COSTS["battle"])
	battle_done = true
	_battle_this_action = true

	var result: Dictionary = Skirmish.resolve(
		_battle_members(), TUTORIAL_ENEMY_HP, TUTORIAL_ENEMY_DEF, _rolls, Skirmish.DEFAULT_ROUND_LIMIT,
		{"enemy_tags": _enemy_tags, "affinity": _affinity})
	if result["won"]:
		return "戰鬥勝利，共 %d 回合。" % result["rounds"] + _hit_text(result) + _reward_victory() + spend_text
	return "戰鬥失敗，敵人剩餘 %d 點生命。" % result["enemy_hp_left"] + _hit_text(result) + spend_text


## Spends time. Returns day-end text when a night finished, and the night event
## when the party enters or passes the night segment.
func _spend(cost: int) -> String:
	var day_before: int = clock.day
	var segment_before: int = clock.segment
	var boundaries: int = clock.spend(cost)

	var text: String = ""
	if boundaries > 0:
		text += "\n第 %d 日結束。" % day_before
	if boundaries > 0 and clock.is_expired():
		text += "\n時限已到。"

	var reached_night: bool = clock.segment == DayClock.SEGMENT_NIGHT and segment_before != DayClock.SEGMENT_NIGHT
	if reached_night:
		_night_entered = true
	if boundaries > 0 or reached_night:
		text += _resolve_night_event()
	return text


## Picks and resolves one night event. Returns an empty string when no pool is set.
func _resolve_night_event() -> String:
	if _night_entries.is_empty():
		return ""

	var roll: float = float(_night_rolls[_night_roll_index % _night_rolls.size()])
	_night_roll_index += 1
	var entry: Dictionary = NightEventPool.pick(_night_entries, roll)
	var text: String = "\n夜間：%s" % entry.get("text", "")

	match str(entry.get("outcome", "")):
		"battle":
			_battle_this_action = true
			var hp: int = int(entry.get("enemy_hp", DEFAULT_NIGHT_ENEMY_HP))
			var def: int = int(entry.get("enemy_def", DEFAULT_NIGHT_ENEMY_DEF))
			var tags: Array = entry.get("enemy_tags", [])
			var result: Dictionary = Skirmish.resolve(
				_battle_members(), hp, def, _rolls, Skirmish.DEFAULT_ROUND_LIMIT,
				{"enemy_tags": tags, "affinity": _affinity})
			if result["won"]:
				return text + "\n你擊退了襲擊者。" + _hit_text(result) + _reward_victory()
			var injured: bool = false
			if _supply != null:
				injured = NightEventPool.resolve_loss(entry, _supply)
			else:
				injured = bool(entry.get("on_loss", {}).get("injury", false))
			return text + _hit_text(result) + ("\n隊伍受傷，補給也有所損失。" if injured else "\n隊伍撤退，補給有所損失。")
		"resource_loss":
			if _supply != null:
				NightEventPool.resolve_loss(entry, _supply)
			return text + "\n補給被竊取。"
	return text


## Builds the members for a skirmish from the party, with attack tags, curses and
## synergy blocks applied.
func _battle_members() -> Array:
	var blocked: Array[String] = []
	if _trust != null:
		blocked = _trust.members_with_effect(_synergies, BERSERK_EFFECT)

	var members: Array = []
	for member: Dictionary in _party:
		var id: String = str(member.get("id", ""))
		members.append({
			"atk": int(member["atk"]),
			"attack_tag": str(_attack_tags.get(id, DEFAULT_ATTACK_TAG)),
			"curse": _curses.get(id, null),
			"can_block_berserk": blocked.has(id),
		})
	return members


## Gives every member trust after a won battle. Returns the log text, or an empty string.
func _reward_victory() -> String:
	if _trust == null or _trust_gain <= 0:
		return ""
	for member: Dictionary in _party:
		_trust.change(str(member.get("id", "")), _trust_gain)
	return "\n隊伍信任提升了。"


func _action_label(action: String) -> String:
	match action:
		"move":
			return "你移動到了下一個區域。"
		"explore":
			return "你探索了周圍的區域。"
		"rest":
			return "隊伍在營地休息。"
	return ""


## Converts a number that may have been parsed as float (JSON) into an int.
## Returns -1 when the value is not a whole number.
func _as_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_equal_approx(value, floorf(value)):
		return int(value)
	return -1


## Approaches the player may choose for the pending encounter. Empty when none is pending.
func pending_approaches() -> Array[String]:
	if _pending == null:
		return []
	return _pending.available(_party_skill_ids(), _approach_skills)


## Labels for the approach buttons and the log.
const APPROACH_LABELS: Dictionary = {
	"combat": "戰鬥",
	"persuade": "說服",
	"puzzle": "解謎",
	"summon": "召喚",
}


## Log text for weakness and resistance hits in a skirmish result.
func _hit_text(result: Dictionary) -> String:
	var text: String = ""
	if int(result.get("weak_hits", 0)) > 0:
		text += "\n弱點命中 %d 次。" % int(result["weak_hits"])
	if int(result.get("resist_hits", 0)) > 0:
		text += "\n抗性減傷 %d 次。" % int(result["resist_hits"])
	return text


## Starts the next encounter after an explore. Returns the text with the encounter and
## its approaches, or the text unchanged when no encounter is left.
func _start_encounter(text: String) -> String:
	if _encounter_index >= _encounters.size():
		return text
	_pending = _encounters[_encounter_index]
	_encounter_index += 1
	var labels: Array[String] = []
	for approach: String in pending_approaches():
		labels.append(APPROACH_LABELS.get(approach, approach))
	return text + "\n遭遇：%s\n可選擇：%s" % [_pending.text, "、".join(labels)]


## True when the chosen approach must be fought on the battle screen. Combat and summon always
## fight; persuade fights only when its roll fails; a puzzle never fights. Starts the fight when true.
func prepare_encounter_fight(approach: String) -> bool:
	if _pending == null or not pending_approaches().has(approach):
		return false
	var fights: bool = approach == "combat" or approach == "summon"
	if approach == "persuade":
		var roll: float = float(_encounter_rolls[0]) if not _encounter_rolls.is_empty() else 0.0
		fights = roll < _pending.persuade_threshold
	if not fights:
		return false
	_fight_approach = approach
	return true


## The approach whose fight is on the battle screen, or "".
func fight_approach() -> String:
	return _fight_approach


## The enemy of the pending encounter for the battle screen. Empty when no encounter is pending.
func encounter_enemy() -> Dictionary:
	if _pending == null:
		return {}
	return {
		"name": _pending.enemy_name,
		"hp": _pending.enemy_hp,
		"max_hp": _pending.enemy_hp,
		"def": _pending.enemy_def,
		"atk": _pending.enemy_atk,
	}


## Applies the result of an encounter fight. outcome is "won", "lost" or "fled". A retreat keeps
## the encounter open so another approach can be tried. stacks: blood-curse stacks after the fight.
func finish_encounter_fight(outcome: String, stacks: Dictionary = {}) -> String:
	if _pending == null or _fight_approach == "":
		return "沒有進行中的遭遇戰鬥。"
	for id: String in stacks:
		if _curses.has(id):
			_curses[id].stacks = clampi(int(stacks[id]), 0, BloodCurse.MAX_STACKS)
	var encounter: Encounter = _pending
	_fight_approach = ""
	_battle_this_action = true
	if outcome == "fled":
		return "你撤出了戰鬥，遭遇仍在。" + _spend(ACTION_COSTS["move"])
	_pending = null
	if outcome == "won":
		return "戰鬥勝利。" + _reward_victory()
	var injured: bool = false
	if _supply != null:
		injured = NightEventPool.resolve_loss({"on_loss": encounter.on_loss}, _supply)
	return "戰鬥失敗，隊伍退出了這場戰鬥。" + ("\n隊伍受傷。" if injured else "")


## True when a story fight is waiting on the battle screen.
func story_fight_pending() -> bool:
	return not _story_fight.is_empty()


## The enemy of the waiting story fight, or empty when none.
func story_fight_enemy() -> Dictionary:
	if _story_fight.is_empty():
		return {}
	return (_battle_enemies[str(_story_fight["enemy"])] as Dictionary).duplicate(true)


## Applies the result of a story fight. outcome is "won", "lost" or "fled". stacks: blood-curse
## stacks after the fight, written back to the flow.
func finish_story_fight(outcome: String, stacks: Dictionary = {}) -> String:
	if _story_fight.is_empty():
		return "沒有進行中的戰鬥。"
	for id: String in stacks:
		if _curses.has(id):
			_curses[id].stacks = clampi(int(stacks[id]), 0, BloodCurse.MAX_STACKS)
	var fight: Dictionary = _story_fight
	_story_fight = {}
	_battle_this_action = true
	if str(fight["kind"]) == "mirror":
		return _finish_mirror_fight(outcome)
	return _finish_sequence_fight(fight, outcome)


## A sequence's final-step fight: winning completes the step and runs its event; losing resets the
## sequence; retreating changes nothing.
func _finish_sequence_fight(fight: Dictionary, outcome: String) -> String:
	var sequence: Dictionary = fight["sequence"]
	if outcome == "fled":
		return "你撤出了戰鬥，守衛仍在。" + _spend(ACTION_COSTS["move"])
	if outcome != "won":
		return _sequence_failure(sequence, _steps(sequence).size() - 1)
	_apply_success(sequence)
	var cost_text: String = _spend(int(sequence.get("cost", 0)))
	if sequence.has("to"):
		_location = str(sequence["to"])
	return "戰鬥勝利。" + cost_text + _run_events(str(fight["action"]))


## The mirror fight: winning avoids the counterattack; losing applies it as before.
func _finish_mirror_fight(outcome: String) -> String:
	if outcome == "fled":
		return "你退開了鏡面。" + _spend(ACTION_COSTS["move"])
	var spend_text: String = _spend(ACTION_COSTS["move"])
	if outcome == "won":
		return "你擋下了鏡中的反擊。" + spend_text
	var damage: int = int(_mirror_counter.get("damage", 0))
	var stacks: int = int(_mirror_counter.get("curse_stacks", 0))
	var curse: BloodCurse = _curses["freya"]
	for index: int in range(stacks):
		curse.add_stack()
	_wounds["freya"] = int(_wounds.get("freya", 0)) + damage
	return "鏡中的芙蕾雅反擊。芙蕾雅受傷（-%d）。血之詛咒激化。" % damage + spend_text


## True when the enemy id names an enemy defined for the battle screen.
func _has_enemy(enemy_id: String) -> bool:
	return enemy_id != "" and _battle_enemies.has(enemy_id)


## Resolves the pending encounter with a chosen approach.
func _resolve_approach(approach: String) -> String:
	if not pending_approaches().has(approach):
		return "無法使用這種應對方式。"

	var encounter: Encounter = _pending
	_pending = null
	var result: Dictionary = encounter.resolve(approach, _battle_members(), _encounter_rolls, _affinity, {})
	if result.get("persuade_failed", false) or not ["solved", "persuaded"].has(str(result["outcome"])):
		_battle_this_action = true

	var text: String = ""
	if result.get("persuade_failed", false):
		text += "說服失敗，怨靈發動攻擊。"
	match str(result["outcome"]):
		"solved":
			return "你解開了封印，隊伍得以通過。"
		"persuaded":
			return "說服成功，怨靈停止了低語，隊伍得以通過。"
		"won":
			return text + "戰鬥勝利，共 %d 回合。" % int(result["rounds"]) + _hit_text(result) + _reward_victory()
		_:
			var injured: bool = false
			if _supply != null:
				injured = NightEventPool.resolve_loss({"on_loss": encounter.on_loss}, _supply)
			return text + "戰鬥失敗，敵人剩餘 %d 點生命。" % int(result["enemy_hp_left"]) + _hit_text(result) + ("\n隊伍受傷。" if injured else "")


## Skill IDs of every party member, flattened for approach checks.
func _party_skill_ids() -> Array:
	var ids: Array = []
	for member: Dictionary in _party:
		var id: String = str(member.get("id", ""))
		for skill_id: Variant in _party_skills.get(id, []):
			ids.append(skill_id)
		for skill_id: Variant in _acquired.get(id, []):
			ids.append(skill_id)
	return ids


## Skills the character gained from narrative rewards (for example a side-quest reward).
func acquired_skills(character_id: String) -> Array:
	return (_acquired.get(character_id, []) as Array).duplicate()


## Damage a character has taken from mirror counterattacks.
func wounds(character_id: String) -> int:
	return int(_wounds.get(character_id, 0))
