class_name DayOneFlow
extends RefCounted
## Day-one action flow: connects the seven-day clock to player actions and the
## tutorial skirmish. The UI only displays the messages returned by perform().
## Saving is allowed only at camp (after a rest), and loading never rewinds time.

## Segment cost of each player action (design/GAME_DESIGN_MASTER.md section 2.1).
const ACTION_COSTS: Dictionary = {"move": 1, "explore": 1, "rest": 2, "battle": 1}
const SEGMENT_NAMES: Array[String] = ["晨", "午", "夜"]

## Placeholder values for the tutorial enemy. These are not design-document values.
const TUTORIAL_ENEMY_HP: int = 30
const TUTORIAL_ENEMY_DEF: int = 2

## Version of the snapshot format written by snapshot(). Bump on any change.
const SNAPSHOT_VERSION: int = 1

var clock: DayClock
var battle_done: bool = false

var _party: Array
var _rolls: Array
var _at_camp: bool = false


## party: Array of Dictionaries with "name" and "atk" keys.
## rolls: damage variance values cycled by the skirmish resolver.
func _init(party: Array, rolls: Array) -> void:
	clock = DayClock.new()
	_party = party
	_rolls = rolls


## Performs a player action and returns a message for the log.
func perform(action: String) -> String:
	if not ACTION_COSTS.has(action):
		return "未知行動：%s" % action
	if clock.is_expired():
		return "時限已到，無法再行動。"

	# Only a rest counts as camp; any other action leaves camp.
	_at_camp = action == "rest"

	if action == "battle":
		return _perform_battle()
	return _action_label(action) + _spend(ACTION_COSTS[action])


## True when the party is at camp (last action was a rest) and may save.
func can_save() -> bool:
	return _at_camp and not clock.is_expired()


## Captures the state needed to resume the game later.
func snapshot() -> Dictionary:
	return {
		"version": SNAPSHOT_VERSION,
		"elapsed": clock.get_elapsed(),
		"battle_done": battle_done,
	}


## Restores a snapshot. Returns false and changes nothing when the data is invalid.
## A restored game is not at camp, so the player must rest again before saving.
func restore(data: Dictionary) -> bool:
	if _as_int(data.get("version", -1)) != SNAPSHOT_VERSION:
		return false
	if not (data.get("battle_done") is bool):
		return false
	var elapsed: int = _as_int(data.get("elapsed", -1))
	if elapsed < 0:
		return false

	# restore_elapsed() validates the range and changes nothing when it fails.
	if not clock.restore_elapsed(elapsed):
		return false
	battle_done = data["battle_done"]
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


## Spends time and returns the day-end text when a night segment finished.
func _spend(cost: int) -> String:
	var day_before: int = clock.day
	var boundaries: int = clock.spend(cost)

	var text: String = ""
	if boundaries > 0:
		text += "\n第 %d 日結束。" % day_before
	if boundaries > 0 and clock.is_expired():
		text += "\n時限已到。"
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
