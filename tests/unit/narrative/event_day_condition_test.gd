extends GdUnitTestSuite
# Unit tests for day conditions on event triggers: "day" matches one day exactly, and
# "min_day" matches that day or any later day.


func _event(trigger: Dictionary) -> Dictionary:
	return {"id": "e", "trigger": trigger, "conditions": [], "effects": [{"type": "message", "text": "hit"}]}


func _messages(trigger: Dictionary, day: int) -> Array:
	var runner := EventRunner.new([_event(trigger)], {})
	var result: Dictionary = runner.evaluate({"action": "go:x", "location": "", "day": day})
	return result["messages"]


func test_day_trigger_fires_only_on_that_day() -> void:
	var trigger: Dictionary = {"action": "go:x", "day": 2}
	assert_array(_messages(trigger, 1)).is_empty()
	assert_array(_messages(trigger, 2)).contains_exactly(["hit"])
	assert_array(_messages(trigger, 3)).is_empty()


func test_min_day_trigger_fires_on_that_day_and_later() -> void:
	var trigger: Dictionary = {"action": "go:x", "min_day": 2}
	assert_array(_messages(trigger, 1)).is_empty()
	assert_array(_messages(trigger, 2)).contains_exactly(["hit"])
	assert_array(_messages(trigger, 3)).contains_exactly(["hit"])


func test_day_values_from_json_floats_still_match() -> void:
	# JSON parsing produces floats for numbers, so 2.0 must match day 2.
	var trigger: Dictionary = {"action": "go:x", "day": 2.0}
	assert_array(_messages(trigger, 2)).contains_exactly(["hit"])


func test_validate_rejects_a_non_numeric_day() -> void:
	var event: Dictionary = _event({"action": "go:x", "day": "2"})
	assert_int(EventRunner.validate(event).size()).is_greater(0)
