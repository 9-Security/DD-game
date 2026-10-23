extends GdUnitTestSuite
# Unit tests for Freya's blood curse (design/GAME_DESIGN_MASTER.md section 3.2).


func test_new_curse_has_no_stacks() -> void:
	# Arrange
	var curse := BloodCurse.new()

	# Act
	# (no action: checking the initial state)

	# Assert
	assert_int(curse.stacks).is_equal(0)
	assert_bool(curse.is_berserk()).is_false()


func test_each_stack_reduces_max_hp_by_five_percent() -> void:
	# Arrange
	var curse := BloodCurse.new()

	# Act
	curse.add_stack()
	curse.add_stack()

	# Assert
	assert_float(curse.max_hp_multiplier()).is_equal_approx(0.90, 0.0001)


func test_each_stack_adds_two_percent_loss_of_control_chance() -> void:
	# Arrange
	var curse := BloodCurse.new()

	# Act
	curse.add_stack()
	curse.add_stack()
	curse.add_stack()

	# Assert
	assert_float(curse.loss_of_control_chance()).is_equal_approx(0.06, 0.0001)


func test_stacks_are_capped_at_five() -> void:
	# Arrange
	var curse := BloodCurse.new()

	# Act
	for index: int in range(8):
		curse.add_stack()

	# Assert
	assert_int(curse.stacks).is_equal(BloodCurse.MAX_STACKS)


func test_fifth_stack_triggers_one_turn_of_berserk_and_clears_stacks() -> void:
	# Arrange
	var curse := BloodCurse.new()
	for index: int in range(4):
		curse.add_stack()

	# Act
	curse.add_stack()
	var triggered := curse.consume_full_curse()

	# Assert
	assert_bool(triggered).is_true()
	assert_int(curse.stacks).is_equal(0)


func test_four_stacks_do_not_trigger_berserk() -> void:
	# Arrange
	var curse := BloodCurse.new()
	for index: int in range(4):
		curse.add_stack()

	# Act
	var triggered := curse.consume_full_curse()

	# Assert
	assert_bool(triggered).is_false()
	assert_int(curse.stacks).is_equal(4)


func test_purify_clears_all_stacks() -> void:
	# Arrange
	var curse := BloodCurse.new()
	curse.add_stack()
	curse.add_stack()

	# Act
	curse.purify()

	# Assert
	assert_int(curse.stacks).is_equal(0)
	assert_float(curse.max_hp_multiplier()).is_equal_approx(1.0, 0.0001)
