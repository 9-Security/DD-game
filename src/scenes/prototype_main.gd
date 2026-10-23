extends Control
## Chapter one prototype: prologue dialogue, difficulty choice, then day one actions,
## supplies, night events and the tutorial skirmish. Game rules live in DayOneFlow and
## the data files; this script only builds the screen and shows what the flow returns.

const PROLOGUE_PATH: String = "res://assets/data/narrative/prologue.json"
const CAPTIONS_PATH: String = "res://assets/data/narrative/captions.json"
const LABELS_PATH: String = "res://assets/data/narrative/ui_labels.json"
const CHARACTER_DIR: String = "res://assets/data/characters/"
const DIALOGUE_PATHS: Array[String] = [
	"res://assets/data/dialogue/chapter2_dialogue.json",
	"res://assets/data/dialogue/chapter3_dialogue.json",
]
const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const NIGHT_POOL_PATH: String = "res://assets/data/events/night_pool.json"
const ENCOUNTER_PATH: String = "res://assets/data/encounters/day1.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter1.json",
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
	"res://assets/data/events/chapter6.json",
	"res://assets/data/events/chapter7.json",
]
## Location and conversation actions offered on the day-one screen, with their labels.
## Confessions offered at the Obsidian Gate, one per party member.
const CHARACTER_IDS: Array[String] = ["eron", "freya", "richter", "inry"]
const ROLL_SAMPLES: int = 16
const BATTLE_SKILLS_PATH: String = "res://assets/data/battle/skills.json"
const BATTLE_ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const CHARACTER_FILE_PATH: String = "res://assets/data/characters/%s.json"
## Single save slot for the prototype. The design calls for three slots later.
## Darkens the full-screen illustration so the text stays readable.
const BACKDROP_SHADE_ALPHA: float = 0.5
const BGM_CONFIG_PATH: String = "res://assets/data/audio/bgm.json"
const ENDING_ART_PATHS: Dictionary = {
	"END_A": "res://assets/art/chapters/ending_a.jpg",
	"END_B": "res://assets/art/chapters/ending_b.jpg",
	"END_C": "res://assets/art/chapters/ending_c.jpg",
}
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
var _dialogue_button: Button
## Scripted dialogue scenes that play after a player action.
var _dialogue: DialoguePlayer = DialoguePlayer.new()
## A story fight waiting for its lead-in dialogue to finish: {enemy, note}. Empty when none waits.
var _pending_battle: Dictionary = {}
var _captions: Dictionary = {}
var _labels: Dictionary = {}
var _ending_panel: VBoxContainer
var _ending_load_button: Button
var _ending_label: Label
var _ending_art: TextureRect
## Full-screen transition illustration shown briefly at a story moment, and its fade tween.
var _transition: TextureRect
## Portrait of the prologue speaker, shown on the right while that speaker talks.
var _portrait: TextureRect
var _transition_tween: Tween
## Last story day seen, so a new day starts a transition; and whether the ending transition has played.
var _last_day: int = 0
var _ending_transition_played: bool = false
var _backdrop: TextureRect
var _bgm: BgmPlayer
var _next_button: Button
var _load_button: Button
var _difficulty_bar: HBoxContainer
var _difficulty_label: Label
var _status_label: Label
var _supply_label: Label
var _log_label: Label
var _log_scroll: ScrollContainer
var _action_bar: HBoxContainer
var _action_buttons: Dictionary = {}
var _approach_bar: HBoxContainer
var _chapter3_bar: GridContainer
## Confirmation shown before an unsafe or curse-risk chapter action runs; "" when none is waiting.
var _confirm_bar: HBoxContainer
var _confirm_label: Label
var _confirm_action: String = ""
var _chapter3_buttons: Array[Button] = []
var _talk_bar: GridContainer
var _gate_bar: GridContainer
var _passage_button: Button
var _event_data: Array = []
var _save_button: Button
var _battle_panel: BattlePanel
## Which flow the battle on screen belongs to: "tutorial" or "encounter".
var _battle_source: String = ""
var _slot: int = 1
var _slot_bar: HBoxContainer
var _slot_buttons: Array[Button] = []


