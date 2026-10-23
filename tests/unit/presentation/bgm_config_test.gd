extends GdUnitTestSuite
# Unit tests for the BGM config file: every key the rules can return must exist in it.

const CONFIG_PATH: String = "res://assets/data/audio/bgm.json"


func _tracks() -> Dictionary:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return config["tracks"]


func test_every_key_the_rules_can_return_is_configured() -> void:
	var tracks := _tracks()
	var keys: Array[String] = [
		BgmRules.KEY_PROLOGUE, BgmRules.KEY_EXPLORE, BgmRules.KEY_HEART, BgmRules.KEY_BATTLE, BgmRules.KEY_NIGHT,
		"ending_a", "ending_b", "ending_c",
	]

	for key: String in keys:
		assert_bool(tracks.has(key)).is_true()


func test_every_configured_path_is_empty_or_a_res_path() -> void:
	for key: String in _tracks():
		var path: String = str(_tracks()[key])
		assert_bool(path == "" or path.begins_with("res://")).is_true()
