extends GdUnitTestSuite
# Unit tests for the Obsidian Gate mirror trial (manuscript day two: each character
# must confess before the passage opens; order does not matter).


func test_gate_stays_closed_until_all_four_confess() -> void:
	# Arrange
	var trial := MirrorTrial.new()

	# Act
	trial.confess("freya")
	trial.confess("richter")
	trial.confess("inry")

	# Assert
	assert_bool(trial.is_open()).is_false()
	assert_int(trial.remaining().size()).is_equal(1)
	assert_bool(trial.remaining().has("eron")).is_true()


func test_gate_opens_once_every_character_has_confessed() -> void:
	# Arrange
	var trial := MirrorTrial.new()

	# Act
	trial.confess("eron")
	trial.confess("inry")
	trial.confess("richter")
	trial.confess("freya")

	# Assert
	assert_bool(trial.is_open()).is_true()
	assert_int(trial.remaining().size()).is_equal(0)


func test_unknown_character_cannot_confess() -> void:
	# Arrange
	var trial := MirrorTrial.new()

	# Act
	var accepted := trial.confess("nobody")

	# Assert
	assert_bool(accepted).is_false()


func test_same_character_confessing_twice_is_rejected() -> void:
	# Arrange
	var trial := MirrorTrial.new()
	trial.confess("freya")

	# Act
	var second := trial.confess("freya")

	# Assert
	assert_bool(second).is_false()
	assert_int(trial.remaining().size()).is_equal(3)
