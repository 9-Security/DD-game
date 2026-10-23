extends GdUnitTestSuite
# Unit tests for the three save slots: each slot has its own file, and only slots one to three exist.


func test_each_valid_slot_has_its_own_save_file() -> void:
	var first := SaveRepository.slot_path(1)
	var second := SaveRepository.slot_path(2)
	var third := SaveRepository.slot_path(3)

	assert_str(first).is_equal("user://save_slot_1.json")
	assert_str(second).is_equal("user://save_slot_2.json")
	assert_str(third).is_equal("user://save_slot_3.json")


func test_slot_zero_and_slot_four_are_not_valid_save_slots() -> void:
	assert_bool(SaveRepository.is_valid_slot(0)).is_false()
	assert_bool(SaveRepository.is_valid_slot(4)).is_false()


func test_an_invalid_slot_has_no_save_file_path() -> void:
	assert_str(SaveRepository.slot_path(4)).is_empty()


func test_the_slot_count_is_three() -> void:
	assert_int(SaveRepository.SLOT_COUNT).is_equal(3)
