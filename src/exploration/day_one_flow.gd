class_name DayOneFlow
extends RefCounted
## Day-one action flow: connects the seven-day clock to player actions, supply use,
## night events and the tutorial skirmish. The UI only displays returned messages.
## Saving is allowed only at camp (after a successful rest), and loading never rewinds time.

## Segment cost of each player action (design/GAME_DESIGN_MASTER.md section 2.1).
const ACTION_COSTS: Dictionary = {"move": 1, "explore": 1, "rest": 2, "battle": 1}
const SEGMENT_NAMES: Array[String] = ["晨", "午", "夜"]

## Placeholder values for the tutorial enemy. These are not design-document values.
const TUTORIAL_ENEMY_HP: int = 30
const TUTORIAL_ENEMY_DEF: int = 2

## Fallback stats for a night battle entry that does not define its own enemy.
const DEFAULT_NIGHT_ENEMY_HP: int = 20
const DEFAULT_NIGHT_ENEMY_DEF: int = 1

## Version of the snapshot format written by snapshot(). Bump on any change.
const SNAPSHOT_VERSION: int = 2

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


## party: Array of Dictionaries with "name" and "atk" keys.
## rolls: damage variance values cycled by the skirmish resolver.
## options (all optional):
##   "supply": SupplyPool. Without it, supplies are unlimited.
##   "rest_food_cost": food each rest consumes (strict 1, assisted 0).
##   "night_entries": Array of night pool entries.
##   "night_rolls": rolls in [0, 1) used to pick night entries, cycled.
func _init(party: Array, rolls: Array, options: Dictionary = {}) -> void:
	clock = DayClock.new()
	_party = party
	_rolls = rolls
	_supply = options.get("supply", null)
	rest_food_cost = int(options.get("rest_food_cost", 0))
	_night_entries = options.get("night_entries", [])
	_night_rolls = options.get("night_rolls", [0.0])


## Performs a player action and returns a message for the log.
func perform(action: String) -> String:
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
	return _action_label(action) + _spend(ACTION_COSTS[action])


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

	# restore_elapsed() validates the range and changes nothing when it fails.
	if not clock.restore_elapsed(elapsed):
		return false
	battle_done = data["battle_done"]
	rest_food_cost = cost
	if _supply != null:
		_supply.set_counts(herbs, food)
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

	var result: Dictionary = Skirmish.resolve(_party, TUTORIAL_ENEMY_HP, TUTORIAL_ENEMY_DEF, _rolls)
	if result["won"]:
		return "戰鬥勝利，共 %d 回合。" % result["rounds"] + spend_text
	return "戰鬥失敗，敵人剩餘 %d 點生命。" % result["enemy_hp_left"] + spend_text


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
			var result: Dictionary = Skirmish.resolve(_party, hp, def, _rolls)
			if result["won"]:
				return text + "\n你擊退了襲擊者。"
			var injured: bool = false
			if _supply != null:
				injured = NightEventPool.resolve_loss(entry, _supply)
			else:
				injured = bool(entry.get("on_loss", {}).get("injury", false))
			return text + ("\n隊伍受傷，補給也有所損失。" if injured else "\n隊伍撤退，補給有所損失。")
		"resource_loss":
			if _supply != null:
				NightEventPool.resolve_loss(entry, _supply)
			return text + "\n補給被竊取。"
	return text


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
