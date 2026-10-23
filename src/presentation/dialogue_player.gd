class_name DialoguePlayer
extends RefCounted
## Plays scripted dialogue scenes one line at a time.
##
## A scene is started by a player action (its `action` field) and is shown once per game; the
## caller records that in the game state. Pure logic with no scene access, so it can be unit tested.
##
## Data format (assets/data/dialogue/*.json):
## {"scenes": [{"id": String, "action": String, "requires_flag": String, "source_ref": String,
##              "lines": [{"speaker": String, "text": String}]}]}
## A scene plays only after the action's event has set `requires_flag`, so a refused action never
## shows its dialogue.
## Narration uses the speaker NARRATOR. Every other speaker must have a portrait in PortraitRules.

## Speaker name for narration lines. Narration has no portrait.
const NARRATOR: String = "旁白"
## Longest allowed line, so each line fits the dialogue box (project narrative rule).
const MAX_LINE_LENGTH: int = 120

## Action string to scene id. Only scenes that passed validation are stored.
var _scene_ids_by_action: Dictionary = {}
## Scene id to the story flag that must be set before the scene plays.
var _flag_by_scene: Dictionary = {}
## Scene id to its lines.
var _lines_by_scene: Dictionary = {}
## Lines of the scene being played, empty when no scene is active.
var _active_lines: Array = []
## Index of the line on screen in the active scene.
var _line_index: int = 0


## Returns the validation errors in the data. Empty when the data is valid.
static func validate(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not (data.get("scenes", null) is Array):
		errors.append("dialogue data has no scenes array")
		return errors
	var seen_ids: Dictionary = {}
	for scene: Variant in data["scenes"]:
		if not (scene is Dictionary):
			errors.append("dialogue scene is not a dictionary")
			continue
		var scene_id: String = str(scene.get("id", ""))
		if scene_id == "":
			errors.append("dialogue scene has no id")
		elif seen_ids.has(scene_id):
			errors.append("duplicate dialogue scene id: %s" % scene_id)
		seen_ids[scene_id] = true
		if str(scene.get("action", "")) == "":
			errors.append("dialogue scene %s has no action" % scene_id)
		if str(scene.get("requires_flag", "")) == "":
			errors.append("dialogue scene %s has no requires_flag" % scene_id)
		errors.append_array(_validate_lines(scene_id, scene.get("lines", null)))
	return errors


## Loads the scenes after validating them. When the data is invalid nothing is loaded, so a
## broken file can never show a half-written scene. Returns the validation errors.
func load_data(data: Dictionary) -> PackedStringArray:
	var errors := validate(data)
	_scene_ids_by_action.clear()
	_flag_by_scene.clear()
	_lines_by_scene.clear()
	_active_lines = []
	_line_index = 0
	if not errors.is_empty():
		return errors
	for scene: Dictionary in data["scenes"]:
		var scene_id: String = str(scene["id"])
		_scene_ids_by_action[str(scene["action"])] = scene_id
		_flag_by_scene[scene_id] = str(scene["requires_flag"])
		_lines_by_scene[scene_id] = scene["lines"]
	return errors


## Returns the id of the scene that the action starts, or "" when the action has no scene.
func scene_for_action(action: String) -> String:
	return str(_scene_ids_by_action.get(action, ""))


## Returns the story flag that must be set before the scene plays, or "" for an unknown scene.
func required_flag(scene_id: String) -> String:
	return str(_flag_by_scene.get(scene_id, ""))


## Starts a scene. Returns false when the id is unknown or the scene has no lines.
func start(scene_id: String) -> bool:
	if not _lines_by_scene.has(scene_id):
		return false
	var lines: Array = _lines_by_scene[scene_id]
	if lines.is_empty():
		return false
	_active_lines = lines
	_line_index = 0
	return true


## True while a scene is on screen.
func is_active() -> bool:
	return not _active_lines.is_empty()


## Returns the line on screen as {"speaker": String, "text": String}, or {} when no scene is active.
func current_line() -> Dictionary:
	if not is_active():
		return {}
	return _active_lines[_line_index]


## Moves to the next line. Returns true while the scene continues, false when it has ended.
func advance() -> bool:
	if not is_active():
		return false
	_line_index += 1
	if _line_index < _active_lines.size():
		return true
	cancel()
	return false


## Stops the active scene, for example when the player loads a save.
func cancel() -> void:
	_active_lines = []
	_line_index = 0


## Checks the lines of one scene and returns the errors found.
static func _validate_lines(scene_id: String, lines: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not (lines is Array) or (lines as Array).is_empty():
		errors.append("dialogue scene %s has no lines" % scene_id)
		return errors
	for line: Variant in lines:
		if not (line is Dictionary):
			errors.append("dialogue scene %s has a line that is not a dictionary" % scene_id)
			continue
		var speaker: String = str(line.get("speaker", ""))
		var text: String = str(line.get("text", ""))
		if speaker != NARRATOR and not PortraitRules.PORTRAITS.has(speaker):
			errors.append("dialogue scene %s has unknown speaker: %s" % [scene_id, speaker])
		if text == "":
			errors.append("dialogue scene %s has an empty line" % scene_id)
		elif text.length() > MAX_LINE_LENGTH:
			errors.append("dialogue scene %s has a line over %d characters" % [scene_id, MAX_LINE_LENGTH])
	return errors
