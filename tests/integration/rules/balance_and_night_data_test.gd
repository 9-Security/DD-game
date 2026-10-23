extends GdUnitTestSuite
# Integration test: the shipped rule and event data files parse and validate.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const NIGHT_PATH: String = "res://assets/data/events/night_pool.json"


func test_balance_file_parses_and_validates() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	assert_bool(parsed is Dictionary).is_true()
	assert_int(GameRules.validate(parsed).size()).is_equal(0)


func test_night_pool_file_parses_and_validates() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(NIGHT_PATH))
	assert_bool(parsed is Dictionary).is_true()
	assert_int(NightEventPool.validate(parsed["entries"]).size()).is_equal(0)
