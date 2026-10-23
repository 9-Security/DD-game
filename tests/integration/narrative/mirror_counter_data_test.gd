extends GdUnitTestSuite
# Integration test: balance data defines the mirror counterattack values.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"


func test_balance_defines_the_mirror_counterattack() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var counter: Dictionary = parsed.get("mirror_counter", {})
	assert_int(int(counter.get("damage", -1))).is_greater_equal(0)
	assert_int(int(counter.get("curse_stacks", -1))).is_greater_equal(0)
