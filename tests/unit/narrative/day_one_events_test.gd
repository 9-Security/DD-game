extends GdUnitTestSuite
# Unit tests for narrative events inside the day-one flow: locations, conversations and
# how events change flags, messages, trust and the saved state.


func _party() -> Array:
	return [
		{"id": "freya", "name": "f", "atk": 10},
		{"id": "richter", "name": "r", "atk": 10},
	]


func _events() -> Array:
	return [
		{"id": "sapling", "trigger": {"action": "explore", "location": "焦林"}, "conditions": [],
			"effects": [{"type": "set_flag", "flag": "saw_convoy", "value": true}, {"type": "message", "text": "幼樹的記憶。"}]},
		{"id": "lie", "trigger": {"action": "talk:freya"}, "conditions": [{"flag": "saw_convoy", "equals": true}],
			"effects": [{"type": "message", "text": "里克特起疑。"}]},
		{"id": "bread", "trigger": {"action": "talk:freya_food"}, "conditions": [],
			"effects": [{"type": "trust", "character": "freya", "delta": 5}]},
	]


func _flow(extra: Dictionary = {}) -> DayOneFlow:
	var options := {"events": _events(), "trust": TrustBoard.new(["freya", "richter"], 50, 0, 100)}
	options.merge(extra, true)
	return DayOneFlow.new(_party(), [0.0], options)


func test_go_moves_the_party_and_spends_one_segment() -> void:
	# Arrange
	var flow := _flow()

	# Act
	flow.perform("go:焦林")

	# Assert
	assert_str(flow.location()).is_equal("焦林")
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_NOON)


func test_exploring_at_the_location_fires_its_event() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:焦林")

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_bool(message.contains("幼樹的記憶。")).is_true()
	assert_bool(flow.event_flag("saw_convoy")).is_true()


func test_conversation_is_free_and_waits_for_its_condition() -> void:
	# Arrange
	var flow := _flow()
	var before_segment := flow.clock.segment

	# Act
	var early := flow.perform("talk:freya")
	flow.perform("go:焦林")
	flow.perform("explore")
	var later := flow.perform("talk:freya")

	# Assert
	assert_bool(early.contains("起疑")).is_false()
	assert_bool(later.contains("起疑")).is_true()
	assert_int(before_segment).is_equal(DayClock.SEGMENT_MORNING)


func test_event_trust_change_is_applied_to_the_board() -> void:
	# Arrange
	var trust := TrustBoard.new(["freya", "richter"], 50, 0, 100)
	var flow := _flow({"trust": trust})

	# Act
	flow.perform("talk:freya_food")

	# Assert
	assert_int(trust.get_trust("freya")).is_equal(55)


func test_entering_night_fires_night_events() -> void:
	# Arrange
	var events := [{"id": "lamp", "trigger": {"night_entered": true}, "conditions": [],
		"effects": [{"type": "message", "text": "燈靈出現。"}, {"type": "set_flag", "flag": "saw_girl", "value": true}]}]
	var flow := _flow({"events": events})
	flow.perform("move")

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_bool(message.contains("燈靈出現。")).is_true()
	assert_bool(flow.event_flag("saw_girl")).is_true()


func test_snapshot_keeps_location_and_event_flags() -> void:
	# Arrange
	var source := _flow()
	source.perform("go:焦林")
	source.perform("explore")
	var snapshot := source.snapshot()
	var target := _flow()

	# Act
	var restored := target.restore(snapshot)

	# Assert
	assert_bool(restored).is_true()
	assert_str(target.location()).is_equal("焦林")
	assert_bool(target.event_flag("saw_convoy")).is_true()
