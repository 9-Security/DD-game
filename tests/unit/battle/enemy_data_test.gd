extends GdUnitTestSuite
# Unit tests for the enemy data file: the tutorial enemy must agree with the day flow's constants.

const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"


func _tutorial() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENEMIES_PATH))
	return data["tutorial"]


func test_the_tutorial_enemy_has_the_same_hp_and_defense_as_the_day_flow() -> void:
	var enemy := _tutorial()

	assert_int(int(enemy["hp"])).is_equal(DayOneFlow.TUTORIAL_ENEMY_HP)
	assert_int(int(enemy["def"])).is_equal(DayOneFlow.TUTORIAL_ENEMY_DEF)


func test_the_tutorial_enemy_has_a_positive_attack_and_a_name() -> void:
	var enemy := _tutorial()

	assert_int(int(enemy["atk"])).is_greater(0)
	assert_str(str(enemy["name"])).is_not_empty()
