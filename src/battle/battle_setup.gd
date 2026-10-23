class_name BattleSetup
extends RefCounted
## Builds battle members for TurnBattle from character data dictionaries (assets/data/characters/).
## Pure functions only, so the mapping can be unit tested without file access.


## Returns one party member for TurnBattle. character: the parsed character file.
## skill_id: the skill this member uses in battle.
static func party_member(character: Dictionary, skill_id: String) -> Dictionary:
	var stats: Dictionary = character.get("stats", {})
	var identity: Dictionary = character.get("identity", {})
	var hp: int = int(stats.get("hp", 1))
	return {
		"id": str(character.get("id", "")),
		"name": str(identity.get("name", character.get("id", ""))),
		"hp": hp,
		"max_hp": hp,
		"mp": int(stats.get("mp", 0)),
		"atk": int(stats.get("atk", 0)),
		"def": int(stats.get("def", 0)),
		"speed": int(stats.get("spd", 0)),
		"skill": skill_id,
	}
