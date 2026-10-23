extends GdUnitTestSuite
# Unit tests for launch parameters: a web page passes them in its URL, and they become the same
# option strings the desktop build reads from the command line.


func test_skip_and_difficulty_become_the_desktop_options() -> void:
	var options: PackedStringArray = LaunchOptions.from_query("?skip=1&difficulty=assisted")

	assert_array(Array(options)).contains_exactly(["--skip-prologue", "--difficulty=assisted"])


func test_demo_actions_are_split_and_keep_their_order() -> void:
	var options: PackedStringArray = LaunchOptions.from_query("?demo=move,go:黑曜石之門,confess:eron")

	assert_array(Array(options)).contains_exactly([
		"--demo-action=move",
		"--demo-action=go:黑曜石之門",
		"--demo-action=confess:eron",
	])


func test_percent_encoded_values_are_decoded() -> void:
	var query: String = "?demo=go%3A%E9%BB%91%E6%9B%9C%E7%9F%B3%E4%B9%8B%E9%96%80%2Cmove"

	var options: PackedStringArray = LaunchOptions.from_query(query)

	assert_array(Array(options)).contains_exactly(["--demo-action=go:黑曜石之門", "--demo-action=move"])


func test_an_empty_query_gives_no_options() -> void:
	assert_array(Array(LaunchOptions.from_query(""))).is_empty()
