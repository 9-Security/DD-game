extends GdUnitTestSuite
# Integration test: balance data carries attack tags and the battle trust reward.

const BALANCE_PATH: String = "res://assets/data/rules/balance.json"


func test_balance_defines_attack_tags_for_each_party_member() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var tags: Dictionary = parsed.get("attack_tags", {})
	for character_id: String in ["eron", "freya", "richter", "inry"]:
		assert_bool(tags.has(character_id)).is_true()


func test_balance_defines_a_battle_trust_reward() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	assert_int(int(parsed["trust"]["battle_victory_gain"])).is_equal(10)
