extends GdUnitTestSuite
# Integration test: the route from the blood oath cavern to ending A runs on the real data. It starts
# from the chapter four route, so it checks that the later chapters are reachable in time.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const DIALOGUE_PATHS: Array[String] = [
	"res://assets/data/dialogue/chapter5_dialogue.json",
	"res://assets/data/dialogue/chapter6_dialogue.json",
	"res://assets/data/dialogue/chapter7_dialogue.json",
	"res://assets/data/dialogue/chapter7_endings_dialogue.json",
]
const EVENTS_PATHS: Array[String] = [
	"res://assets/data/events/chapter2.json",
	"res://assets/data/events/chapter3.json",
	"res://assets/data/events/chapter4.json",
	"res://assets/data/events/chapter5.json",
	"res://assets/data/events/chapter6.json",
	"res://assets/data/events/chapter7.json",
]
const CONFESSIONS: Array[String] = ["eron", "freya", "richter", "inry"]
const EARLIER_ROUTE: Array[String] = [
	"go:咒牆迷廊", "read:first_name", "read:second_name", "go:名冊廊廳", "read:kaen",
	"seal:draw", "seal:link", "seal:read", "seal:kaen", "go:出口門廊",
	"go:失聲之庭", "commune:tree", "release:stabilize", "release:chain_one", "release:chain_two",
]
const LATER_ROUTE: Array[String] = [
	"go:血誓熔窟", "read:father_record", "oath:lower", "oath:cover", "oath:barrier", "oath:chain", "oath:pierce",
	"descend:stairs", "go:墜星之心", "cross:test", "cross:go", "inry:stop_force", "inry:listen",
	"read:oath_truth", "harvest:assess", "harvest:whole", "return:safe",
	"palace:evidence", "palace:orders", "palace:tell_liana", "palace:liana_consent",
	"final:king_volunteers", "final:ritual_a",
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
	for action: String in EARLIER_ROUTE:
		flow.perform(action)
	flow.perform("release:core")
	flow.finish_story_fight("won")
	return flow


## Places gated by day in the balance rules; the route waits in time until each one is open.
func _advance_for(flow: DayOneFlow, action: String) -> void:
	var needed := 0
	if action == "go:血誓熔窟":
		needed = 5
	elif action == "go:墜星之心":
		needed = 6
	while flow.clock.day < needed:
		flow.clock.spend(1)


func _perform_all(flow: DayOneFlow, actions: Array[String]) -> void:
	for action: String in actions:
		if flow.story_fight_pending():
			flow.finish_story_fight("won")
		_advance_for(flow, action)
		flow.perform(action)
	if flow.story_fight_pending():
		flow.finish_story_fight("won")


func test_the_route_reaches_ending_a_within_time() -> void:
	var flow := _flow()

	_perform_all(flow, LATER_ROUTE)

	assert_bool(flow.event_flag("ending_a")).is_true()
	assert_bool(flow.is_time_up()).is_false()


## Endings B and C belong to other routes, so this route checks every scene except theirs.
func test_the_route_reaches_ending_b_when_the_oath_is_broken() -> void:
	var flow := _flow()
	var route: Array[String] = []
	for action: String in LATER_ROUTE:
		if action == "final:king_volunteers" or action == "final:ritual_a":
			continue
		route.append(action)
	route.append("final:break_oath")

	_perform_all(flow, route)

	assert_bool(flow.event_flag("ending_b")).is_true()


func test_every_later_scene_on_this_route_has_its_flag_set() -> void:
	var flow := _flow()
	_perform_all(flow, LATER_ROUTE)

	for path: String in DIALOGUE_PATHS:
		for scene: Dictionary in _json(path)["scenes"]:
			var id := str(scene["id"])
			if not scene.has("requires_flag") or id.contains("ending_b") or id.contains("ending_c"):
				continue
			assert_bool(flow.event_flag(str(scene["requires_flag"]))).is_true()
