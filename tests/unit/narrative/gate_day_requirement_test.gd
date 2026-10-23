extends GdUnitTestSuite
# Unit tests for day-based entry requirements: the Obsidian Gate is reached on day two, so the
# first day must be spent before the party can travel there.

const BLOCKED_TEXT: String = "今日無法抵達黑曜石之門，等到第二日再出發。"
const REQUIREMENTS: Dictionary = {
	"黑曜石之門": {"min_day": 2, "blocked_text": BLOCKED_TEXT},
}


func _flow() -> DayOneFlow:
	return DayOneFlow.new([{"id": "eron", "name": "e", "atk": 10}], [0.0], {
		"location_requirements": REQUIREMENTS,
	})


func test_gate_is_refused_on_day_one_without_spending_time() -> void:
	# Arrange
	var flow := _flow()
	var before: int = flow.clock.get_elapsed()

	# Act
	var message: String = flow.perform("go:黑曜石之門")

	# Assert
	assert_str(message).is_equal(BLOCKED_TEXT)
	assert_str(flow.location()).is_empty()
	assert_int(flow.clock.get_elapsed()).is_equal(before)


func test_gate_is_reachable_once_day_two_begins() -> void:
	# Arrange: spend the whole first day
	var flow := _flow()
	flow.clock.spend(DayClock.SEGMENTS_PER_DAY)

	# Act
	flow.perform("go:黑曜石之門")

	# Assert
	assert_int(flow.clock.day).is_equal(2)
	assert_str(flow.location()).is_equal("黑曜石之門")


func test_places_without_a_day_requirement_stay_open_on_day_one() -> void:
	# Arrange
	var flow := _flow()

	# Act
	flow.perform("go:焦林")

	# Assert
	assert_str(flow.location()).is_equal("焦林")
