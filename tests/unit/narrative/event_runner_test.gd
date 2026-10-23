extends GdUnitTestSuite
# Unit tests for the event runner: triggers, conditions, effects and once-only firing.


func _set_flag_event(id: String, trigger_action: String, flag: String) -> Dictionary:
	return {
		"id": id,
		"trigger": {"action": trigger_action},
		"conditions": [],
		"effects": [{"type": "set_flag", "flag": flag, "value": true}, {"type": "message", "text": "事件 %s" % id}],
	}


func _context(action: String, location: String = "", night: bool = false) -> Dictionary:
	return {"action": action, "location": location, "night_entered": night}


func test_matching_action_fires_the_event_and_sets_its_flag() -> void:
	# Arrange
	var runner := EventRunner.new([_set_flag_event("sapling", "explore", "saw_convoy")], {})

	# Act
	var result := runner.evaluate(_context("explore"))

	# Assert
	assert_bool(runner.flags.get("saw_convoy", false)).is_true()
	assert_bool((result["messages"] as Array).has("事件 sapling")).is_true()


func test_event_fires_only_once() -> void:
	# Arrange
	var runner := EventRunner.new([_set_flag_event("sapling", "explore", "saw_convoy")], {})
	runner.evaluate(_context("explore"))

	# Act
	var second := runner.evaluate(_context("explore"))

	# Assert
	assert_int((second["messages"] as Array).size()).is_equal(0)


func test_location_must_match_when_the_trigger_names_one() -> void:
	# Arrange
	var event := _set_flag_event("sapling", "explore", "saw_convoy")
	event["trigger"]["location"] = "焦林"
	var runner := EventRunner.new([event], {})

	# Act
	var elsewhere := runner.evaluate(_context("explore", "守淵村"))
	var there := runner.evaluate(_context("explore", "焦林"))

	# Assert
	assert_int((elsewhere["messages"] as Array).size()).is_equal(0)
	assert_int((there["messages"] as Array).size()).is_equal(1)


func test_flag_condition_blocks_the_event_until_the_flag_is_set() -> void:
	# Arrange
	var event := _set_flag_event("lie", "talk:freya", "richter_suspicious")
	event["conditions"] = [{"flag": "saw_convoy", "equals": true}]
	var runner := EventRunner.new([event], {})

	# Act
	var before := runner.evaluate(_context("talk:freya"))
	runner.flags["saw_convoy"] = true
	var after := runner.evaluate(_context("talk:freya"))

	# Assert
	assert_int((before["messages"] as Array).size()).is_equal(0)
	assert_int((after["messages"] as Array).size()).is_equal(1)


func test_night_entry_trigger_fires_only_on_night_entry() -> void:
	# Arrange
	var event := {
		"id": "lamp", "trigger": {"night_entered": true}, "conditions": [],
		"effects": [{"type": "message", "text": "燈靈"}],
	}
	var runner := EventRunner.new([event], {})

	# Act
	var no_night := runner.evaluate(_context("move"))
	var night := runner.evaluate(_context("move", "", true))

	# Assert
	assert_int((no_night["messages"] as Array).size()).is_equal(0)
	assert_int((night["messages"] as Array).size()).is_equal(1)


func test_trust_effect_is_returned_for_the_flow_to_apply() -> void:
	# Arrange
	var event := {
		"id": "bread", "trigger": {"action": "talk:freya_food"}, "conditions": [],
		"effects": [{"type": "trust", "character": "freya", "delta": 5}],
	}
	var runner := EventRunner.new([event], {})

	# Act
	var result := runner.evaluate(_context("talk:freya_food"))

	# Assert
	var changes: Array = result["trust_changes"]
	assert_int(changes.size()).is_equal(1)
	assert_str(changes[0]["character"]).is_equal("freya")
	assert_int(int(changes[0]["delta"])).is_equal(5)


func test_validation_rejects_unknown_effect_and_missing_trigger() -> void:
	# Arrange
	var bad := {"id": "x", "trigger": {}, "conditions": [], "effects": [{"type": "teleport"}]}

	# Act
	var errors := EventRunner.validate(bad)

	# Assert
	assert_bool(errors.has("trigger must name an action or night_entered")).is_true()
	assert_bool(errors.has("effects[0].type must be one of: set_flag, message, trust")).is_true()


func test_flags_survive_a_snapshot_round_trip() -> void:
	# Arrange
	var source := EventRunner.new([_set_flag_event("sapling", "explore", "saw_convoy")], {})
	source.evaluate(_context("explore"))
	var snapshot := source.snapshot()
	var target := EventRunner.new([_set_flag_event("sapling", "explore", "saw_convoy")], {})

	# Act
	var restored := target.restore(snapshot)
	var again := target.evaluate(_context("explore"))

	# Assert
	assert_bool(restored).is_true()
	assert_bool(target.flags.get("saw_convoy", false)).is_true()
	assert_int((again["messages"] as Array).size()).is_equal(0)
