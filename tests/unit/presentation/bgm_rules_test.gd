extends GdUnitTestSuite
# Unit tests for choosing the background music key: prologue, ending, the heart of the fallen star, or exploration.


func test_prologue_plays_the_prologue_music() -> void:
	var key := BgmRules.key_for(true, "", "")

	assert_str(key).is_equal("prologue")


func test_exploration_plays_the_explore_music() -> void:
	var key := BgmRules.key_for(false, "", "黑曜石之門")

	assert_str(key).is_equal("explore")


func test_the_heart_of_the_fallen_star_plays_its_own_music() -> void:
	var key := BgmRules.key_for(false, "", "墜星之心")

	assert_str(key).is_equal("heart")


func test_a_reached_ending_plays_the_music_of_that_ending() -> void:
	var key := BgmRules.key_for(false, "END_B", "王宮藥室")

	assert_str(key).is_equal("ending_b")


func test_an_unknown_ending_falls_back_to_exploration_music() -> void:
	var key := BgmRules.key_for(false, "END_X", "王宮藥室")

	assert_str(key).is_equal("explore")
