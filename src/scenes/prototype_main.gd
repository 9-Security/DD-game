extends Control
## Chapter one prototype: prologue dialogue, difficulty choice, then day one actions,
## supplies, night events and the tutorial skirmish. Game rules live in DayOneFlow and
## the data files; this script only builds the screen and shows what the flow returns.

const PROLOGUE_PATH: String = "res://assets/data/narrative/prologue.json"
const CHARACTER_DIR: String = "res://assets/data/characters/"
const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const NIGHT_POOL_PATH: String = "res://assets/data/events/night_pool.json"
const ENCOUNTER_PATH: String = "res://assets/data/encounters/day1.json"
const EVENTS_PATH: String = "res://assets/data/events/chapter1.json"
## Location and conversation actions offered on the day-one screen, with their labels.
const NARRATIVE_ACTIONS: Array = [
	["go:焦林", "前往焦林"],
	["help:sapling", "幫助焦林的幼樹"],
	["go:守淵村", "前往守淵村"],
	["talk:freya", "與芙蕾雅交談"],
	["talk:richter", "與里克特交談"],
	["talk:freya_food", "遞給芙蕾雅乾糧"],
	["talk:innkeeper", "詢問旅店主人"],
]
const CHARACTER_IDS: Array[String] = ["eron", "freya", "richter", "inry"]
const ROLL_SAMPLES: int = 16
## Single save slot for the prototype. The design calls for three slots later.
const SAVE_PATH: String = "user://save_slot_1.json"
const DIFFICULTY_LABELS: Dictionary = {
	"strict": "嚴格難度（休息消耗食糧）",
	"assisted": "輔助難度（休息不耗食糧）",
}

var _lines: Array = []
var _line_index: int = 0
var _flow: DayOneFlow
var _difficulty: String = "strict"
var _rules: Dictionary = {}
var _night_entries: Array = []
var _encounter_entries: Array = []

var _dialogue_label: Label
var _next_button: Button
var _load_button: Button
var _difficulty_bar: HBoxContainer
var _difficulty_label: Label
var _status_label: Label
var _supply_label: Label
var _log_label: Label
var _action_bar: HBoxContainer
var _action_buttons: Dictionary = {}
var _approach_bar: HBoxContainer
var _talk_bar: HBoxContainer
var _event_data: Array = []
var _save_button: Button


func _ready() -> void:
	_build_ui()
	_lines = _load_prologue_lines()
	_rules = _load_rules()
	_night_entries = _load_night_entries()
	_encounter_entries = _load_encounter_entries()
	_event_data = _load_event_entries()
	_difficulty = str(_rules.get("default_difficulty", "strict"))

	# Launch options for capture and review, passed after "--" on the command line:
	#   --skip-prologue              open directly on the day-one screen
	#   --difficulty=<strict|assisted>  choose the difficulty before the day starts
	#   --demo-load                  load the save slot at launch
	#   --demo-action=<action>       perform one action at launch (move, explore, rest, battle, save)
	var options: PackedStringArray = OS.get_cmdline_user_args()
	for option: String in options:
		if option.begins_with("--difficulty="):
			_set_difficulty(option.trim_prefix("--difficulty="))

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

	var title := Label.new()
	title.text = "七日之藥，深淵之願 — 序章與第一日（原型）"
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

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

	_difficulty_bar = HBoxContainer.new()
	_difficulty_bar.add_theme_constant_override("separation", 16)
	root.add_child(_difficulty_bar)
	for difficulty: String in ["strict", "assisted"]:
		var button := Button.new()
		button.text = DIFFICULTY_LABELS[difficulty]
		button.custom_minimum_size = Vector2(320, 48)
		button.pressed.connect(_set_difficulty.bind(difficulty))
		_difficulty_bar.add_child(button)

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

	_supply_label = Label.new()
	_supply_label.add_theme_font_size_override("font_size", 20)
	_supply_label.visible = false
	root.add_child(_supply_label)

	_difficulty_label = Label.new()
	_difficulty_label.add_theme_font_size_override("font_size", 18)
	_difficulty_label.visible = false
	root.add_child(_difficulty_label)

	_action_bar = HBoxContainer.new()
	_action_bar.add_theme_constant_override("separation", 16)
	_action_bar.visible = false
	root.add_child(_action_bar)
	for action: String in ["move", "explore", "rest", "battle"]:
		var button := Button.new()
		button.text = _button_text(action)
		button.custom_minimum_size = Vector2(220, 48)
		button.pressed.connect(_on_action_pressed.bind(action))
		_action_bar.add_child(button)
		_action_buttons[action] = button

	_talk_bar = HBoxContainer.new()
	_talk_bar.add_theme_constant_override("separation", 12)
	_talk_bar.visible = false
	root.add_child(_talk_bar)
	for pair: Array in NARRATIVE_ACTIONS:
		var button := Button.new()
		button.text = str(pair[1])
		button.custom_minimum_size = Vector2(150, 44)
		button.pressed.connect(_on_action_pressed.bind(str(pair[0])))
		_talk_bar.add_child(button)

	_approach_bar = HBoxContainer.new()
	_approach_bar.add_theme_constant_override("separation", 16)
	_approach_bar.visible = false
	root.add_child(_approach_bar)

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
			return "休息（2 段，耗食糧）"
		"battle":
			return "教學戰鬥（1 段）"
	return action


