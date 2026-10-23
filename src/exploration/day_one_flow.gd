class_name DayOneFlow
extends RefCounted
## Day-one action flow: connects the seven-day clock to player actions and the
## tutorial skirmish. The UI only displays the messages returned by perform().

## Segment cost of each player action (design/GAME_DESIGN_MASTER.md section 2.1).
const ACTION_COSTS: Dictionary = {"move": 1, "explore": 1, "rest": 2, "battle": 1}
const SEGMENT_NAMES: Array[String] = ["晨", "午", "夜"]

## Placeholder values for the tutorial enemy. These are not design-document values.
const TUTORIAL_ENEMY_HP: int = 30
const TUTORIAL_ENEMY_DEF: int = 2

var clock: DayClock
var battle_done: bool = false

var _party: Array
var _rolls: Array


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
	if action == "battle":
		return _perform_battle()
	return _action_label(action) + _spend(ACTION_COSTS[action])


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
