extends GdUnitTestSuite
# Integration test: the save repository writes and reads real files under user://.
# The test file is removed after each case so no state leaks between runs.

const TEST_PATH: String = "user://test_save_integration.json"


func after_test() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_written_snapshot_reads_back_identically() -> void:
	# Arrange
	var snapshot := {"version": 1, "elapsed": 7, "battle_done": true}

	# Act
	var wrote := SaveRepository.write(TEST_PATH, snapshot)
	var loaded: Variant = SaveRepository.read(TEST_PATH)

	# Assert
	assert_bool(wrote).is_true()
	assert_bool(loaded is Dictionary).is_true()
	assert_int(int(loaded["elapsed"])).is_equal(7)
	assert_bool(loaded["battle_done"]).is_true()


func test_reading_a_missing_file_returns_null() -> void:
	# Arrange: no file written at TEST_PATH

	# Act
	var loaded: Variant = SaveRepository.read(TEST_PATH)

	# Assert
	assert_object(loaded).is_null()


func test_reading_a_corrupt_file_returns_null() -> void:
	# Arrange
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()

	# Act
	var loaded: Variant = SaveRepository.read(TEST_PATH)

	# Assert
	assert_object(loaded).is_null()
