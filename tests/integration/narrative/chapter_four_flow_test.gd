extends GdUnitTestSuite
# Integration test: the chapter four route runs on the real data after the chapters two and three routes.
# The guardian's core is a story fight, so the route wins it before the core step completes.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const DIALOGUE_PATH: String = "res://assets/data/dialogue/chapter4_dialogue.json"
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
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
const CHAPTER_FOUR_ROUTE: Array[String] = [
	"go:失聲之庭",
	"commune:tree",
	"release:stabilize",
	"release:chain_one",
	"release:chain_two",
]


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _events() -> Array:
	var events: Array = []
	for path: String in EVENTS_PATHS:
		events.append_array(_json(path)["events"])
	return events


func _flow() -> DayOneFlow:
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
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)
	flow.perform("go:黑曜石之門")
	flow.perform("strike:mirror")
	flow.finish_story_fight("won")
	for character_id: String in CONFESSIONS:
		flow.perform("confess:%s" % character_id)
	flow.perform("go:門後通道")
	while flow.clock.day < 3:
		flow.clock.spend(1)
	for action: String in CHAPTER_THREE_ROUTE:
		flow.perform(action)
	while flow.clock.day < 4:
		flow.clock.spend(1)
	return flow


func test_the_chapter_four_route_sets_every_action_scene_flag() -> void:
	var flow := _flow()

	for action: String in CHAPTER_FOUR_ROUTE:
		flow.perform(action)
	flow.perform("release:core")
	assert_bool(flow.story_fight_pending()).is_true()
	flow.finish_story_fight("won")

	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if scene.has("requires_flag"):
			assert_bool(flow.event_flag(str(scene["requires_flag"]))).is_true()


func test_the_guardian_core_is_not_broken_before_the_fight_is_won() -> void:
	var flow := _flow()
	for action: String in CHAPTER_FOUR_ROUTE:
		flow.perform(action)

	flow.perform("release:core")

	assert_bool(flow.event_flag("guardian_core_broken_safely")).is_false()
