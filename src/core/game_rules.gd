class_name GameRules
extends RefCounted
## Validation for the balance rule file (assets/data/rules/balance.json).
## Values live in data so they can be tuned without changing code.

const DIFFICULTY_NAMES: Array[String] = ["strict", "assisted"]
const SUPPLY_FIELDS: Array[String] = ["starting_herbs", "starting_food", "rest_food_cost"]


## Returns human-readable errors. An empty list means the rules are usable.
static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []

	var difficulty: Dictionary = data.get("difficulty", {})
	for name: String in DIFFICULTY_NAMES:
		if not difficulty.has(name):
			errors.append("difficulty.%s is required" % name)
			continue
		for field: String in SUPPLY_FIELDS:
			var value: Variant = difficulty[name].get(field, -1)
			if not (value is int or value is float) or int(value) < 0 or not is_equal_approx(float(value), floorf(float(value))):
				errors.append("difficulty.%s.%s must be a non-negative integer" % [name, field])

	var trust: Dictionary = data.get("trust", {})
	var low: int = int(trust.get("min", 0))
	var high: int = int(trust.get("max", 100))
	var start: int = int(trust.get("start", 50))
	if start < low or start > high:
		errors.append("trust.start must be between trust.min and trust.max")

	return errors
