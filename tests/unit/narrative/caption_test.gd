extends GdUnitTestSuite
# Unit tests for the scene caption: it describes the current place and falls back to the day.

const CAPTIONS_PATH: String = "res://assets/data/narrative/captions.json"


func _captions() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CAPTIONS_PATH))


func test_start_caption_is_used_before_the_party_moves() -> void:
	var captions: Dictionary = _captions()
	assert_str(str(captions.get("start", ""))).contains("星墜之淵外圍")


func test_every_place_with_an_action_has_a_caption() -> void:
	var captions: Dictionary = _captions()
	var places: Dictionary = captions.get("locations", {})
	for place: String in ["黑曜石之門", "門後通道", "咒牆迷廊", "名冊廊廳", "出口門廊", "失聲之庭", "血誓熔窟"]:
		assert_bool(places.has(place)).is_true()
		assert_str(str(places[place])).is_not_empty()
