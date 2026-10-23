extends GdUnitTestSuite
# Unit tests for enemy sprites: every enemy that names a sprite must name a file that exists.

const ENEMIES_PATH: String = "res://assets/data/battle/enemies.json"
const ENCOUNTERS_PATH: String = "res://assets/data/encounters/day1.json"


func test_every_battle_enemy_that_names_a_sprite_has_that_file() -> void:
	var enemies: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENEMIES_PATH))
	var named: int = 0
	for key: String in enemies:
		if key == "source":
			continue
		var enemy: Dictionary = enemies[key]
		if enemy.has("sprite"):
			named += 1
			assert_bool(ResourceLoader.exists(str(enemy["sprite"]))).is_true()
	assert_int(named).is_greater(0)


func test_every_encounter_enemy_that_names_a_sprite_has_that_file() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTERS_PATH))
	for entry: Dictionary in data["entries"]:
		if entry.has("sprite"):
			assert_bool(ResourceLoader.exists(str(entry["sprite"]))).is_true()
