class_name CharacterData
extends RefCounted
## Validates character definition dictionaries loaded from assets/data/characters/.
## Pure functions only: no file access, so the rules can be unit tested directly.

const REQUIRED_FIELDS: Array[String] = ["id", "identity", "stats", "skills"]

## Optional skills that a character can acquire later (design settings v1.0).
const EXTRA_SKILL_REQUIRED_FIELDS: Array[String] = ["id", "name", "unlock"]
## How an extra skill can be obtained: by reaching a level, or as a side-quest reward.
const UNLOCK_SOURCES: Array[String] = ["level", "quest_reward"]

## Settings skills merged into a starting skill. They record the original description
## and point to the starting skill they were merged into.
const MERGED_SKILL_REQUIRED_FIELDS: Array[String] = ["id", "name", "description", "into"]


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

	_validate_skill_lists(data, errors)
	return errors


## Checks extra_skills and merged_skills, and skill ID uniqueness across all lists.
static func _validate_skill_lists(data: Dictionary, errors: Array[String]) -> void:
	var seen: Dictionary = {}
	var starting: Array = []
	if data.get("skills") is Array:
		starting = data["skills"]
		for skill_id: Variant in starting:
			seen[str(skill_id)] = true

	if data.has("extra_skills"):
		_validate_extra_skills(data["extra_skills"], seen, errors)

	if data.has("merged_skills"):
		_validate_merged_skills(data["merged_skills"], starting, seen, errors)


static func _validate_extra_skills(extra: Variant, seen: Dictionary, errors: Array[String]) -> void:
	if not (extra is Array):
		errors.append("extra_skills must be an array")
		return

	for index: int in range((extra as Array).size()):
		var entry: Variant = extra[index]
		var prefix: String = "extra_skills[%d]" % index
		if not (entry is Dictionary):
			errors.append("%s must be an object" % prefix)
			continue

		for field: String in EXTRA_SKILL_REQUIRED_FIELDS:
			if not entry.has(field):
				errors.append("%s missing field: %s" % [prefix, field])

		if entry.has("unlock") and not _is_valid_unlock(entry["unlock"]):
			errors.append("%s.unlock.sources must contain only: %s" % [prefix, ", ".join(UNLOCK_SOURCES)])

		_register_id(entry, seen, errors)


static func _validate_merged_skills(merged: Variant, starting: Array, seen: Dictionary, errors: Array[String]) -> void:
	if not (merged is Array):
		errors.append("merged_skills must be an array")
		return

	for index: int in range((merged as Array).size()):
		var entry: Variant = merged[index]
		var prefix: String = "merged_skills[%d]" % index
		if not (entry is Dictionary):
			errors.append("%s must be an object" % prefix)
			continue

		for field: String in MERGED_SKILL_REQUIRED_FIELDS:
			if not entry.has(field):
				errors.append("%s missing field: %s" % [prefix, field])

		if entry.has("into") and not starting.has(str(entry["into"])):
			errors.append("%s.into must name a starting skill: %s" % [prefix, str(entry["into"])])

		_register_id(entry, seen, errors)


## Records an entry's id and reports a repeat. Merged entries share the same ID space.
static func _register_id(entry: Dictionary, seen: Dictionary, errors: Array[String]) -> void:
	if not entry.has("id"):
		return
	var skill_id: String = str(entry["id"])
	if seen.has(skill_id):
		errors.append("duplicate skill id: %s" % skill_id)
	seen[skill_id] = true


## An unlock must name at least one known source.
static func _is_valid_unlock(unlock: Variant) -> bool:
	if not (unlock is Dictionary) or not unlock.has("sources"):
		return false
	var sources: Variant = unlock["sources"]
	if not (sources is Array) or (sources as Array).is_empty():
		return false
	for source: Variant in sources:
		if not UNLOCK_SOURCES.has(str(source)):
			return false
	return true
