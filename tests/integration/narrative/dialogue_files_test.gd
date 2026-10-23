extends GdUnitTestSuite
# Integration test: every dialogue file is valid, every scene is started by a real game trigger, and
# every scene's flag is set by the game. It covers all dialogue files, so each new chapter is checked
# without a separate test file.

const DIALOGUE_DIR: String = "res://assets/data/dialogue/"
const DIALOGUE_FILES: Array[String] = [
	"chapter2_dialogue.json",
	"chapter3_dialogue.json",
	"chapter4_dialogue.json",
	"chapter5_dialogue.json",
	"chapter6_dialogue.json",
	"chapter7_dialogue.json",
	"chapter7_endings_dialogue.json",
]
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter1.json",
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
	"res://assets/data/events/chapter6.json",
	"res://assets/data/events/chapter7.json",
]
const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const LABELS_PATH: String = "res://assets/data/narrative/ui_labels.json"


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _all_scenes() -> Array:
	var scenes: Array = []
	for file: String in DIALOGUE_FILES:
		scenes.append_array(_json(DIALOGUE_DIR + file)["scenes"])
	return scenes


func _set_flags() -> Array[String]:
	var flags: Array[String] = [DayOneFlow.MIRROR_STRIKE_FLAG]
	for path: String in EVENTS_PATHS:
		for event: Dictionary in _json(path)["events"]:
			for effect: Dictionary in event.get("effects", []):
				if effect.get("type", "") == "set_flag":
					flags.append(str(effect["flag"]))
	for sequence: Dictionary in _json(BALANCE_PATH)["sequences"]:
		for step: Dictionary in sequence.get("steps", []):
			if step.has("flag"):
				flags.append(str(step["flag"]))
	return flags


func test_every_dialogue_file_has_no_validation_errors() -> void:
	for file: String in DIALOGUE_FILES:
		var errors := DialoguePlayer.validate(_json(DIALOGUE_DIR + file))
		assert_int(errors.size()).is_equal(0)


func test_every_scene_flag_is_set_by_the_game() -> void:
	var set_flags := _set_flags()

	for scene: Dictionary in _all_scenes():
		if scene.has("requires_flag"):
			assert_bool(set_flags.has(str(scene["requires_flag"]))).is_true()


func test_every_action_scene_is_a_real_action() -> void:
	var labels_text := JSON.stringify(_json(LABELS_PATH))
	var event_actions: Array[String] = []
	for path: String in EVENTS_PATHS:
		for event: Dictionary in _json(path)["events"]:
			var trigger: Dictionary = event.get("trigger", {})
			if trigger.has("action"):
				event_actions.append(str(trigger["action"]))

	for scene: Dictionary in _all_scenes():
		if not scene.has("action"):
			continue
		var action := str(scene["action"])
		assert_bool(event_actions.has(action) or labels_text.contains("\"%s\"" % action)).is_true()


func test_every_day_scene_names_a_day_that_appears_once() -> void:
	var days: Dictionary = {}
	for scene: Dictionary in _all_scenes():
		if scene.has("day"):
			var day := int(scene["day"])
			assert_bool(days.has(day)).is_false()
			days[day] = true
