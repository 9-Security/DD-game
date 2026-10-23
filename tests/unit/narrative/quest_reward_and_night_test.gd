extends GdUnitTestSuite
# Unit tests for the sapling side quest (skill reward) and the night branch of the innkeeper.


func _events() -> Array:
	return [
		{"id": "clue", "trigger": {"action": "explore", "location": "焦林"}, "conditions": [],
			"effects": [{"type": "set_flag", "flag": "saw_convoy", "value": true}]},
		{"id": "sapling_help", "trigger": {"action": "help:sapling", "location": "焦林"},
			"conditions": [{"flag": "saw_convoy", "equals": true}],
			"effects": [
				{"type": "unlock_skill", "character": "eron", "skill": "spirit_link"},
				{"type": "message", "text": "幼樹重新長出葉子。"},
			]},
		{"id": "innkeeper_day", "trigger": {"action": "talk:innkeeper", "is_night": false}, "conditions": [],
			"effects": [{"type": "message", "text": "鐘聲的故事。"}]},
		{"id": "innkeeper_night", "trigger": {"action": "talk:innkeeper", "is_night": true}, "conditions": [],
			"effects": [{"type": "message", "text": "別在天黑後說那個名字。"}]},
	]


func _flow() -> DayOneFlow:
	return DayOneFlow.new([{"id": "eron", "name": "e", "atk": 10}], [0.0], {"events": _events()})


func test_helping_the_sapling_grants_the_skill_as_a_quest_reward() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:焦林")
	flow.perform("explore")

	# Act
	var message := flow.perform("help:sapling")

	# Assert
	assert_bool(message.contains("幼樹重新長出葉子。")).is_true()
	assert_bool(flow.acquired_skills("eron").has("spirit_link")).is_true()


func test_sapling_help_is_unavailable_before_the_clue() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:焦林")

	# Act
	flow.perform("help:sapling")

	# Assert
	assert_int(flow.acquired_skills("eron").size()).is_equal(0)


func test_sapling_reward_is_granted_only_once() -> void:
	# Arrange
	var flow := _flow()
	flow.perform("go:焦林")
	flow.perform("explore")
	flow.perform("help:sapling")

	# Act
	var second := flow.perform("help:sapling")

	# Assert
	assert_bool(second.contains("幼樹重新長出葉子。")).is_false()


func test_acquired_skills_survive_a_snapshot_round_trip() -> void:
	# Arrange
	var source := _flow()
	source.perform("go:焦林")
	source.perform("explore")
	source.perform("help:sapling")
	var snapshot := source.snapshot()
	var target := _flow()

	# Act
	var restored := target.restore(snapshot)

	# Assert
	assert_bool(restored).is_true()
	assert_bool(target.acquired_skills("eron").has("spirit_link")).is_true()


func test_innkeeper_answers_by_day_and_refuses_by_night() -> void:
	# Arrange
	var flow := _flow()

	# Act
	var day := flow.perform("talk:innkeeper")
	flow.perform("rest")
	var night := flow.perform("talk:innkeeper")

	# Assert
	assert_bool(day.contains("鐘聲的故事。")).is_true()
	assert_bool(night.contains("別在天黑後說那個名字。")).is_true()
