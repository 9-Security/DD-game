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


func test_every_story_fight_enemy_is_defined_with_positive_stats() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENEMIES_PATH))
	for id: String in ["stone_flower_beast", "blood_oath_armor", "mirror_freya"]:
		var enemy: Dictionary = data[id]
		assert_int(int(enemy["hp"])).is_greater(0)
		assert_int(int(enemy["atk"])).is_greater(0)
		assert_str(str(enemy["name"])).is_not_empty()


func test_the_balance_file_points_to_defined_story_enemies() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENEMIES_PATH))
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/rules/balance.json"))
	var ids: Array[String] = [str(balance["mirror_counter"]["enemy"])]
	for sequence: Dictionary in balance["sequences"]:
		if sequence.has("battle"):
			ids.append(str(sequence["battle"]["enemy"]))
	for id: String in ids:
		assert_bool(data.has(id)).is_true()