func _set_difficulty(difficulty: String) -> void:
	if _flow != null:
		# The difficulty is fixed once the day has started.
		return
	if not DIFFICULTY_LABELS.has(difficulty):
		return
	_difficulty = difficulty
	_difficulty_label.visible = true
	_difficulty_label.text = "已選擇：%s" % DIFFICULTY_LABELS[difficulty]


func _show_next_line() -> void:
	if _line_index < _lines.size():
		var line: Dictionary = _lines[_line_index]
		_dialogue_label.text = "%s：%s" % [line.get("speaker", ""), line.get("text", "")]
		_line_index += 1
	else:
		_enter_day_one()


func _enter_day_one() -> void:
	_ensure_flow()
	_next_button.visible = false
	_load_button.visible = false
	_difficulty_bar.visible = false
	_difficulty_label.visible = false
	_dialogue_label.text = "第一日開始。四人踏入星墜之淵外圍。"
	_status_label.visible = true
	_supply_label.visible = true
	_action_bar.visible = true
	_log_label.visible = true
	_log_label.text = ""
	_refresh_status()


## Builds the day-one flow once, using the chosen difficulty and the balance data.
func _ensure_flow() -> void:
	if _flow != null:
		return
	var party: Array = _load_party()
	var settings: Dictionary = _rules.get("difficulty", {}).get(_difficulty, {})
	var supply := SupplyPool.new(
		int(settings.get("starting_herbs", 0)),
		int(settings.get("starting_food", 0)),
	)
	var trust_rules: Dictionary = _rules.get("trust", {})
	var trust := TrustBoard.new(
		CHARACTER_IDS,
		int(trust_rules.get("start", 50)),
		int(trust_rules.get("min", 0)),
		int(trust_rules.get("max", 100)),
	)
	var enemy_tags: Array = _rules.get("enemy_tags", {}).get("tutorial_enemy", [])
	_flow = DayOneFlow.new(party, _sample_rolls(), {
		"supply": supply,
		"rest_food_cost": int(settings.get("rest_food_cost", 0)),
		"night_entries": _night_entries,
		"night_rolls": _unit_rolls(),
		"trust": trust,
		"trust_gain": int(trust_rules.get("battle_victory_gain", 0)),
		"synergies": _rules.get("synergies", []),
		"enemy_tags": enemy_tags,
		"affinity": _rules.get("affinity", {}),
		"attack_tags": _rules.get("attack_tags", {}),
		"encounters": _encounter_entries,
		"party_skills": _party_skills(party),
		"approach_skills": _rules.get("approach_skills", {}),
		"encounter_rolls": _unit_rolls(),
		"events": _event_data,
	})


func _on_action_pressed(action: String) -> void:
	_ensure_flow()
	var message: String = _flow.perform(action)
	_log_label.text = message
	_refresh_status()
	if _flow.clock.is_expired():
		_action_bar.visible = false


func _on_save_pressed() -> void:
	_ensure_flow()
	if not _flow.can_save():
		_log_label.text = "只能在營地存檔。請先休息。"
	elif SaveRepository.write(SAVE_PATH, _flow.snapshot()):
		_log_label.text = "已存檔。"
	else:
		_log_label.text = "存檔失敗，請檢查儲存空間。"
	_refresh_status()


