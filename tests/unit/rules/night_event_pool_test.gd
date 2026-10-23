extends GdUnitTestSuite
# Unit tests for the night event pool: weighted selection and battle-loss consequences.

const ENTRIES: Array = [
	{"id": "lamp", "weight": 1, "outcome": "flavor"},
	{"id": "ghost", "weight": 3, "outcome": "battle", "on_loss": {"food": 1, "herbs": 1, "injury": true}},
]


func test_low_roll_picks_the_first_entry() -> void:
	# Arrange / Act
	var entry := NightEventPool.pick(ENTRIES, 0.10)

	# Assert
	assert_str(entry["id"]).is_equal("lamp")


func test_roll_past_first_weight_picks_the_heavier_entry() -> void:
	# Arrange / Act: weights are 1 and 3, so 0.5 falls in the second band
	var entry := NightEventPool.pick(ENTRIES, 0.50)

	# Assert
	assert_str(entry["id"]).is_equal("ghost")


func test_empty_pool_returns_empty_dictionary() -> void:
	# Arrange / Act
	var entry := NightEventPool.pick([], 0.5)

	# Assert
	assert_int(entry.size()).is_equal(0)


func test_battle_loss_deducts_supply_but_never_below_zero() -> void:
	# Arrange
	var pool := SupplyPool.new(0, 1)
	var entry: Dictionary = ENTRIES[1]

	# Act
	var injured := NightEventPool.resolve_loss(entry, pool)

	# Assert
	assert_bool(injured).is_true()
	assert_int(pool.count("food")).is_equal(0)
	assert_int(pool.count("herbs")).is_equal(0)


func test_validation_rejects_zero_weight_and_unknown_outcome() -> void:
	# Arrange
	var bad: Array = [
		{"id": "a", "weight": 0, "outcome": "flavor"},
		{"id": "b", "weight": 1, "outcome": "teleport"},
	]

	# Act
	var errors := NightEventPool.validate(bad)

	# Assert
	assert_int(errors.size()).is_equal(2)
