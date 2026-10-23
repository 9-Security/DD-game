extends GdUnitTestSuite
# Integration test: every ending shown on the ending panel has an illustration that exists and loads.
# The paths live as a constant on the prototype scene script, so the test reads them from there.

const SCENE_SCRIPT_PATH: String = "res://src/scenes/prototype_main.gd"
const ENDING_IDS: Array[String] = ["END_A", "END_B", "END_C"]


func _art_paths() -> Dictionary:
	var script: Script = load(SCENE_SCRIPT_PATH)
	return script.get_script_constant_map()["ENDING_ART_PATHS"]


func test_every_ending_has_an_art_path() -> void:
	var paths: Dictionary = _art_paths()

	for ending_id: String in ENDING_IDS:
		assert_bool(paths.has(ending_id)).is_true()


func test_every_ending_art_file_exists_and_loads_as_a_texture() -> void:
	var paths: Dictionary = _art_paths()

	for ending_id: String in ENDING_IDS:
		var path: String = str(paths[ending_id])
		assert_bool(ResourceLoader.exists(path)).is_true()
		assert_object(load(path) as Texture2D).is_not_null()