func _on_load_pressed() -> void:
	_ensure_flow()
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
	var where: String = _flow.location()
	_status_label.text = _flow.status_text() + ("｜地點：%s" % where if where != "" else "")
	var party_line: String = _flow.party_text()
	_supply_label.text = _flow.supply_text() + ("\n" + party_line if party_line != "" else "")
	_action_buttons["rest"].disabled = not _flow.can_rest()
	var approaches: Array[String] = _flow.pending_approaches()
	_rebuild_approach_bar(approaches)
	_approach_bar.visible = not approaches.is_empty()
	_action_bar.visible = approaches.is_empty() and not _flow.clock.is_expired()
	_talk_bar.visible = approaches.is_empty() and not _flow.clock.is_expired()
	_save_button.disabled = not _flow.can_save()


## Loads the prologue lines. Returns an empty array and logs an error when missing.
func _load_prologue_lines() -> Array:
	var parsed: Variant = _load_json(PROLOGUE_PATH)
	if not (parsed is Dictionary) or not parsed.has("lines"):
		push_error("Prologue data missing or malformed: %s" % PROLOGUE_PATH)
		return []
	return parsed["lines"]


## Loads the balance rules after validating them. Returns an empty dictionary on failure.
func _load_rules() -> Dictionary:
	var parsed: Variant = _load_json(BALANCE_PATH)
	if not (parsed is Dictionary):
		push_error("Balance data missing or malformed: %s" % BALANCE_PATH)
		return {}
	var errors: Array[String] = GameRules.validate(parsed)
	if not errors.is_empty():
		push_error("Balance data invalid: %s" % ", ".join(errors))
		return {}
	return parsed


## Loads the night event entries after validating them. Returns an empty array on failure.
func _load_night_entries() -> Array:
	var parsed: Variant = _load_json(NIGHT_POOL_PATH)
	if not (parsed is Dictionary) or not parsed.has("entries"):
		push_error("Night pool data missing or malformed: %s" % NIGHT_POOL_PATH)
		return []
	var errors: Array[String] = NightEventPool.validate(parsed["entries"])
	if not errors.is_empty():
		push_error("Night pool data invalid: %s" % ", ".join(errors))
		return []
	return parsed["entries"]


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
			"id": character_id,
			"name": data["identity"]["name"],
			"atk": int(data["stats"]["atk"]),
			"curse": (_rules.get("blood_curse_bearers", []) as Array).has(character_id),
			"skills": data["skills"],
		})
	return party


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Random variance samples for combat.
func _sample_rolls() -> Array:
	var rolls: Array = []
	for index: int in range(ROLL_SAMPLES):
		rolls.append(randf_range(-DamageCalculator.ROLL_LIMIT, DamageCalculator.ROLL_LIMIT))
	return rolls


## Random samples in [0, 1) used to pick night events.
func _unit_rolls() -> Array:
	var rolls: Array = []
	for index: int in range(ROLL_SAMPLES):
		rolls.append(randf())
	return rolls


## Loads the day-one encounters, keeping only valid entries.
func _load_encounter_entries() -> Array:
	var parsed: Variant = _load_json(ENCOUNTER_PATH)
	if not (parsed is Dictionary) or not parsed.has("entries"):
		push_error("Encounter data missing or malformed: %s" % ENCOUNTER_PATH)
		return []
	var valid: Array = []
	for entry: Variant in parsed["entries"]:
		var errors: Array[String] = Encounter.validate(entry)
		if errors.is_empty():
			valid.append(entry)
		else:
			push_error("Encounter entry invalid: %s" % ", ".join(errors))
	return valid


## Skill IDs per party member, keyed by character ID.
func _party_skills(party: Array) -> Dictionary:
	var skills: Dictionary = {}
	for member: Dictionary in party:
		skills[str(member["id"])] = member["skills"]
	return skills


## Rebuilds the approach buttons for the pending encounter.
func _rebuild_approach_bar(approaches: Array[String]) -> void:
	for child: Node in _approach_bar.get_children():
		child.queue_free()
	for approach: String in approaches:
		var button := Button.new()
		button.text = DayOneFlow.APPROACH_LABELS.get(approach, approach)
		button.custom_minimum_size = Vector2(220, 48)
		button.pressed.connect(_on_action_pressed.bind("approach:" + approach))
		_approach_bar.add_child(button)


## Loads the chapter one events, keeping only valid entries.
func _load_event_entries() -> Array:
	var parsed: Variant = _load_json(EVENTS_PATH)
	if not (parsed is Dictionary) or not parsed.has("events"):
		push_error("Event data missing or malformed: %s" % EVENTS_PATH)
		return []
	var valid: Array = []
	for event: Variant in parsed["events"]:
		var errors: Array[String] = EventRunner.validate(event)
		if errors.is_empty():
			valid.append(event)
		else:
			push_error("Event invalid: %s" % ", ".join(errors))
	return valid
