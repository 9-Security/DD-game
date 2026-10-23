class_name BattlePanel
extends PanelContainer
## Interactive turn-based battle screen. The player picks a command for the member whose turn it
## is; TurnBattle resolves it. When the battle ends, finished(outcome) is emitted once with
## "won", "lost" or "fled".

signal finished(outcome: String)

const COMMANDS: Array[Array] = [
	["attack", "攻擊"],
	["defend", "防禦"],
	["retreat", "撤退"],
	["skill", "技能"],
]
const LOG_LIMIT: int = 8

var _battle: TurnBattle
var _skills: Dictionary = {}
var _party: Array = []
var _done: bool = false
var _choosing_target: bool = false
var _log_lines: Array[String] = []

var _status_label: Label
var _members_label: Label
var _log_label: Label
var _command_bar: HBoxContainer
var _target_bar: HBoxContainer
var _prompt_label: Label


func _init() -> void:
	# An opaque background, so the exploration screen behind the battle does not show through.
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.07, 0.07, 0.09, 1.0)
	add_theme_stylebox_override("panel", background)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 24)
	box.add_child(_status_label)

	_members_label = Label.new()
	_members_label.add_theme_font_size_override("font_size", 20)
	box.add_child(_members_label)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 20)
	_log_label.custom_minimum_size = Vector2(0, 200)
	box.add_child(_log_label)

	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 20)
	box.add_child(_prompt_label)

	_command_bar = HBoxContainer.new()
	_command_bar.add_theme_constant_override("separation", 16)
	box.add_child(_command_bar)
	for command: Array in COMMANDS:
		var button := Button.new()
		button.text = str(command[1])
		button.custom_minimum_size = Vector2(160, 48)
		button.pressed.connect(_on_command_pressed.bind(str(command[0])))
		_command_bar.add_child(button)

	_target_bar = HBoxContainer.new()
	_target_bar.add_theme_constant_override("separation", 16)
	_target_bar.visible = false
	box.add_child(_target_bar)


## Starts a battle. party: battle members (see BattleSetup). enemy: enemy dictionary.
## rolls: variance values in [-0.10, 0.10]. skills: skill definitions keyed by id.
func start(party: Array, enemy: Dictionary, rolls: Array, skills: Dictionary, round_limit: int) -> void:
	_party = party
	_skills = skills
	_battle = TurnBattle.new(party, enemy, rolls, round_limit, skills)
	_done = false
	_choosing_target = false
	_log_lines.clear()
	_add_log("戰鬥開始。")
	_refresh()


func _refresh() -> void:
	_status_label.text = "第 %d 回合｜敵人生命 %d" % [_battle.rounds, _battle.enemy_hp()]
	var lines: Array[String] = []
	for member: Dictionary in _party:
		var member_id: String = str(member["id"])
		lines.append("%s  生命 %d/%d  魔力 %d" % [
			member["name"], _battle.member_hp(member_id), int(member["max_hp"]), _battle.member_mp(member_id)])
	_members_label.text = "\n".join(lines)
	_log_label.text = "\n".join(_log_lines)

	var order: Array[String] = _battle.turn_order()
	var outcome: String = _battle.outcome()
	var acting: bool = outcome == "" and not order.is_empty()
	_command_bar.visible = acting and not _choosing_target
	_target_bar.visible = acting and _choosing_target
	_prompt_label.text = ""
	if acting:
		_prompt_label.text = "輪到：%s" % _name_of(order[0])
		if _choosing_target:
			_prompt_label.text = "選擇要為誰施放技能："
	if outcome != "":
		_finish(outcome)


func _name_of(member_id: String) -> String:
	for member: Dictionary in _party:
		if str(member["id"]) == member_id:
			return str(member["name"])
	return member_id


func _actor() -> String:
	var order: Array[String] = _battle.turn_order()
	return order[0] if not order.is_empty() else ""


func _add_log(text: String) -> void:
	_log_lines.append(text)
	while _log_lines.size() > LOG_LIMIT:
		_log_lines.pop_front()


func _on_command_pressed(command: String) -> void:
	if command == "skill" and _skill_needs_target():
		_show_targets()
		return
	_act(command, "")


func _skill_needs_target() -> bool:
	var skill: Dictionary = _skills.get(_skill_of(_actor()), {})
	return str(skill.get("kind", "")) == "heal"


func _skill_of(member_id: String) -> String:
	for member: Dictionary in _party:
		if str(member["id"]) == member_id:
			return str(member["skill"])
	return ""


func _show_targets() -> void:
	_choosing_target = true
	for child: Node in _target_bar.get_children():
		child.queue_free()
	for member: Dictionary in _party:
		var member_id: String = str(member["id"])
		if _battle.member_hp(member_id) <= 0:
			continue
		var button := Button.new()
		button.text = str(member["name"])
		button.custom_minimum_size = Vector2(200, 48)
		button.pressed.connect(_on_target_pressed.bind(member_id))
		_target_bar.add_child(button)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(120, 48)
	cancel.pressed.connect(_on_cancel_target_pressed)
	_target_bar.add_child(cancel)
	_refresh()


func _on_target_pressed(target_id: String) -> void:
	_choosing_target = false
	_act("skill", target_id)


func _on_cancel_target_pressed() -> void:
	_choosing_target = false
	_refresh()


func _act(command: String, target_id: String) -> void:
	var result: Dictionary = _battle.act(_actor(), command, target_id)
	_add_log(str(result["message"]))
	_refresh()


func _finish(outcome: String) -> void:
	if _done:
		return
	_done = true
	finished.emit(outcome)
