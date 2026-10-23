extends GdUnitTestSuite
# Integration test: the chapter two route runs end to end on the real data. Each action that starts a
# dialogue scene sets the flag that scene requires, the gate opens only after all four confessions,
# and the passage opens after that.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const EVENTS_PATH: String = "res://assets/data/events/chapter2.json"
const DIALOGUE_PATH: String = "res://assets/data/dialogue/chapter2_dialogue.json"
const CONFESSIONS: Array[String] = ["eron", "freya", "richter", "inry"]


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _flow() -> DayOneFlow:
	var balance := _json(BALANCE_PATH)
	return DayOneFlow.new([
		{"id": "freya", "name": "f", "atk": 16, "curse": true},
		{"id": "eron", "name": "e", "atk": 8},
		{"id": "richter", "name": "r", "atk": 10},
		{"id": "inry", "name": "i", "atk": 6},
	], [0.0], {
		"sequences": balance["sequences"],
		"location_requirements": balance["location_requirements"],
		"location_actions": balance["location_actions"],
		"events": _json(EVENTS_PATH)["events"],
		"battle_enemies": _json(ENEMIES_PATH),
		"mirror_counter": balance["mirror_counter"],
		"event_flags": {},
	})


func test_the_gate_cannot_be_reached_on_day_one() -> void:
	var flow := _flow()

	flow.perform("go:黑曜石之門")

	assert_bool(flow.event_flag("gate_reached")).is_false()
	assert_str(flow.location()).is_not_equal("黑曜石之門")


func test_the_chapter_two_route_plays_every_action_scene_and_opens_the_passage() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)
	assert_int(flow.clock.day).is_equal(2)

	flow.perform("go:黑曜石之門")
	assert_bool(flow.event_flag("gate_reached")).is_true()

	flow.perform("strike:mirror")
	assert_bool(flow.event_flag(DayOneFlow.MIRROR_STRIKE_FLAG)).is_true()
	flow.finish_story_fight("won")

	for character_id: String in CONFESSIONS:
		flow.perform("confess:%s" % character_id)
	assert_bool(flow.event_flag("obsidian_gate_open")).is_true()

	flow.perform("go:門後通道")
	assert_bool(flow.event_flag("passage_entered")).is_true()


func test_each_action_scene_flag_is_set_by_the_route() -> void:
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)
	flow.perform("go:黑曜石之門")
	flow.perform("strike:mirror")
	flow.finish_story_fight("won")
	for character_id: String in CONFESSIONS:
		flow.perform("confess:%s" % character_id)
	flow.perform("go:門後通道")

	for scene: Dictionary in _json(DIALOGUE_PATH)["scenes"]:
		if scene.has("requires_flag"):
			assert_bool(flow.event_flag(str(scene["requires_flag"]))).is_true()


func test_a_refused_confession_before_the_gate_sets_no_flag() -> void:
	var flow := _flow()

	flow.perform("confess:eron")

	assert_bool(flow.event_flag("mirror_eron_acknowledged")).is_false()
