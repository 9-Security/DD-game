extends GdUnitTestSuite
# Integration test: the chapter three dialogue file is valid, every scene's flag and action come from
# real game data, and the chapter three route runs end to end after the chapter two route.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const LABELS_PATH: String = "res://assets/data/narrative/ui_labels.json"
const DIALOGUE_PATH: String = "res://assets/data/dialogue/chapter3_dialogue.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
]
const CONFESSIONS: Array[String] = ["eron", "freya", "richter", "inry"]
const CHAPTER_THREE_ROUTE: Array[String] = [
	"go:咒牆迷廊",
	"read:first_name",
	"read:second_name",
	"go:名冊廊廳",
	"read:kaen",
	"seal:draw",
	"seal:link",
	"seal:read",
	"seal:kaen",
	"go:出口門廊",
]


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _events() -> Array:
	var events: Array = []
	for path: String in EVENTS_PATHS:
		events.append_array(_json(path)["events"])
	return events


## Flags that the game sets: event effects plus the step flags of every balance sequence.
func _set_flags() -> Array[String]:
	var flags: Array[String] = []
	for event: Dictionary in _events():
		for effect: Dictionary in event.get("effects", []):
			if effect.get("type", "") == "set_flag":
				flags.append(str(effect["flag"]))
	for sequence: Dictionary in _json(BALANCE_PATH)["sequences"]:
		for step: Dictionary in sequence.get("steps", []):
			if step.has("flag"):
				flags.append(str(step["flag"]))
	return flags


func _flow(day_segments: int) -> DayOneFlow:
	var balance := _json(BALANCE_PATH)
	var flow := DayOneFlow.new([
		{"id": "freya", "name": "f", "atk": 16, "curse": true},
		{"id": "eron", "name": "e", "atk": 8},
		{"id": "richter", "name": "r", "atk": 10},
		{"id": "inry", "name": "i", "atk": 6},
	], [0.99], {
		"sequences": balance["sequences"],
		"location_requirements": balance["location_requirements"],
		"location_actions": balance["location_actions"],
		"events": _events(),
		"battle_enemies": _json(ENEMIES_PATH),
		"mirror_counter": balance["mirror_counter"],
		"event_flags": {},
	})
	flow.clock.spend(day_segments)
	return flow


func _run_chapter_two(flow: DayOneFlow) -> void:
	flow.perform("go:黑曜石之門")
	flow.perform("strike:mirror")
	flow.finish_story_fight("won")
	for character_id: String in CONFESSIONS:
		flow.perform("confess:%s" % character_id)
	flow.perform("go:門後通道")


func test_chapter_three_dialogue_file_has_no_validation_errors() -> void:
	var errors := DialoguePlayer.validate(_json(DIALOGUE_PATH))

	assert_int(errors.size()).is_equal(0)


func test_every_chapter_three_scene_flag_is_set_by_the_game() -> void:
	var set_flags := _set_flags()

	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if scene.has("requires_flag"):
			assert_bool(set_flags.has(str(scene["requires_flag"]))).is_true()


func test_every_chapter_three_action_scene_is_a_real_action() -> void:
	var labels_text := JSON.stringify(_json(LABELS_PATH))
	var event_actions: Array[String] = []
	for event: Dictionary in _events():
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.has("action"):
			event_actions.append(str(trigger["action"]))

	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if not scene.has("action"):
			continue
		var action := str(scene["action"])
		assert_bool(event_actions.has(action) or labels_text.contains("\"%s\"" % action)).is_true()


func test_chapter_three_scene_starts_on_day_three() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_json(DIALOGUE_PATH))

	assert_str(player.scene_for_day(3)).is_equal("ch3_dialogue_day3_wake")


func test_the_chapter_three_route_sets_every_action_scene_flag() -> void:
	var flow := _flow(DayClock.SEGMENTS_PER_DAY)
	_run_chapter_two(flow)
	# Advance to day three by time, since the chapter two actions also spend time.
	while flow.clock.day < 3:
		flow.clock.spend(1)
	assert_int(flow.clock.day).is_equal(3)

	for action: String in CHAPTER_THREE_ROUTE:
		flow.perform(action)

	assert_bool(flow.event_flag("chapter3_exit")).is_true()
	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if scene.has("requires_flag"):
			assert_bool(flow.event_flag(str(scene["requires_flag"]))).is_true()
