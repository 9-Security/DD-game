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
const TUTORIAL_ENEMY_HP: int = 30
const TUTORIAL_ENEMY_DEF: int = 2

## Fallback stats for a night battle entry that does not define its own enemy.
const DEFAULT_NIGHT_ENEMY_HP: int = 20
const DEFAULT_NIGHT_ENEMY_DEF: int = 1

const DEFAULT_ATTACK_TAG: String = "physical"
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
var _party_skills: Dictionary = {}
var _approach_skills: Dictionary = {}
var _encounter_rolls: Array = [0.0]
var _location: String = ""
var _events: EventRunner = null
var _night_entered: bool = false
var _acquired: Dictionary = {}
var _wounds: Dictionary = {}
var _mirror_counter: Dictionary = {}


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
	if options.has("events"):
		_events = EventRunner.new(options["events"], options.get("event_flags", {}))

	for member: Dictionary in party:
		if bool(member.get("curse", false)):
			_curses[str(member.get("id", ""))] = BloodCurse.new()


## Performs a player action and returns a message for the log.
## Performs a player action and returns a message for the log. Narrative events run
## only after an action that actually happened.
func perform(action: String) -> String:
	var ran: bool = _can_run(action)
	_night_entered = false
	var text: String = _perform_action(action)
	if ran and _events != null:
		text += _run_events(action)
	return text


## Current location, empty before the first move.
func location() -> String:
	return _location


## Value of a narrative flag. False when unset or when the chapter has no events.
func event_flag(flag: String) -> bool:
	if _events == null:
		return false
	return bool(_events.flags.get(flag, false))


func _can_run(action: String) -> bool:
	if clock.is_expired():
		return false
	if _pending != null:
		return action.begins_with("approach:") and pending_approaches().has(action.trim_prefix("approach:"))
	if action == "rest":
		return can_rest()
	if action.begins_with("help:") or action.begins_with("confess:") or action.begins_with("strike:"):
		return true
	if action.begins_with("go:") or action.begins_with("talk:"):
		return true
	return ACTION_COSTS.has(action)


func _run_events(action: String) -> String:
	var result: Dictionary = _events.evaluate({
		"action": action,
		"location": _location,
		"night_entered": _night_entered,
		"is_night": clock.segment == DayClock.SEGMENT_NIGHT,
	})
	for unlock: Dictionary in result["skill_unlocks"]:
		var owner: String = str(unlock["character"])
		if not _acquired.has(owner):
			_acquired[owner] = []
		if not (_acquired[owner] as Array).has(str(unlock["skill"])):
			(_acquired[owner] as Array).append(str(unlock["skill"]))
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
	if action.begins_with("go:"):
		if clock.is_expired():
			return "時限已到，無法再行動。"
		_at_camp = false
		_location = action.trim_prefix("go:")
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


## Resolves the pending encounter with a chosen approach.
func _resolve_approach(approach: String) -> String:
	if not pending_approaches().has(approach):
		return "無法使用這種應對方式。"

	var encounter: Encounter = _pending
	_pending = null
	var result: Dictionary = encounter.resolve(approach, _battle_members(), _encounter_rolls, _affinity, {})

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
