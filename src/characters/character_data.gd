class_name CharacterData
extends RefCounted
## Validates character definition dictionaries loaded from assets/data/characters/.
## Pure functions only: no file access, so the rules can be unit tested directly.

const REQUIRED_FIELDS: Array[String] = ["id", "identity", "stats", "skills"]

## Optional skills kept for later upgrades or acquisition (design settings v1.0).
const EXTRA_SKILL_REQUIRED_FIELDS: Array[String] = ["id", "name", "unlock"]
## "unassigned" means the unlock condition has not been decided yet.
const UNLOCK_TYPES: Array[String] = ["level", "story_flag", "upgrade", "unassigned"]


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

	if data.has("extra_skills"):
		_validate_extra_skills(data, errors)

	return errors


## Checks the optional extra_skills block and skill ID uniqueness across both lists.
static func _validate_extra_skills(data: Dictionary, errors: Array[String]) -> void:
	if not (data["extra_skills"] is Array):
		errors.append("extra_skills must be an array")
		return

	var seen: Dictionary = {}
	if data.get("skills") is Array:
		for skill_id: Variant in data["skills"]:
			seen[str(skill_id)] = true

	var extra: Array = data["extra_skills"]
	for index: int in range(extra.size()):
		var entry: Variant = extra[index]
		var prefix: String = "extra_skills[%d]" % index
		if not (entry is Dictionary):
			errors.append("%s must be an object" % prefix)
			continue

		for field: String in EXTRA_SKILL_REQUIRED_FIELDS:
			if not entry.has(field):
				errors.append("%s missing field: %s" % [prefix, field])

		if entry.has("unlock"):
			var unlock: Variant = entry["unlock"]
			if not (unlock is Dictionary) or not UNLOCK_TYPES.has(str(unlock.get("type", ""))):
				errors.append("%s.unlock.type must be one of: %s" % [prefix, ", ".join(UNLOCK_TYPES)])

		if entry.has("id"):
			var skill_id: String = str(entry["id"])
			if seen.has(skill_id):
				errors.append("duplicate skill id: %s" % skill_id)
			seen[skill_id] = true
