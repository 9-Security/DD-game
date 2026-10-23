extends GdUnitTestSuite
# Unit tests for weakening the blood curse. Weakening removes stacks but never cures the curse
# outright, so the stack count stays at zero or above.

func test_weaken_removes_the_given_number_of_stacks() -> void:
	var curse := BloodCurse.new()
	for index: int in range(3):
		curse.add_stack()

	curse.weaken(2)

	assert_int(curse.stacks).is_equal(1)


func test_weaken_never_goes_below_zero() -> void:
	var curse := BloodCurse.new()
	curse.add_stack()

	curse.weaken(5)

	assert_int(curse.stacks).is_equal(0)
