extends GdUnitTestSuite
# Unit tests for the Obsidian Gate in the day-one flow: the mirror reveal, the four
# confessions, and the gate opening once all four are made. Confessions cost no time.


func _events() -> Array:
	var events: Array = [
		{"id": "reveal", "trigger": {"action": "go:黑曜石之門"}, "conditions": [],
			"effects": [{"type": "message", "text": "四面銀鏡亮起。"}]},
	]
	for id: String in ["eron", "freya", "richter", "inry"]:
		events.append({"id": "confess_" + id,
			"trigger": {"action": "confess:" + id, "location": "黑曜石之門"}, "conditions": [],
			"effects": [
				{"type": "set_flag", "flag": "mirror_%s_acknowledged" % id, "value": true},
				{"type": "message", "text": "%s承認了。" % id},
			]})
	events.append({"id": "gate_open", "trigger": {"location": "黑曜石之門"},
		"conditions": [
			{"flag": "mirror_eron_acknowledged"}, {"flag": "mirror_freya_acknowledged"},
			{"flag": "mirror_richter_acknowledged"}, {"flag": "mirror_inry_acknowledged"},
		],
		"effects": [
			{"type": "set_flag", "flag": "obsidian_gate_open", "value": true},
			{"type": "message", "text": "門開啟了。"},
		]})
	return events


func _flow() -> DayOneFlow:
	return DayOneFlow.new([{"id": "eron", "name": "e", "atk": 10}], [0.0], {"events": _events()})


func test_entering_the_gate_shows_the_reveal() -> void:
	# Arrange
	var flow := _flow()

	# Act
	var message := flow.perform("go:黑曜石之門")

	# Assert
	assert_bool(message.contains("四面銀鏡亮起。")).is_true()


func test_confession_costs_no_time_and_sets_its_flag() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:黑曜石之門")
	var before := flow.clock.get_elapsed()

	# Act
	flow.perform("confess:eron")

	# Assert
	assert_bool(flow.event_flag("mirror_eron_acknowledged")).is_true()
	assert_int(flow.clock.get_elapsed()).is_equal(before)


func test_confession_is_refused_away_from_the_gate() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:守淵村")

	# Act
	flow.perform("confess:eron")

	# Assert
	assert_bool(flow.event_flag("mirror_eron_acknowledged")).is_false()


func test_gate_opens_only_after_all_four_confess() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:黑曜石之門")
	flow.perform("confess:eron")
	flow.perform("confess:freya")
	flow.perform("confess:richter")

	# Act
	var partial := flow.event_flag("obsidian_gate_open")
	var last := flow.perform("confess:inry")

	# Assert
	assert_bool(partial).is_false()
	assert_bool(flow.event_flag("obsidian_gate_open")).is_true()
	assert_bool(last.contains("門開啟了。")).is_true()


func test_confessions_can_be_made_in_any_order() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:黑曜石之門")

	# Act
	flow.perform("confess:inry")
	flow.perform("confess:richter")
	flow.perform("confess:eron")
	flow.perform("confess:freya")

	# Assert
	assert_bool(flow.event_flag("obsidian_gate_open")).is_true()
