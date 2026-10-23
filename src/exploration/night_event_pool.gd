class_name NightEventPool
extends RefCounted
## Weighted night event pool. Entries are chosen by an injected roll in [0, 1),
## so selection is deterministic in tests and seeded in play.
## Outcomes: "battle" (may be lost), "resource_loss", "flavor".

const OUTCOMES: Array[String] = ["battle", "resource_loss", "flavor"]


## Returns human-readable errors for a list of entries. An empty list means valid.
static func validate(entries: Array) -> Array[String]:
	var errors: Array[String] = []
	for index: int in range(entries.size()):
		var entry: Variant = entries[index]
		var prefix: String = "entries[%d]" % index
		if not (entry is Dictionary):
			errors.append("%s must be an object" % prefix)
			continue
		if int(entry.get("weight", 0)) <= 0:
			errors.append("%s.weight must be greater than 0" % prefix)
		if not OUTCOMES.has(str(entry.get("outcome", ""))):
			errors.append("%s.outcome must be one of: %s" % [prefix, ", ".join(OUTCOMES)])
	return errors


## Picks an entry by weight. Returns an empty dictionary for an empty pool.
static func pick(entries: Array, roll: float) -> Dictionary:
	var total: int = 0
	for entry: Dictionary in entries:
		total += int(entry.get("weight", 0))
	if total <= 0:
		return {}

	var threshold: float = clampf(roll, 0.0, 0.999999) * total
	var cumulative: float = 0.0
	for entry: Dictionary in entries:
		cumulative += int(entry.get("weight", 0))
		if threshold < cumulative:
			return entry
	return entries[entries.size() - 1]


## Applies the loss consequences of a battle entry to the supply pool.
## Deductions never go below zero. Returns true when the party is injured.
static func resolve_loss(entry: Dictionary, supply: SupplyPool) -> bool:
	var loss: Dictionary = entry.get("on_loss", {})
	var food: int = int(loss.get("food", 0))
	var herbs: int = int(loss.get("herbs", 0))
	if food > 0:
		supply.consume("food", mini(food, supply.count("food")))
	if herbs > 0:
		supply.consume("herbs", mini(herbs, supply.count("herbs")))
	return bool(loss.get("injury", false))
