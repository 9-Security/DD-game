extends GdUnitTestSuite
# Unit tests for attack-tag weakness and resistance (enemy tags vs attack tags).

const TABLE: Dictionary = {
	"weak_multiplier": 1.5,
	"resist_multiplier": 0.5,
	"matchups": {
		"light": {"weak": ["ancient_construct"], "resist": []},
		"rune": {"weak": [], "resist": ["ancient_construct"]},
		"purify": {"weak": ["restless_spirit"], "resist": []},
	},
}


func test_weak_match_multiplies_damage() -> void:
	# Arrange / Act
	var m := Affinity.multiplier("light", ["ancient_construct"], TABLE)

	# Assert
	assert_float(m).is_equal_approx(1.5, 0.0001)


func test_resist_match_reduces_damage() -> void:
	# Arrange / Act
	var m := Affinity.multiplier("rune", ["ancient_construct"], TABLE)

	# Assert
	assert_float(m).is_equal_approx(0.5, 0.0001)


func test_no_matching_tag_is_neutral() -> void:
	# Arrange / Act
	var m := Affinity.multiplier("purify", ["ancient_construct"], TABLE)

	# Assert
	assert_float(m).is_equal_approx(1.0, 0.0001)


func test_unknown_attack_tag_is_neutral() -> void:
	# Arrange / Act
	var m := Affinity.multiplier("fire", ["ancient_construct"], TABLE)

	# Assert
	assert_float(m).is_equal_approx(1.0, 0.0001)


func test_weak_and_resist_at_once_cancel_to_neutral() -> void:
	# Arrange: an attack that is weak against one tag and resisted by another
	var table := TABLE.duplicate(true)
	table["matchups"]["light"]["resist"] = ["ancient_construct"]

	# Act
	var m := Affinity.multiplier("light", ["ancient_construct"], table)

	# Assert
	assert_float(m).is_equal_approx(1.0, 0.0001)
