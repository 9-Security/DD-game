extends GdUnitTestSuite
# Unit tests for choosing the portrait shown for a dialogue speaker. Narration has no portrait.


func test_a_named_character_shows_their_portrait() -> void:
	assert_str(PortraitRules.path_for_speaker("里克特")).is_equal("res://assets/art/portraits/portrait_richter.png")


func test_the_king_shows_the_king_portrait() -> void:
	assert_str(PortraitRules.path_for_speaker("國王")).is_equal("res://assets/art/portraits/portrait_king.png")


func test_narration_shows_no_portrait() -> void:
	assert_str(PortraitRules.path_for_speaker("旁白")).is_empty()


func test_an_unknown_speaker_shows_no_portrait() -> void:
	assert_str(PortraitRules.path_for_speaker("路人")).is_empty()


func test_every_portrait_the_rules_name_exists() -> void:
	for speaker: String in PortraitRules.SPEAKERS:
		assert_bool(ResourceLoader.exists(PortraitRules.path_for_speaker(speaker))).is_true()
