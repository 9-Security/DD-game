extends GdUnitTestSuite
# Integration test: the button labels and title live in ui_labels.json. Every story button must
# name a real action at its place, so a label cannot point at an action the rules do not offer.

const LABELS_PATH: String = "res://assets/data/narrative/ui_labels.json"
const BALANCE_PATH: String = "res://assets/data/rules/balance.json"


func _labels() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(LABELS_PATH))


func test_labels_file_has_the_title_and_every_button_group() -> void:
	var labels: Dictionary = _labels()
	assert_str(str(labels.get("title", ""))).is_not_empty()
	assert_array(labels.get("narrative_actions", [])).is_not_empty()
	assert_array(labels.get("gate_actions", [])).is_not_empty()
	assert_array(labels.get("story_actions", [])).is_not_empty()
	assert_int((labels.get("passage_action", []) as Array).size()).is_equal(2)


func test_every_story_button_matches_a_location_action_or_a_destination() -> void:
	var labels: Dictionary = _labels()
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var location_actions: Dictionary = balance["location_actions"]
	for entry: Array in labels["story_actions"]:
		var action: String = str(entry[0])
		var place: String = str(entry[2])
		assert_str(str(entry[1])).is_not_empty()
		if action.begins_with("go:"):
			assert_bool(action.trim_prefix("go:") != "").is_true()
		else:
			assert_bool((location_actions.get(place, []) as Array).has(action)).is_true()
