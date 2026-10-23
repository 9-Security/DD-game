extends GdUnitTestSuite
# Unit tests for choosing the full-screen backdrop: prologue, the chapter of the current day, or an ending.


func test_prologue_shows_the_prologue_illustration() -> void:
	var path := BackdropRules.path_for(true, 1, "")

	assert_str(path).is_equal(BackdropRules.PROLOGUE_PATH)


func test_day_one_shows_the_first_chapter_illustration() -> void:
	var path := BackdropRules.path_for(false, 1, "")

	assert_str(path).is_equal(BackdropRules.CHAPTER_PATHS[0])


func test_day_seven_shows_the_seventh_chapter_illustration() -> void:
	var path := BackdropRules.path_for(false, 7, "")

	assert_str(path).is_equal(BackdropRules.CHAPTER_PATHS[6])


func test_a_reached_ending_overrides_the_day_illustration() -> void:
	var ending_path := "res://assets/art/chapters/ending_b.png"

	var path := BackdropRules.path_for(false, 7, ending_path)

	assert_str(path).is_equal(ending_path)


func test_an_out_of_range_day_falls_back_to_the_first_chapter() -> void:
	var path := BackdropRules.path_for(false, 0, "")

	assert_str(path).is_equal(BackdropRules.CHAPTER_PATHS[0])
