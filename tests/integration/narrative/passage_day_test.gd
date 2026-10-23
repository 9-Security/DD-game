extends GdUnitTestSuite
# Integration test: the real chapter two data picks the passage arrival text by day. Day two
# keeps the novel's "第二日尚未結束"; a later day must not claim it.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const EVENTS_PATH: String = "res://assets/data/events/chapter2.json"
const DAY_TWO_LINE: String = "第二日尚未結束"


func _flow() -> DayOneFlow:
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	return DayOneFlow.new([{"id": "eron", "name": "艾洛恩", "atk": 10}], [0.0], {
		"events": chapter["events"],
		"location_requirements": balance["location_requirements"],
		"event_flags": {"obsidian_gate_open": true},
	})


func test_passage_on_day_two_keeps_the_novel_line() -> void:
	# Arrange: day two morning, then the gate, then the passage (ends on day two night)
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)

	# Act
	flow.perform("go:黑曜石之門")
	var message: String = flow.perform("go:門後通道")

	# Assert
	assert_int(flow.clock.day).is_equal(2)
	assert_bool(message.contains(DAY_TWO_LINE)).is_true()


func test_passage_after_day_two_does_not_claim_day_two() -> void:
	# Arrange: day three morning, then the gate, then the passage
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY * 2)

	# Act
	flow.perform("go:黑曜石之門")
	var message: String = flow.perform("go:門後通道")

	# Assert
	assert_bool(message.contains("門後是一條幽暗的通道")).is_true()
	assert_bool(message.contains(DAY_TWO_LINE)).is_false()
