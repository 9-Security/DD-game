extends Control
## Chapter one prototype: prologue dialogue, then day one actions and the
## tutorial skirmish. Game rules live in DayOneFlow; this script only shows them.

const PROLOGUE_PATH: String = "res://assets/data/narrative/prologue.json"
const CHARACTER_DIR: String = "res://assets/data/characters/"
const CHARACTER_IDS: Array[String] = ["eron", "freya", "richter", "inry"]
const ROLL_SAMPLES: int = 16
## Single save slot for the prototype. The design calls for three slots later.
const SAVE_PATH: String = "user://save_slot_1.json"

var _lines: Array = []
var _line_index: int = 0
var _flow: DayOneFlow

var _title_label: Label
var _dialogue_label: Label
var _next_button: Button
var _load_button: Button
var _status_label: Label
var _log_label: Label
var _action_bar: HBoxContainer
var _save_button: Button


func _ready() -> void:
	_build_ui()
	_lines = _load_prologue_lines()
	var party: Array = _load_party()
	_flow = DayOneFlow.new(party, _sample_rolls())

	# Launch options for capture and review, passed after "--" on the command line:
	#   --skip-prologue            open directly on the day-one screen
	#   --demo-load                load the save slot at launch
	#   --demo-action=<action>     perform one action at launch (move, explore, rest, battle, save)
	var options: PackedStringArray = OS.get_cmdline_user_args()
	if options.has("--skip-prologue"):
		_enter_day_one()
	else:
		_show_next_line()
	if options.has("--demo-load"):
		_on_load_pressed()
	for option: String in options:
		if option.begins_with("--demo-action="):
			var action: String = option.trim_prefix("--demo-action=")
			if action == "save":
				_on_save_pressed()
			else:
				_on_action_pressed(action)


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

	_load_button = Button.new()
	_load_button.text = "讀取存檔"
	_load_button.custom_minimum_size = Vector2(200, 48)
	_load_button.pressed.connect(_on_load_pressed)
	_load_button.visible = SaveRepository.read(SAVE_PATH) != null
	root.add_child(_load_button)

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

	_save_button = Button.new()
	_save_button.text = "存檔（需在營地）"
	_save_button.custom_minimum_size = Vector2(200, 48)
	_save_button.disabled = true
	_save_button.pressed.connect(_on_save_pressed)
	_action_bar.add_child(_save_button)

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
	_load_button.visible = false
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


func _on_save_pressed() -> void:
	if not _flow.can_save():
		_log_label.text = "只能在營地存檔。請先休息。"
	elif SaveRepository.write(SAVE_PATH, _flow.snapshot()):
		_log_label.text = "已存檔。"
	else:
		_log_label.text = "存檔失敗，請檢查儲存空間。"
	_refresh_status()


func _on_load_pressed() -> void:
	var data: Variant = SaveRepository.read(SAVE_PATH)
	if data == null:
		_log_label.text = "沒有可讀取的存檔。"
		_log_label.visible = true
		_load_button.visible = false
		return
	if not _flow.restore(data):
		_log_label.text = "存檔內容無效，無法讀取。"
		_log_label.visible = true
		return
	_enter_day_one()
	_log_label.text = "已讀取存檔。"


func _refresh_status() -> void:
	_status_label.text = _flow.status_text()
	_save_button.disabled = not _flow.can_save()


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
