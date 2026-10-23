extends GdUnitTestSuite
# Integration test: a day-one encounter offers puzzle to a party member who has a rune skill.

const ENCOUNTER_PATH: String = "res://assets/data/encounters/day1.json"
const BALANCE_PATH: String = "res://assets/data/rules/balance.json"
const RICHTER_PATH: String = "res://assets/data/characters/richter.json"


func test_rune_seal_encounter_offers_puzzle_to_richter() -> void:
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_PATH))
	var rune_seal: Dictionary = {}
	for entry: Dictionary in encounters["entries"]:
		if entry["id"] == "rune_seal":
			rune_seal = entry
	assert_bool((rune_seal["approaches"] as Array).has("puzzle")).is_true()

	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
	var richter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RICHTER_PATH))
	var puzzle_skills: Array = balance["approach_skills"]["puzzle"]
	var shared: bool = false
	for skill_id: String in richter["skills"]:
		if puzzle_skills.has(skill_id):
			shared = true
	assert_bool(shared).is_true()


func test_day_one_encounter_file_documents_its_fields() -> void:
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_PATH))
	assert_bool(encounters.has("field_notes")).is_true()
