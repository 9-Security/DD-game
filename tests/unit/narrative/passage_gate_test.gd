extends GdUnitTestSuite
# Unit tests for the passage behind the Obsidian Gate: locked until the gate opens, and
# arriving there fires its own event without spending anything extra.

const REQUIREMENTS: Dictionary = {"門後通道": "obsidian_gate_open"}


func _events() -> Array:
	return [
		{"id": "gate_open", "trigger": {"location": "黑曜石之門"},
			"conditions": [{"flag": "mirror_eron_acknowledged"}],
			"effects": [{"type": "set_flag", "flag": "obsidian_gate_open", "value": true}]},
		{"id": "passage_arrival", "trigger": {"action": "go:門後通道"},
			"conditions": [{"flag": "obsidian_gate_open"}],
			"effects": [
				{"type": "set_flag", "flag": "passage_entered", "value": true},
				{"type": "message", "text": "門後是一條幽暗的通道，岩壁上的紋路隨著腳步逐漸顯露。"},
			]},
	]


func _flow(flags: Dictionary = {}) -> DayOneFlow:
	return DayOneFlow.new([{"id": "eron", "name": "e", "atk": 10}], [0.0], {
		"events": _events(), "location_requirements": REQUIREMENTS, "event_flags": flags,
	})


func test_passage_is_locked_while_the_gate_is_closed() -> void:
	# Arrange
	var flow := _flow()
	var before := flow.clock.get_elapsed()

	# Act
	var message := flow.perform("go:門後通道")

	# Assert
	assert_bool(message.contains("無法通行")).is_true()
	assert_bool(flow.event_flag("passage_entered")).is_false()
	assert_str(flow.location()).is_not_equal("門後通道")
	assert_int(flow.clock.get_elapsed()).is_equal(before)


func test_passage_opens_after_the_gate_opens_and_fires_its_arrival() -> void:
	# Arrange: the gate's flag is already set
	var flow := _flow({"obsidian_gate_open": true})

	# Act
	var message := flow.perform("go:門後通道")

	# Assert
	assert_str(flow.location()).is_equal("門後通道")
	assert_bool(flow.event_flag("passage_entered")).is_true()
	assert_bool(message.contains("幽暗的通道")).is_true()


func test_locations_without_a_requirement_stay_open() -> void:
	# Arrange
	var flow := _flow()

	# Act
	flow.perform("go:焦林")

	# Assert
	assert_str(flow.location()).is_equal("焦林")