func _ready() -> void:
	_labels = _read_dictionary(LABELS_PATH)
	_build_ui()
	_portrait = TextureRect.new()
	_portrait.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_portrait.offset_left = -400
	_portrait.offset_top = -580
	_portrait.offset_right = -40
	_portrait.offset_bottom = -20
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = false
	add_child(_portrait)
	# The transition overlay is added last, so it sits above the whole screen and ignores the mouse.
	_transition = TextureRect.new()
	_transition.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_transition.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition.modulate.a = 0.0
	_transition.visible = false
	add_child(_transition)
	_lines = _load_prologue_lines()
	_captions = _read_dictionary(CAPTIONS_PATH)
	_rules = _load_rules()
	_night_entries = _load_night_entries()
	_encounter_entries = _load_encounter_entries()
	_event_data = _load_event_entries()
	_load_dialogue()
	_difficulty = str(_rules.get("default_difficulty", "strict"))

	# Launch options for capture and review, passed after "--" on the command line:
	#   --skip-prologue              open directly on the day-one screen
	#   --difficulty=<strict|assisted>  choose the difficulty before the day starts
	#   --demo-load                  load the save slot at launch
	#   --demo-action=<action>       perform one action at launch (move, explore, rest, battle, save)
	var options: PackedStringArray = _launch_options()
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


