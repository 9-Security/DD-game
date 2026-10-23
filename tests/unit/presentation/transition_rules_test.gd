extends GdUnitTestSuite
# Unit tests for choosing the transition illustration for a moment in the story.


func test_the_party_moment_shows_the_party_transition() -> void:
	assert_str(TransitionRules.path_for(TransitionRules.KIND_PARTY)).is_equal(TransitionRules.PARTY_PATH)


func test_a_new_day_shows_the_chapter_transition() -> void:
	assert_str(TransitionRules.path_for(TransitionRules.KIND_CHAPTER)).is_equal(TransitionRules.CHAPTER_PATH)


func test_a_journey_shows_the_map_transition() -> void:
	assert_str(TransitionRules.path_for(TransitionRules.KIND_TRAVEL)).is_equal(TransitionRules.TRAVEL_PATH)


func test_a_final_choice_shows_the_critical_choice_transition() -> void:
	assert_str(TransitionRules.path_for(TransitionRules.KIND_CRITICAL)).is_equal(TransitionRules.CRITICAL_PATH)


func test_a_reached_ending_shows_the_ending_transition() -> void:
	assert_str(TransitionRules.path_for(TransitionRules.KIND_ENDING)).is_equal(TransitionRules.ENDING_PATH)


func test_an_unknown_kind_has_no_transition() -> void:
	assert_str(TransitionRules.path_for("unknown")).is_empty()


func test_every_transition_file_exists() -> void:
	for kind: String in TransitionRules.KINDS:
		assert_bool(ResourceLoader.exists(TransitionRules.path_for(kind))).is_true()
