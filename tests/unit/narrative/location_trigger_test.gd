extends GdUnitTestSuite
# Unit tests for location-only triggers: they match any action performed at that location.


func _gate_event() -> Dictionary:
	return {
		"id": "gate_open", "trigger": {"location": "黑曜石之門"},
		"conditions": [{"flag": "a", "equals": true}],
		"effects": [{"type": "message", "text": "門開了。"}],
	}


func test_location_only_trigger_fires_on_any_action_at_that_location() -> void:
	# Arrange
	var runner := EventRunner.new([_gate_event()], {"a": true})

	# Act
	var result := runner.evaluate({"action": "explore", "location": "黑曜石之門"})

	# Assert
	assert_int((result["messages"] as Array).size()).is_equal(1)


func test_location_only_trigger_ignores_other_locations() -> void:
	# Arrange
	var runner := EventRunner.new([_gate_event()], {"a": true})

	# Act
	var result := runner.evaluate({"action": "explore", "location": "守淵村"})

	# Assert
	assert_int((result["messages"] as Array).size()).is_equal(0)


func test_location_only_trigger_waits_for_its_conditions() -> void:
	# Arrange
	var runner := EventRunner.new([_gate_event()], {})

	# Act
	var result := runner.evaluate({"action": "explore", "location": "黑曜石之門"})

	# Assert
	assert_int((result["messages"] as Array).size()).is_equal(0)


func test_location_only_trigger_passes_validation() -> void:
	# Arrange / Act
	var errors := EventRunner.validate(_gate_event())

	# Assert
	assert_int(errors.size()).is_equal(0)