## Desktop reads the command line; the web build reads the page URL (see LaunchOptions).
func _launch_options() -> PackedStringArray:
	if OS.has_feature("web"):
		return LaunchOptions.from_query(str(JavaScriptBridge.eval("window.location.search", true)))
	return OS.get_cmdline_user_args()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Backdrop and shade come first so they sit behind the text and buttons.
	_backdrop = TextureRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_bgm = BgmPlayer.new()
	add_child(_bgm)
	var bgm_config: Dictionary = _read_dictionary(BGM_CONFIG_PATH)
	_bgm.setup(bgm_config.get("tracks", {}), float(bgm_config.get("volume_db", -8.0)))
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, BACKDROP_SHADE_ALPHA)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 48
	root.offset_top = 32
	root.offset_right = -48
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := Label.new()
	title.text = str(_labels.get("title", ""))
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	_dialogue_label = Label.new()
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 24)
	_dialogue_label.custom_minimum_size = Vector2(0, 160)
	root.add_child(_dialogue_label)

	_dialogue_button = Button.new()
	_dialogue_button.text = "繼續"
	_dialogue_button.custom_minimum_size = Vector2(200, 48)
	_dialogue_button.visible = false
	_dialogue_button.pressed.connect(_on_dialogue_next_pressed)
	root.add_child(_dialogue_button)

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
	_load_button.visible = SaveRepository.read(_save_path()) != null
	root.add_child(_load_button)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.visible = false
	root.add_child(_status_label)

	_supply_label = Label.new()
	_supply_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

	_talk_bar = GridContainer.new()
	_talk_bar.columns = 4
	_talk_bar.add_theme_constant_override("h_separation", 12)
	_talk_bar.add_theme_constant_override("v_separation", 10)
	_talk_bar.visible = false
	root.add_child(_talk_bar)
	for pair: Array in _labels.get("narrative_actions", []):
		var button := Button.new()
		button.text = str(pair[1])
		button.custom_minimum_size = Vector2(150, 44)
		button.pressed.connect(_on_action_pressed.bind(str(pair[0])))
		_talk_bar.add_child(button)

	_gate_bar = GridContainer.new()
	_gate_bar.columns = 3
	_gate_bar.add_theme_constant_override("h_separation", 12)
	_gate_bar.add_theme_constant_override("v_separation", 10)
	_gate_bar.visible = false
	root.add_child(_gate_bar)
	for pair: Array in _labels.get("gate_actions", []):
		var button := Button.new()
		button.text = str(pair[1])
		button.custom_minimum_size = Vector2(220, 44)
		button.pressed.connect(_on_action_pressed.bind(str(pair[0])))
		_gate_bar.add_child(button)
	var passage: Array = _labels.get("passage_action", ["", ""])
	_passage_button = Button.new()
	_passage_button.text = str(passage[1])
	_passage_button.custom_minimum_size = Vector2(220, 44)
	_passage_button.visible = false
	_passage_button.pressed.connect(_on_action_pressed.bind(str(passage[0])))
	_gate_bar.add_child(_passage_button)

	_chapter3_bar = GridContainer.new()
	_chapter3_bar.columns = 4
	_chapter3_bar.add_theme_constant_override("h_separation", 12)
	_chapter3_bar.add_theme_constant_override("v_separation", 10)
	_chapter3_bar.visible = false
	root.add_child(_chapter3_bar)
	for entry: Array in _labels.get("story_actions", []):
		var button := Button.new()
		button.text = str(entry[1])
		button.custom_minimum_size = Vector2(280, 44)
		button.set_meta("action", str(entry[0]))
		button.set_meta("place", str(entry[2]))
		button.set_meta("label", str(entry[1]))
		button.pressed.connect(_on_chapter_pressed.bind(str(entry[0])))
		_chapter3_bar.add_child(button)
		_chapter3_buttons.append(button)

	_confirm_bar = HBoxContainer.new()
	_confirm_bar.add_theme_constant_override("separation", 16)
	_confirm_bar.visible = false
	root.add_child(_confirm_bar)
	_confirm_label = Label.new()
	_confirm_label.add_theme_font_size_override("font_size", 20)
	_confirm_bar.add_child(_confirm_label)
	var confirm_button := Button.new()
	confirm_button.text = "確定"
	confirm_button.custom_minimum_size = Vector2(140, 44)
	confirm_button.pressed.connect(_on_confirm_pressed)
	_confirm_bar.add_child(confirm_button)
	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(140, 44)
	cancel_button.pressed.connect(_on_cancel_pressed)
	_confirm_bar.add_child(cancel_button)

	_ending_panel = VBoxContainer.new()
	_ending_panel.add_theme_constant_override("separation", 12)
	_ending_panel.visible = false
	root.add_child(_ending_panel)
	_ending_art = TextureRect.new()
	_ending_art.custom_minimum_size = Vector2(0, 160)
	_ending_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ending_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ending_panel.add_child(_ending_art)
	_ending_label = Label.new()
	_ending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_label.add_theme_font_size_override("font_size", 20)
	_ending_panel.add_child(_ending_label)
	var buttons: Dictionary = _labels.get("time_up_buttons", {})
	_ending_load_button = Button.new()
	_ending_load_button.text = str(buttons.get("load", ""))
	_ending_load_button.custom_minimum_size = Vector2(220, 48)
	_ending_load_button.pressed.connect(_on_load_pressed)
	_ending_load_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	_ending_panel.add_child(_ending_load_button)
	var restart_button := Button.new()
	restart_button.text = str(buttons.get("restart", ""))
	restart_button.custom_minimum_size = Vector2(220, 48)
	restart_button.pressed.connect(_on_restart_pressed)
	_ending_panel.add_child(restart_button)

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

	# The save slots sit on their own row so the action row never overflows the screen width.
	_slot_bar = HBoxContainer.new()
	_slot_bar.add_theme_constant_override("separation", 16)
	_slot_bar.visible = false
	root.add_child(_slot_bar)
	for slot: int in range(1, SaveRepository.SLOT_COUNT + 1):
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(200, 48)
		slot_button.set_meta("slot", slot)
		slot_button.pressed.connect(_on_slot_pressed.bind(slot))
		_slot_bar.add_child(slot_button)
		_slot_buttons.append(slot_button)

	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size = Vector2(0, 160)
	_log_scroll.visible = false
	root.add_child(_log_scroll)
	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 20)
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_label)


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
		_set_portrait(PortraitRules.path_for_speaker(str(line.get("speaker", ""))))
		_line_index += 1
	else:
		_set_portrait("")
		_enter_day_one()
		_play_transition(TransitionRules.KIND_PARTY)
	_refresh_backdrop()


## Sets the full-screen illustration for the prologue, the current day, or the ending reached.
func _refresh_backdrop() -> void:
	var in_prologue: bool = _flow == null
	var day: int = _flow.clock.day if _flow != null else 1
	var ending_id: String = _flow.ending_id() if _flow != null else ""
	var ending_path: String = str(ENDING_ART_PATHS.get(ending_id, ""))
	var path: String = BackdropRules.path_for(in_prologue, day, ending_path)
	_backdrop.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	# The music follows the same state as the backdrop.
	var place: String = _flow.location() if _flow != null else ""
	var mood: String = _flow.mood() if _flow != null else ""
	_bgm.play_key(BgmRules.key_for(in_prologue, ending_id, place, mood))


