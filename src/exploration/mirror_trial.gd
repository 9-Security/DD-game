class_name MirrorTrial
extends RefCounted
## Obsidian Gate mirror trial: each party member must confess before the passage
## opens. Confessions can happen in any order; a repeated or unknown confession is refused.
## Content follows the co-designed manuscript (day two, Obsidian Gate).

const REQUIRED_CHARACTERS: Array[String] = ["freya", "richter", "inry", "eron"]

var _confessed: Dictionary = {}


## Records a confession. Returns false for an unknown or repeated character.
func confess(character_id: String) -> bool:
	if not REQUIRED_CHARACTERS.has(character_id):
		return false
	if _confessed.has(character_id):
		return false
	_confessed[character_id] = true
	return true


## True once every required character has confessed.
func is_open() -> bool:
	return remaining().is_empty()


## Characters who have not confessed yet, in the order defined by REQUIRED_CHARACTERS.
func remaining() -> Array[String]:
	var pending: Array[String] = []
	for character_id: String in REQUIRED_CHARACTERS:
		if not _confessed.has(character_id):
			pending.append(character_id)
	return pending
