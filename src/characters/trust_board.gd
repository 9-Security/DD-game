class_name TrustBoard
extends RefCounted
## Trust value per character, clamped to a configured range, and team synergies
## that activate when every listed member meets a trust threshold.

var _values: Dictionary = {}
var _min: int
var _max: int


func _init(character_ids: Array, start: int, min_value: int, max_value: int) -> void:
	_min = min_value
	_max = max_value
	for character_id: Variant in character_ids:
		_values[str(character_id)] = clampi(start, _min, _max)


## Current trust, or -1 for an unknown character.
func get_trust(character_id: String) -> int:
	return int(_values.get(character_id, -1))


## Changes trust by delta, clamped to the range. Returns the new value, or -1 when unknown.
func change(character_id: String, delta: int) -> int:
	if not _values.has(character_id):
		return -1
	_values[character_id] = clampi(int(_values[character_id]) + delta, _min, _max)
	return int(_values[character_id])


## Effect names of every synergy whose members all meet their threshold.
## Each synergy: {"members": Array, "min_trust": int, "effect": String}.
func active_synergies(synergies: Array) -> Array[String]:
	var effects: Array[String] = []
	for synergy: Dictionary in synergies:
		var met: bool = true
		for member: Variant in synergy.get("members", []):
			if get_trust(str(member)) < int(synergy.get("min_trust", 0)):
				met = false
				break
		if met:
			effects.append(str(synergy.get("effect", "")))
	return effects


## Sets trust to a value (clamped). Used when restoring a saved game.
## Returns false for an unknown character.
func set_trust(character_id: String, value: int) -> bool:
	if not _values.has(character_id):
		return false
	_values[character_id] = clampi(value, _min, _max)
	return true


## Character IDs covered by an active synergy that carries the given effect.
func members_with_effect(synergies: Array, effect: String) -> Array[String]:
	var members: Array[String] = []
	for synergy: Dictionary in synergies:
		if str(synergy.get("effect", "")) != effect:
			continue
		var active: bool = true
		for member: Variant in synergy.get("members", []):
			if get_trust(str(member)) < int(synergy.get("min_trust", 0)):
				active = false
				break
		if active:
			for member: Variant in synergy.get("members", []):
				if not members.has(str(member)):
					members.append(str(member))
	return members