func _enter_day_one() -> void:
	_ensure_flow()
	_next_button.visible = false
	_load_button.visible = false
	_difficulty_bar.visible = false
	_difficulty_label.visible = false
	_dialogue_label.text = _caption()
	_dialogue_label.custom_minimum_size = Vector2(0, 40)
	_status_label.visible = true
	_supply_label.visible = true
	_action_bar.visible = true
	_log_scroll.visible = true
	_set_log("")
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
		"battle_enemies": _read_dictionary(BATTLE_ENEMIES_PATH),
		"party_skills": _party_skills(party),
		"approach_skills": _rules.get("approach_skills", {}),
		"encounter_rolls": _unit_rolls(),
		"step_rolls": _unit_rolls(),
		"events": _event_data,
		"mirror_counter": _rules.get("mirror_counter", {}),
		"location_requirements": _rules.get("location_requirements", {}),
		"location_actions": _rules.get("location_actions", {}),
		"sequences": _rules.get("sequences", []),
	})


func _on_action_pressed(action: String) -> void:
	_ensure_flow()
	if action == "battle" and _flow.can_start_battle():
		_battle_source = "tutorial"
		_open_battle(_read_dictionary(BATTLE_ENEMIES_PATH).get("tutorial", {}), [])
		return
	if action.begins_with("approach:") and _flow.prepare_encounter_fight(action.trim_prefix("approach:")):
		_battle_source = "encounter"
		var summon: Array = [_summon_member()] if _flow.fight_approach() == "summon" else []
		_open_battle(_flow.encounter_enemy(), summon)
		return
	var before: String = _flow.location()
	var message: String = _flow.perform(action)
	if _flow.story_fight_pending():
		# A story fight (a sequence's final step, or the mirror) is fought on the battle screen.
		# Dialogue that leads into the fight plays first; the battle opens when it ends.
		_show_result(message)
		if _start_dialogue_for(action):
			_pending_battle = {"enemy": _flow.story_fight_enemy(), "note": message}
			return
		_open_story_battle(_flow.story_fight_enemy(), message)
		return
	_show_result(message)
	if action.begins_with("final:"):
		_play_transition(TransitionRules.KIND_CRITICAL)
	elif action.begins_with("go:") and _flow.location() != before:
		_play_transition(TransitionRules.KIND_TRAVEL)
	_start_dialogue_for(action)


## Starts the dialogue scene that the action triggers, unless that scene has already played.
## Returns true when a scene started.
func _start_dialogue_for(action: String) -> bool:
	var scene_id: String = _dialogue.scene_for_action(action)
	if scene_id == "":
		return false
	# The action may have been refused; the scene plays only once its event has set the flag.
	if not _flow.event_flag(_dialogue.required_flag(scene_id)):
		return false
	return _start_dialogue(scene_id)


## Starts the dialogue scene that belongs to a story day, unless it has already played.
func _start_dialogue_for_day(day: int) -> bool:
	var scene_id: String = _dialogue.scene_for_day(day)
	if scene_id == "":
		return false
	return _start_dialogue(scene_id)


## Plays a scene once: marks it played, starts it and shows its first line. Returns false when the
## scene was already played or cannot start.
func _start_dialogue(scene_id: String) -> bool:
	if _flow.dialogue_played(scene_id) or not _dialogue.start(scene_id):
		return false
	_flow.mark_dialogue_played(scene_id)
	_refresh_status()
	_show_dialogue_line()
	return true


## Opens the battle screen for a story fight, with the flow's message noted on it.
func _open_story_battle(enemy: Dictionary, message: String) -> void:
	_battle_source = "story"
	_open_battle(enemy, [])
	_battle_panel.add_note(message)


## Shows the line on screen: speaker, text and portrait. Narration has no portrait.
func _show_dialogue_line() -> void:
	var line: Dictionary = _dialogue.current_line()
	var speaker: String = str(line.get("speaker", ""))
	var text: String = str(line.get("text", ""))
	_dialogue_label.text = text if speaker == DialoguePlayer.NARRATOR else "%s：%s" % [speaker, text]
	_set_portrait(PortraitRules.path_for_speaker(speaker))
	# Focus the continue button so Enter or Space advances the dialogue without a mouse.
	_dialogue_button.grab_focus()


## Moves to the next dialogue line, or closes the scene after its last line.
func _on_dialogue_next_pressed() -> void:
	if _dialogue.advance():
		_show_dialogue_line()
		return
	_set_portrait("")
	_refresh_status()
	if not _pending_battle.is_empty():
		var pending: Dictionary = _pending_battle
		_pending_battle = {}
		_open_story_battle(pending["enemy"], str(pending["note"]))


