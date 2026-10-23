extends GdUnitTestSuite
# Unit tests for the background music player: a missing or empty track must never stop the game.


func test_a_track_with_no_file_plays_nothing_and_does_not_fail() -> void:
	var player: BgmPlayer = auto_free(BgmPlayer.new())
	player.setup({"explore": ""}, -8.0)

	player.play_key("explore")

	assert_bool(player.is_playing()).is_false()


func test_a_key_missing_from_the_config_plays_nothing_and_does_not_fail() -> void:
	var player: BgmPlayer = auto_free(BgmPlayer.new())
	player.setup({}, -8.0)

	player.play_key("heart")

	assert_bool(player.is_playing()).is_false()


func test_a_path_that_does_not_exist_plays_nothing_and_does_not_fail() -> void:
	var player: BgmPlayer = auto_free(BgmPlayer.new())
	player.setup({"explore": "res://assets/audio/bgm/missing.ogg"}, -8.0)

	player.play_key("explore")

	assert_bool(player.is_playing()).is_false()
