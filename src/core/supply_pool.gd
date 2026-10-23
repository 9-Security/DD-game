class_name SupplyPool
extends RefCounted
## Herbs and food the party carries. Camping and healing draw from this pool.
## Counts never go below zero: a consume that would overdraw is refused.

const KINDS: Array[String] = ["herbs", "food"]

var _counts: Dictionary = {}


func _init(herbs: int, food: int) -> void:
	_counts = {"herbs": maxi(herbs, 0), "food": maxi(food, 0)}


## Current count of a supply kind, or 0 for an unknown kind.
func count(kind: String) -> int:
	return int(_counts.get(kind, 0))


## Adds a positive amount of a known kind. Returns false when rejected.
func add(kind: String, amount: int) -> bool:
	if not KINDS.has(kind) or amount <= 0:
		return false
	_counts[kind] = int(_counts[kind]) + amount
	return true


## Removes a positive amount of a known kind. Returns false and changes nothing when short.
func consume(kind: String, amount: int) -> bool:
	if not KINDS.has(kind) or amount <= 0 or int(_counts[kind]) < amount:
		return false
	_counts[kind] = int(_counts[kind]) - amount
	return true