## Loads the dialogue scene data, logging every validation error. A file with errors plays nothing.
func _load_dialogue() -> void:
	# Each file is validated on its own, so one broken file does not silence the others.
	var scenes: Array = []
	for path: String in DIALOGUE_PATHS:
		var parsed: Variant = _load_json(path)
		if not (parsed is Dictionary):
			push_error("Dialogue data missing or malformed: %s" % path)
			continue
		var errors := DialoguePlayer.validate(parsed)
		for error: String in errors:
			push_error("%s: %s" % [path, error])
		if errors.is_empty():
			scenes.append_array(parsed["scenes"])
	_dialogue.load_data({"scenes": scenes})


## Shows the portrait at path, or hides the portrait when path is empty or missing.
func _set_portrait(path: String) -> void:
	_portrait.texture = load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null
	_portrait.visible = _portrait.texture != null


## A new story day, and the first reached ending, each play their transition once.
func _check_story_transitions() -> void:
	var day: int = _flow.clock.day
	var day_changed: bool = day != _last_day
	if _last_day != 0 and day_changed:
		_play_transition(TransitionRules.KIND_CHAPTER)
	_last_day = day
	if day_changed:
		_start_dialogue_for_day(day)
	if _flow.is_ended() and not _ending_transition_played:
		_ending_transition_played = true
		_play_transition(TransitionRules.KIND_ENDING)


## Shows a transition illustration briefly, then fades it out. Non-blocking.
func _play_transition(kind: String) -> void:
	var path: String = TransitionRules.path_for(kind)
	if path == "" or not ResourceLoader.exists(path):
		return
	_transition.texture = load(path) as Texture2D
	_transition.visible = true
	if _transition_tween != null:
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.tween_property(_transition, "modulate:a", 1.0, 0.4)
	_transition_tween.tween_interval(1.6)
	_transition_tween.tween_property(_transition, "modulate:a", 0.0, 0.6)
	_transition_tween.tween_callback(func() -> void: _transition.visible = false)


## Shows the result of an action in the log and refreshes the screen.
func _show_result(message: String) -> void:
	_set_log(message)
	_refresh_status()
	if _flow.is_over():
		_action_bar.visible = false
		_slot_bar.visible = false


## Opens the interactive battle screen against enemy. extra_members join the party for this fight.
func _open_battle(enemy: Dictionary, extra_members: Array) -> void:
	if _battle_panel == null:
		_battle_panel = BattlePanel.new()
		_battle_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_battle_panel.offset_left = 48
		_battle_panel.offset_top = 32
		_battle_panel.offset_right = -48
		_battle_panel.offset_bottom = -32
		_battle_panel.finished.connect(_on_battle_finished)
		add_child(_battle_panel)
	var skill_file: Dictionary = _read_dictionary(BATTLE_SKILLS_PATH)
	var skills: Dictionary = skill_file.get("skills", {})
	var representative: Dictionary = skill_file.get("representative", {})
	var party: Array = []
	var curses: Dictionary = _flow.all_curse_stacks()
	for id: String in CHARACTER_IDS:
		var character: Dictionary = _read_dictionary(CHARACTER_FILE_PATH % id)
		var stacks: int = int(curses[id]) if curses.has(id) else -1
		party.append(BattleSetup.party_member(character, str(representative.get(id, "")), stacks))
	party.append_array(extra_members)
	_battle_panel.start(party, enemy.duplicate(true), _battle_rolls(), skills, Skirmish.DEFAULT_ROUND_LIMIT)
	_battle_panel.visible = true


## The temporary summoned member that joins the party for a summon approach. It has no skill.
func _summon_member() -> Dictionary:
	return {
		"id": "summon",
		"name": "召喚物",
		"hp": 20,
		"max_hp": 20,
		"mp": 0,
		"atk": Encounter.DEFAULT_SUMMON_ATK,
		"def": 0,
		"speed": 10,
		"skill": "",
	}


## Variance values in [-0.10, 0.10] for the battle damage formula.
func _battle_rolls() -> Array:
	var rolls: Array = []
	for index: int in range(ROLL_SAMPLES):
		rolls.append(randf() * 0.2 - 0.1)
	return rolls


