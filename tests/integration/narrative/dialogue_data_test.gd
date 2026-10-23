extends GdUnitTestSuite
# Integration test: the chapter two dialogue file is valid, and each scene is started by an action
# that the chapter two events really produce. A scene that no action can start would never play.

const DIALOGUE_PATH: String = "res://assets/data/dialogue/chapter2_dialogue.json"
const EVENTS_PATH: String = "res://assets/data/events/chapter2.json"
const LABELS_PATH: String = "res://assets/data/narrative/ui_labels.json"


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _event_actions() -> Array[String]:
	var actions: Array[String] = []
	for event: Dictionary in _json(EVENTS_PATH)["events"]:
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.has("action"):
			actions.append(str(trigger["action"]))
	return actions


func test_chapter_two_dialogue_file_has_no_validation_errors() -> void:
	var errors := DialoguePlayer.validate(_json(DIALOGUE_PATH))

	assert_int(errors.size()).is_equal(0)


func test_every_dialogue_scene_is_started_by_a_button_action() -> void:
	# A scene may be started by an event trigger, or by a button action listed in the UI labels
	# (for example the mirror strike, which the flow handles directly).
	var actions := _event_actions()
	var labels_text := JSON.stringify(_json(LABELS_PATH))

	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if not scene.has("action"):
			continue
		var action := str(scene["action"])
		assert_bool(actions.has(action) or labels_text.contains("\"%s\"" % action)).is_true()


func test_every_required_flag_is_set_by_a_chapter_two_event_or_the_flow() -> void:
	var set_flags: Array[String] = [DayOneFlow.MIRROR_STRIKE_FLAG]
	for event: Dictionary in _json(EVENTS_PATH)["events"]:
		for effect: Dictionary in event.get("effects", []):
			if effect.get("type", "") == "set_flag":
				set_flags.append(str(effect["flag"]))

	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if not scene.has("requires_flag"):
			continue
		assert_bool(set_flags.has(str(scene["requires_flag"]))).is_true()


func test_day_two_inn_scene_starts_on_day_two() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_json(DIALOGUE_PATH))

	assert_str(player.scene_for_day(2)).is_equal("ch2_dialogue_day2_inn")


func test_mirror_confessions_each_have_a_dialogue_scene() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_json(DIALOGUE_PATH))

	for character_id: String in ["eron", "freya", "richter", "inry"]:
		assert_str(player.scene_for_action("confess:%s" % character_id)).is_not_empty()
