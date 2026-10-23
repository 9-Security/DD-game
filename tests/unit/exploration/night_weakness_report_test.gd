extends GdUnitTestSuite
# Unit test: a night battle reports weakness hits like the other fights do.

const AFFINITY: Dictionary = {
	"weak_multiplier": 1.5,
	"resist_multiplier": 0.5,
	"matchups": {"purify": {"weak": ["restless_spirit"], "resist": []}},
}


func test_night_battle_reports_weakness_hits() -> void:
	# Arrange: the party's only member attacks with purify against a restless spirit
	var party: Array = [{"id": "eron", "name": "e", "atk": 10}]
	var entries: Array = [{
		"id": "ambush", "text": "伏擊。", "weight": 1, "outcome": "battle",
		"enemy_hp": 999, "enemy_def": 0, "enemy_tags": ["restless_spirit"],
		"on_loss": {"food": 0, "herbs": 0, "injury": false},
	}]
	var flow := DayOneFlow.new(party, [0.0], {
		"night_entries": entries,
		"night_rolls": [0.0],
		"attack_tags": {"eron": "purify"},
		"affinity": AFFINITY,
	})
	flow.perform("move")

	# Act
	var message := flow.perform("explore")

	# Assert
	assert_bool(message.contains("弱點命中")).is_true()