## Applies the battle result to the day and closes the battle screen.
func _on_battle_finished(outcome: String) -> void:
	_battle_panel.visible = false
	var stacks: Dictionary = _battle_panel.curse_stacks()
	match _battle_source:
		"encounter":
			_show_result(_flow.finish_encounter_fight(outcome, stacks))
		"story":
			_show_result(_flow.finish_story_fight(outcome, stacks))
		_:
			_show_result(_flow.finish_battle(outcome, stacks))


func _on_save_pressed() -> void:
	_ensure_flow()
	if not _flow.can_save():
		_set_log("只能在營地存檔。請先休息。")
	elif SaveRepository.write(_save_path(), _flow.snapshot()):
		_set_log("已存檔。")
	else:
		_set_log("存檔失敗，請檢查儲存空間。")
	_refresh_status()


## The text under the panel: the caption of the ending reached, or the time-limit text.
func _ending_text() -> String:
	var endings: Dictionary = _labels.get("endings", {})
	if _flow.is_ended():
		return str(endings.get(_flow.ending_id(), ""))
	return str(_labels.get("time_up", ""))


## The closing text of the ending reached, or "" while the story continues.
func _ending_body() -> String:
	if not _flow.is_ended():
		return ""
	var bodies: Dictionary = _labels.get("ending_bodies", {})
	return str(bodies.get(_flow.ending_id(), ""))


