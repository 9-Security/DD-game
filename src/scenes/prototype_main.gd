extends Control
## Chapter one prototype: prologue dialogue, then day one actions and the
## tutorial skirmish. Game rules live in DayOneFlow; this script only shows them.

const PROLOGUE_PATH: String = "res://assets/data/narrative/prologue.json"
const CHARACTER_DIR: String = "res://assets/data/characters/"
const CHARACTER_IDS: Array[String] = ["eron", "freya", "richter", "inry"]
const ROLL_SAMPLES: int = 16

var _lines: Array = []
var _line_index: int = 0
var _flow: DayOneFlow

var _title_label: Label
var _dialogue_label: Label
var _next_button: Button
var _status_label: Label
var _log_label: Label
var _action_bar: HBoxContainer


func _ready() -> void:
	_build_ui()
	_lines = _load_prologue_lines()
	var party: Array = _load_party()
	_flow = DayOneFlow.new(party, _sample_rolls())
	_show_next_line()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 48
	root.offset_top = 32
	root.offset_right = -48
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	_title_label = Label.new()
	_title_label.text = "七日之藥，深淵之願 — 序章與第一日（原型）"
	_title_label.add_theme_font_size_override("font_size", 28)
	root.add_child(_title_label)

	_dialogue_label = Label.new()
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 24)
	_dialogue_label.custom_minimum_size = Vector2(0, 160)
	root.add_child(_dialogue_label)

	_next_button = Button.new()
	_next_button.text = "下一句"
	_next_button.custom_minimum_size = Vector2(200, 48)
	_next_button.pressed.connect(_show_next_line)
	root.add_child(_next_button)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.visible = false
	root.add_child(_status_label)

	_action_bar = HBoxContainer.new()
	_action_bar.add_theme_constant_override("separation", 16)
	_action_bar.visible = false
	root.add_child(_action_bar)
	for action: String in ["move", "explore", "rest", "battle"]:
		var button := Button.new()
		button.text = _button_text(action)
		button.custom_minimum_size = Vector2(160, 48)
		button.pressed.connect(_on_action_pressed.bind(action))
		_action_bar.add_child(button)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 20)
	_log_label.visible = false
	root.add_child(_log_label)


func _button_text(action: String) -> String:
	match action:
		"move":
			return "移動（1 段）"
		"explore":
			return "探索（1 段）"
		"rest":
			return "休息（2 段）"
		"battle":
			return "教學戰鬥（1 段）"
	return action


func _show_next_line() -> void:
	if _line_index < _lines.size():
		var line: Dictionary = _lines[_line_index]
		_dialogue_label.text = "%s：%s" % [line.get("speaker", ""), line.get("text", "")]
		_line_index += 1
	else:
		_enter_day_one()


func _enter_day_one() -> void:
	_next_button.visible = false
	_dialogue_label.text = "第一日開始。四人踏入星墜之淵外圍。"
	_status_label.visible = true
	_action_bar.visible = true
	_log_label.visible = true
	_log_label.text = ""
	_refresh_status()


func _on_action_pressed(action: String) -> void:
	var message: String = _flow.perform(action)
	_log_label.text = message
	_refresh_status()
	if _flow.clock.is_expired():
		_action_bar.visible = false


func _refresh_status() -> void:
	_status_label.text = _flow.status_text()


## Loads the prologue lines. Returns an empty array and logs an error when missing.
func _load_prologue_lines() -> Array:
	var parsed: Variant = _load_json(PROLOGUE_PATH)
	if not (parsed is Dictionary) or not parsed.has("lines"):
		push_error("Prologue data missing or malformed: %s" % PROLOGUE_PATH)
		return []
	return parsed["lines"]


## Loads and validates party members. Invalid files are skipped and logged.
func _load_party() -> Array:
	var party: Array = []
	for character_id: String in CHARACTER_IDS:
		var path: String = CHARACTER_DIR + character_id + ".json"
		var data: Variant = _load_json(path)
		if not (data is Dictionary):
			push_error("Character data missing or malformed: %s" % path)
			continue
		var errors: Array[String] = CharacterData.validate(data)
		if not errors.is_empty():
			push_error("Character data invalid (%s): %s" % [path, ", ".join(errors)])
			continue
		party.append({
			"name": data["identity"]["name"],
			"atk": int(data["stats"]["atk"]),
		})
	return party


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Random variance samples for the tutorial battle.
func _sample_rolls() -> Array:
	var rolls: Array = []
	for index: int in range(ROLL_SAMPLES):
		rolls.append(randf_range(-DamageCalculator.ROLL_LIMIT, DamageCalculator.ROLL_LIMIT))
	return rolls
