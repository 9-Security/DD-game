extends GdUnitTestSuite
# Unit tests for supply-limited rest and night events in the day-one flow.

const FLAVOR: Array = [{"id": "lamp", "text": "燈靈閃爍。", "weight": 1, "outcome": "flavor"}]
const SURE_LOSS: Array = [{
	"id": "ambush", "text": "伏擊。", "weight": 1, "outcome": "battle",
	"enemy_hp": 999, "enemy_def": 0,
	"on_loss": {"food": 1, "herbs": 0, "injury": true},
}]


func _party() -> Array:
	return [{"name": "test-member", "atk": 16}]


func test_rest_is_refused_when_food_is_short_under_strict_rules() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], {"supply": SupplyPool.new(3, 0), "rest_food_cost": 1})

	# Act
	var message := flow.perform("rest")

	# Assert
	assert_bool(message.contains("食糧不足")).is_true()
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_MORNING)
	assert_bool(flow.can_rest()).is_false()


func test_rest_consumes_food_when_available() -> void:
	# Arrange
	var supply := SupplyPool.new(3, 4)
	var flow := DayOneFlow.new(_party(), [0.0], {"supply": supply, "rest_food_cost": 1})

	# Act
	flow.perform("rest")

	# Assert
	assert_int(supply.count("food")).is_equal(3)


func test_assisted_rest_costs_no_food() -> void:
	# Arrange
	var supply := SupplyPool.new(3, 0)
	var flow := DayOneFlow.new(_party(), [0.0], {"supply": supply, "rest_food_cost": 0})

	# Act
	var message := flow.perform("rest")

	# Assert
	assert_bool(message.contains("食糧不足")).is_false()
	assert_int(flow.clock.segment).is_equal(DayClock.SEGMENT_NIGHT)


func test_entering_night_triggers_a_night_event_message() -> void:
	# Arrange
	var flow := DayOneFlow.new(_party(), [0.0], {"night_entries": FLAVOR, "night_rolls": [0.0]})
	flow.perform("move")

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_bool(message.contains("燈靈閃爍。")).is_true()


func test_lost_night_battle_deducts_food_and_reports_injury() -> void:
	# Arrange
	var supply := SupplyPool.new(0, 2)
	var flow := DayOneFlow.new(_party(), [0.0], {"supply": supply, "night_entries": SURE_LOSS, "night_rolls": [0.0]})
	flow.perform("move")

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_int(supply.count("food")).is_equal(1)
	assert_bool(message.contains("受傷")).is_true()


func test_snapshot_round_trips_supply_and_rest_cost() -> void:
	# Arrange
	var source := DayOneFlow.new(_party(), [0.0], {"supply": SupplyPool.new(2, 5), "rest_food_cost": 1})
	source.perform("rest")
	var snapshot := source.snapshot()
	var target_supply := SupplyPool.new(0, 0)
	var target := DayOneFlow.new(_party(), [0.0], {"supply": target_supply, "rest_food_cost": 0})

	# Act
	var restored := target.restore(snapshot)

	# Assert
	assert_bool(restored).is_true()
	assert_int(target_supply.count("food")).is_equal(4)
	assert_int(target_supply.count("herbs")).is_equal(2)
	assert_int(target.rest_food_cost).is_equal(1)