## The illustration of the ending reached. Null while the game is still running or the art is missing.
func _ending_texture() -> Texture2D:
	var path: String = str(ENDING_ART_PATHS.get(_flow.ending_id(), ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Starts the whole game again from the beginning.
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


## The save file of the slot currently selected.
func _save_path() -> String:
	return SaveRepository.slot_path(_slot)


## Selects a camp save slot. The selected slot is used by save, load and restart-from-save.
func _on_slot_pressed(slot: int) -> void:
	_slot = slot
	_refresh_slot_buttons()
	_load_button.visible = SaveRepository.read(_save_path()) != null


## Shows each slot as empty or filled, and disables the slot that is selected.
func _refresh_slot_buttons() -> void:
	for slot_button: Button in _slot_buttons:
		var slot: int = int(slot_button.get_meta("slot"))
		var filled: bool = SaveRepository.read(SaveRepository.slot_path(slot)) != null
		slot_button.text = "存檔格 %d（%s）" % [slot, "有存檔" if filled else "空"]
		slot_button.disabled = slot == _slot


func _on_load_pressed() -> void:
	_ensure_flow()
	var data: Variant = SaveRepository.read(_save_path())
	if data == null:
		_set_log("沒有可讀取的存檔。")
		_log_scroll.visible = true
		_load_button.visible = false
		return
	if not _flow.restore(data):
		_set_log("存檔內容無效，無法讀取。")
		_log_scroll.visible = true
		return
	_dialogue.cancel()
	_pending_battle = {}
	_set_portrait("")
	_enter_day_one()
	var body: String = _ending_body()
	_set_log("已讀取存檔。" + ("\n\n" + body if body != "" else ""))


## Shows each chapter three button only at its place and only when its action or destination is open.
func _refresh_chapter3(bar_open: bool) -> void:
	# Buttons keep their places: a location shows all of its buttons, and those not available now are
	# disabled rather than hidden, so the buttons never move while the story advances.
	_chapter3_bar.visible = bar_open and _confirm_action == ""
	for button: Button in _chapter3_buttons:
		var action: String = str(button.get_meta("action"))
		var place: String = str(button.get_meta("place"))
		var at_place: bool = bar_open and _flow.location() == place
		button.visible = _flow.location() == place
		var done: bool = false
		var available: bool = at_place
		if action.begins_with("go:"):
			done = _chapter3_done(action)
			available = available and _flow.can_enter(action.trim_prefix("go:")) and not done
		elif action.begins_with("read:") and not _flow.is_step(action):
			available = available and _flow.can_act_here(action)
		else:
			done = _flow.step_done(action)
			available = available and _flow.step_visible(action)
		button.disabled = not available
		var base: String = str(button.get_meta("label"))
		var risk: float = _flow.step_curse_risk(action) if available else 0.0
		var text: String = base
		if _flow.is_unsafe_action(action):
			text = "危險：" + text
		if risk > 0.0:
			text += "｜血咒 %d%%" % roundi(risk * 100.0)
		if done:
			text = "已完成：" + base
		button.text = text


## A chapter button: runs the action, or asks for confirmation first when the action is unsafe or
## carries a blood-curse risk.
func _on_chapter_pressed(action: String) -> void:
	if not _flow.needs_confirmation(action):
		_on_action_pressed(action)
		return
	_confirm_action = action
	var risk: int = roundi(_flow.step_curse_risk(action) * 100.0)
	var warning: String = "這一步有危險" if _flow.is_unsafe_action(action) else "血咒可能擾亂這一步"
	_confirm_label.text = "%s（血咒風險 %d%%）。確定要行動嗎？" % [warning, risk]
	_chapter3_bar.visible = false
	_confirm_bar.visible = true


func _on_confirm_pressed() -> void:
	var action: String = _confirm_action
	_confirm_action = ""
	_confirm_bar.visible = false
	_on_action_pressed(action)


func _on_cancel_pressed() -> void:
	_confirm_action = ""
	_confirm_bar.visible = false
	_refresh_status()


## True when a destination has already been reached, so its button is hidden.
func _chapter3_done(action: String) -> bool:
	if action == "go:出口門廊":
		return _flow.event_flag("chapter3_exit")
	if action == "go:失聲之庭":
		return _flow.event_flag("garden_entered")
	if action == "go:血誓熔窟":
		return _flow.event_flag("lava_entered")
	if action == "go:墜星之心":
		return _flow.event_flag("heart_entered")
	return false


## Shows a log message and keeps the newest line in view.
func _set_log(text: String) -> void:
	_log_label.text = text
	_scroll_log_to_end.call_deferred()


func _scroll_log_to_end() -> void:
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


## The caption under the status line: the start text, a place caption, or the day as a fallback.
func _caption() -> String:
	if _flow.location() == "":
		return str(_captions.get("start", ""))
	var places: Dictionary = _captions.get("locations", {})
	if places.has(_flow.location()):
		return str(places[_flow.location()])
	return "第 %d 日｜%s" % [_flow.clock.day, _flow.location()]


## Reads a JSON file whose root is an object. Returns an empty Dictionary if it is not.
func _read_dictionary(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}


func _refresh_status() -> void:
	# While a dialogue scene is on screen it owns the dialogue box and hides the action bars.
	if _flow != null and not _dialogue.is_active():
		_dialogue_label.text = _caption()
		# May start a day's dialogue, which then owns the dialogue box.
		_check_story_transitions()
	var dialogue_open: bool = _dialogue.is_active()
	_dialogue_button.visible = dialogue_open
	var where: String = _flow.location()
	_status_label.text = _flow.status_text() + ("｜地點：%s" % where if where != "" else "")
	var party_line: String = _flow.party_text()
	_supply_label.text = _flow.supply_text() + ("\n" + party_line if party_line != "" else "")
	_action_buttons["rest"].disabled = not _flow.can_rest()
	_action_buttons["battle"].disabled = not _flow.can_start_battle()
	var approaches: Array[String] = _flow.pending_approaches()
	_rebuild_approach_bar(approaches)
	_approach_bar.visible = not approaches.is_empty()
	var actions_open: bool = approaches.is_empty() and not _flow.is_over() and not dialogue_open
	_action_bar.visible = actions_open
	_slot_bar.visible = _action_bar.visible
	_talk_bar.visible = actions_open
	_gate_bar.visible = actions_open and _flow.location() == "黑曜石之門"
	_passage_button.visible = _flow.event_flag("obsidian_gate_open") and not dialogue_open
	_ending_panel.visible = _flow.is_over()
	_ending_label.text = _ending_text()
	_ending_art.texture = _ending_texture()
	_ending_load_button.disabled = SaveRepository.read(_save_path()) == null
	_refresh_slot_buttons()
	_ending_load_button.modulate = Color(1, 1, 1, 0.4) if _ending_load_button.disabled else Color(1, 1, 1, 1)
	_refresh_chapter3(actions_open)
	_refresh_backdrop()
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


## Loads the narrative events of every chapter file, keeping only valid entries.
func _load_event_entries() -> Array:
	var valid: Array = []
	for path: String in EVENTS_PATHS:
		var parsed: Variant = _load_json(path)
		if not (parsed is Dictionary) or not parsed.has("events"):
			push_error("Event data missing or malformed: %s" % path)
			continue
		for event: Variant in parsed["events"]:
			var errors: Array[String] = EventRunner.validate(event)
			if errors.is_empty():
				valid.append(event)
			else:
				push_error("Event invalid: %s" % ", ".join(errors))
	return valid
