extends GdUnitTestSuite
# Unit tests for the mirror counterattack: Freya strikes a silver mirror, the mirror strikes
# back, she is wounded and her blood curse grows. It is a trial mechanic, not a kill route.

const COUNTER: Dictionary = {"damage": 8, "curse_stacks": 2, "enemy": "mirror_freya"}
const ENEMIES: Dictionary = {"mirror_freya": {"name": "鏡中芙蕾雅", "hp": 40, "max_hp": 40, "def": 3, "atk": 8}}


func _flow(extra: Dictionary = {}) -> DayOneFlow:
	var options := {"mirror_counter": COUNTER, "events": [], "battle_enemies": ENEMIES}
	options.merge(extra, true)
	return DayOneFlow.new([
		{"id": "freya", "name": "f", "atk": 10, "curse": true},
		{"id": "eron", "name": "e", "atk": 10},
	], [0.0], options)


func test_striking_a_mirror_opens_a_fight_without_wounding_freya_yet() -> void:
	var flow := _flow()
	flow.perform("go:黑曜石之門")

	flow.perform("strike:mirror")

	assert_bool(flow.story_fight_pending()).is_true()
	assert_int(flow.wounds("freya")).is_equal(0)


func test_losing_to_the_mirror_wounds_freya_and_grows_her_curse() -> void:
	var flow := _flow()
	flow.perform("go:黑曜石之門")
	flow.perform("strike:mirror")

	var message := flow.finish_story_fight("lost")

	assert_bool(message.contains("反擊")).is_true()
	assert_int(flow.wounds("freya")).is_equal(8)
	assert_int(flow.curse_stacks("freya")).is_equal(2)


func test_winning_against_the_mirror_avoids_the_counterattack() -> void:
	var flow := _flow()
	flow.perform("go:黑曜石之門")
	flow.perform("strike:mirror")

	flow.finish_story_fight("won")

	assert_int(flow.wounds("freya")).is_equal(0)
	assert_int(flow.curse_stacks("freya")).is_equal(0)


func test_striking_costs_one_segment_when_the_fight_is_over() -> void:
	var flow := _flow()
	flow.perform("go:黑曜石之門")
	var before := flow.clock.get_elapsed()
	flow.perform("strike:mirror")

	flow.finish_story_fight("won")

	assert_int(flow.clock.get_elapsed()).is_equal(before + 1)


func test_striking_is_refused_away_from_the_gate() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:守淵村")

	# Act
	var message := flow.perform("strike:mirror")

	# Assert
	assert_bool(message.contains("沒有可以攻擊的鏡面")).is_true()
	assert_int(flow.wounds("freya")).is_equal(0)


func test_wounds_and_curse_survive_a_snapshot_round_trip() -> void:
	# Arrange
	var source := _flow()
	source.perform("go:黑曜石之門")
	source.perform("strike:mirror")
	source.finish_story_fight("lost")
	var snapshot := source.snapshot()
	var target := _flow()

	# Act
	var restored := target.restore(snapshot)

	# Assert
	assert_bool(restored).is_true()
	assert_int(target.wounds("freya")).is_equal(8)
	assert_int(target.curse_stacks("freya")).is_equal(2)


func test_counterattack_does_not_open_the_gate_or_count_as_a_confession() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:黑曜石之門")

	# Act
	flow.perform("strike:mirror")

	# Assert
	assert_bool(flow.event_flag("mirror_freya_acknowledged")).is_false()
	assert_bool(flow.event_flag("obsidian_gate_open")).is_false()
