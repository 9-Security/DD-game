class_name EventRunner
extends RefCounted
## Runs narrative events. An event fires once when its trigger matches the context and
## every condition holds. Effects set flags, produce log messages, or return trust changes
## for the caller to apply, so this class does not depend on the trust board.
##
## Trigger: {"action": String} with optional "location", "is_night", "day" (exact day number)
## and "min_day" (that day or later), and/or {"night_entered": true}, or {"location": String}
## alone to match any action there.
## Conditions: [{"flag": String, "equals": bool}] (equals defaults to true).
## Effects: {"type": "set_flag", "flag", "value"}, {"type": "message", "text"},
##          {"type": "trust", "character", "delta"}.

const EFFECT_TYPES: Array[String] = ["set_flag", "message", "trust", "unlock_skill"]

## Story flags. Keys are flag names, values are bools.
var flags: Dictionary = {}

var _events: Array = []
var _fired: Dictionary = {}


func _init(events: Array, initial_flags: Dictionary) -> void:
	_events = events
	flags = initial_flags.duplicate()


## Returns human-readable errors for one event. An empty list means valid.
static func validate(event: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(event.get("id", "")) == "":
		errors.append("id is required")

	var trigger: Variant = event.get("trigger", {})
	var has_action: bool = trigger is Dictionary and str(trigger.get("action", "")) != ""
	var has_night: bool = trigger is Dictionary and bool(trigger.get("night_entered", false))
	var has_location: bool = trigger is Dictionary and str(trigger.get("location", "")) != ""
	if not has_action and not has_night and not has_location:
		errors.append("trigger must name an action or night_entered")
	if trigger is Dictionary:
		for key: String in ["day", "min_day"]:
			if trigger.has(key) and not (trigger[key] is int or trigger[key] is float):
				errors.append("trigger.%s must be a number" % key)

	for condition: Variant in event.get("conditions", []):
		if not (condition is Dictionary) or not condition.has("flag"):
			errors.append("each condition needs a flag")

	var effects: Variant = event.get("effects", [])
	if not (effects is Array):
		errors.append("effects must be an array")
		return errors
	for index: int in range((effects as Array).size()):
		var effect: Variant = effects[index]
		var prefix: String = "effects[%d]" % index
		if not (effect is Dictionary) or not EFFECT_TYPES.has(str(effect.get("type", ""))):
			errors.append("%s.type must be one of: %s" % [prefix, ", ".join(EFFECT_TYPES)])
			continue
		match str(effect["type"]):
			"set_flag":
				if not effect.has("flag"):
					errors.append("%s needs a flag" % prefix)
			"message":
				if not effect.has("text"):
					errors.append("%s needs text" % prefix)
			"trust":
				if not effect.has("character") or not effect.has("delta"):
					errors.append("%s needs character and delta" % prefix)
			"unlock_skill":
				if not effect.has("character") or not effect.has("skill"):
					errors.append("%s needs character and skill" % prefix)
	return errors


## Checks the context against every unfired event. Returns
## {"messages": Array[String], "trust_changes": Array[Dictionary]}.
func evaluate(context: Dictionary) -> Dictionary:
	var messages: Array[String] = []
	var trust_changes: Array[Dictionary] = []
	var skill_unlocks: Array[Dictionary] = []

	for event: Dictionary in _events:
		var id: String = str(event.get("id", ""))
		if _fired.has(id):
			continue
		if not _trigger_matches(event.get("trigger", {}), context):
			continue
		if not _conditions_hold(event.get("conditions", [])):
			continue

		_fired[id] = true
		for effect: Dictionary in event.get("effects", []):
			match str(effect.get("type", "")):
				"set_flag":
					flags[str(effect["flag"])] = bool(effect.get("value", true))
				"message":
					messages.append(str(effect["text"]))
				"trust":
					trust_changes.append({"character": str(effect["character"]), "delta": int(effect["delta"])})
				"unlock_skill":
					skill_unlocks.append({"character": str(effect["character"]), "skill": str(effect["skill"])})

	return {"messages": messages, "trust_changes": trust_changes, "skill_unlocks": skill_unlocks}


## Captures flags and which events have fired.
func snapshot() -> Dictionary:
	return {"flags": flags.duplicate(), "fired": _fired.keys()}


## True when the data has the shape snapshot() produces.
func is_snapshot_valid(data: Dictionary) -> bool:
	if not (data.get("flags", null) is Dictionary) or not (data.get("fired", null) is Array):
		return false
	for value: Variant in (data["flags"] as Dictionary).values():
		if not (value is bool):
			return false
	return true


## Restores flags and fired events. Returns false and changes nothing when the data is invalid.
func restore(data: Dictionary) -> bool:
	if not is_snapshot_valid(data):
		return false
	flags = (data["flags"] as Dictionary).duplicate()
	_fired = {}
	for id: Variant in data["fired"]:
		_fired[str(id)] = true
	return true


func _trigger_matches(trigger: Variant, context: Dictionary) -> bool:
	if not (trigger is Dictionary):
		return false
	var has_action: bool = str(trigger.get("action", "")) != ""
	var has_night: bool = bool(trigger.get("night_entered", false))
	var has_location: bool = str(trigger.get("location", "")) != ""
	if not has_action and not has_night and not has_location:
		return false
	if has_action and str(context.get("action", "")) != str(trigger["action"]):
		return false
	if has_location and str(context.get("location", "")) != str(trigger["location"]):
		return false
	if has_night and not bool(context.get("night_entered", false)):
		return false
	if trigger.has("is_night") and bool(context.get("is_night", false)) != bool(trigger["is_night"]):
		return false
	var day: int = int(context.get("day", 0))
	if trigger.has("day") and day != int(trigger["day"]):
		return false
	if trigger.has("min_day") and day < int(trigger["min_day"]):
		return false
	return true


func _conditions_hold(conditions: Array) -> bool:
	for condition: Dictionary in conditions:
		var actual: bool = bool(flags.get(str(condition["flag"]), false))
		if actual != bool(condition.get("equals", true)):
			return false
	return true
