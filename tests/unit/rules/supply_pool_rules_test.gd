extends GdUnitTestSuite
# Unit tests for the supply pool (herbs and food) used by camp and healing.


func test_new_pool_reports_starting_counts() -> void:
	# Arrange / Act
	var pool := SupplyPool.new(3, 4)

	# Assert
	assert_int(pool.count("herbs")).is_equal(3)
	assert_int(pool.count("food")).is_equal(4)


func test_consume_reduces_count_when_enough_is_available() -> void:
	# Arrange
	var pool := SupplyPool.new(3, 4)

	# Act
	var ok := pool.consume("food", 2)

	# Assert
	assert_bool(ok).is_true()
	assert_int(pool.count("food")).is_equal(2)


func test_consume_fails_without_changing_counts_when_short() -> void:
	# Arrange
	var pool := SupplyPool.new(1, 1)

	# Act
	var ok := pool.consume("herbs", 2)

	# Assert
	assert_bool(ok).is_false()
	assert_int(pool.count("herbs")).is_equal(1)


func test_unknown_kind_is_rejected() -> void:
	# Arrange
	var pool := SupplyPool.new(1, 1)

	# Act / Assert
	assert_bool(pool.add("gold", 5)).is_false()
	assert_bool(pool.consume("gold", 1)).is_false()


func test_add_rejects_non_positive_amounts() -> void:
	# Arrange
	var pool := SupplyPool.new(1, 1)

	# Act / Assert
	assert_bool(pool.add("food", 0)).is_false()
	assert_int(pool.count("food")).is_equal(1)
