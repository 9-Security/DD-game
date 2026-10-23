class_name CharacterData
extends RefCounted
## Validates character definition dictionaries loaded from assets/data/characters/.
## Pure functions only: no file access, so the rules can be unit tested directly.

const REQUIRED_FIELDS: Array[String] = ["id", "identity", "stats", "skills"]


## Returns a list of human-readable validation errors. An empty list means valid.
static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []

	for field: String in REQUIRED_FIELDS:
		if not data.has(field):
			errors.append("missing field: %s" % field)

	if data.has("stats") and data["stats"] is Dictionary:
		var stats: Dictionary = data["stats"]
		var hp: Variant = stats.get("hp", 0)
		if not (hp is int or hp is float) or hp <= 0:
			errors.append("stats.hp must be greater than 0")

	if data.has("skills"):
		if not (data["skills"] is Array) or (data["skills"] as Array).is_empty():
			errors.append("skills must contain at least one entry")

	return errors
