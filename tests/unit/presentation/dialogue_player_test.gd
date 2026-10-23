extends GdUnitTestSuite
# Unit tests for DialoguePlayer: validation of dialogue data, scene lookup by action, and line sequencing.


func _scene(id: String, action: String, lines: Array) -> Dictionary:
	return {"id": id, "action": action, "requires_flag": "test_flag", "source_ref": "test", "lines": lines}


func _line(speaker: String, text: String) -> Dictionary:
	return {"speaker": speaker, "text": text}


func _data(scenes: Array) -> Dictionary:
	return {"scenes": scenes}


func test_valid_data_has_no_errors() -> void:
	var data := _data([_scene("s1", "confess:eron", [_line("艾洛恩", "我想拯救所有生命。")])])

	var errors := DialoguePlayer.validate(data)

	assert_int(errors.size()).is_equal(0)


func test_unknown_speaker_is_reported() -> void:
	var data := _data([_scene("s1", "confess:eron", [_line("路人甲", "你好。")])])

	var errors := DialoguePlayer.validate(data)

	assert_int(errors.size()).is_equal(1)


func test_scene_without_required_flag_is_reported() -> void:
	var scene := _scene("s1", "confess:eron", [_line("艾洛恩", "一句話。")])
	scene.erase("requires_flag")

	var errors := DialoguePlayer.validate(_data([scene]))

	assert_int(errors.size()).is_equal(1)


func test_required_flag_is_returned_for_a_loaded_scene() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_data([_scene("s1", "confess:eron", [_line("艾洛恩", "一句話。")])]))

	assert_str(player.required_flag("s1")).is_equal("test_flag")


func test_narrator_line_needs_no_portrait() -> void:
	var data := _data([_scene("s1", "go:門後通道", [_line(DialoguePlayer.NARRATOR, "門開了。")])])

	var errors := DialoguePlayer.validate(data)

	assert_int(errors.size()).is_equal(0)


func test_line_over_limit_is_reported() -> void:
	var long_text := "字".repeat(DialoguePlayer.MAX_LINE_LENGTH + 1)
	var data := _data([_scene("s1", "confess:eron", [_line("艾洛恩", long_text)])])

	var errors := DialoguePlayer.validate(data)

	assert_int(errors.size()).is_equal(1)


func test_duplicate_scene_id_is_reported() -> void:
	var line := [_line("艾洛恩", "一句話。")]
	var data := _data([_scene("s1", "confess:eron", line), _scene("s1", "confess:freya", line)])

	var errors := DialoguePlayer.validate(data)

	assert_int(errors.size()).is_equal(1)


func test_scene_without_lines_is_reported() -> void:
	var data := _data([_scene("s1", "confess:eron", [])])

	var errors := DialoguePlayer.validate(data)

	assert_int(errors.size()).is_equal(1)


func test_invalid_data_loads_no_scene() -> void:
	var player := DialoguePlayer.new()
	var data := _data([_scene("s1", "confess:eron", [_line("路人甲", "你好。")])])

	var errors := player.load_data(data)

	assert_int(errors.size()).is_equal(1)
	assert_str(player.scene_for_action("confess:eron")).is_equal("")


func test_action_maps_to_its_scene_id() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_data([_scene("s1", "confess:eron", [_line("艾洛恩", "一句話。")])]))

	assert_str(player.scene_for_action("confess:eron")).is_equal("s1")


func test_unknown_action_has_no_scene() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_data([_scene("s1", "confess:eron", [_line("艾洛恩", "一句話。")])]))

	assert_str(player.scene_for_action("confess:freya")).is_equal("")


func test_start_shows_the_first_line() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_data([_scene("s1", "confess:eron", [_line("艾洛恩", "第一句。"), _line("艾洛恩", "第二句。")])]))

	var started := player.start("s1")

	assert_bool(started).is_true()
	assert_str(player.current_line()["text"]).is_equal("第一句。")


func test_advance_moves_through_lines_then_ends_the_scene() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_data([_scene("s1", "confess:eron", [_line("艾洛恩", "第一句。"), _line("艾洛恩", "第二句。")])]))
	player.start("s1")

	var has_more := player.advance()
	assert_bool(has_more).is_true()
	assert_str(player.current_line()["text"]).is_equal("第二句。")

	var ended := player.advance()
	assert_bool(ended).is_false()
	assert_bool(player.is_active()).is_false()


func test_start_unknown_scene_returns_false() -> void:
	var player := DialoguePlayer.new()

	assert_bool(player.start("missing")).is_false()
	assert_bool(player.is_active()).is_false()


func test_cancel_stops_an_active_scene() -> void:
	var player := DialoguePlayer.new()
	player.load_data(_data([_scene("s1", "confess:eron", [_line("艾洛恩", "第一句。"), _line("艾洛恩", "第二句。")])]))
	player.start("s1")

	player.cancel()

	assert_bool(player.is_active()).is_false()
	assert_dict(player.current_line()).is_empty()
