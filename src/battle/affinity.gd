class_name Affinity
extends RefCounted
## Attack-tag weakness and resistance. The matchup table is supplied by the caller
## (loaded from assets/data/rules/balance.json), so this stays a pure function.


## Damage multiplier for one attack tag against a set of target tags.
## A weakness and a resistance that hit the same target cancel out to neutral.
static func multiplier(attack_tag: String, target_tags: Array, table: Dictionary) -> float:
	var matchups: Dictionary = table.get("matchups", {})
	if not matchups.has(attack_tag):
		return 1.0

	var entry: Dictionary = matchups[attack_tag]
	var weak_hit: bool = _any_match(entry.get("weak", []), target_tags)
	var resist_hit: bool = _any_match(entry.get("resist", []), target_tags)

	if weak_hit and not resist_hit:
		return float(table.get("weak_multiplier", 1.0))
	if resist_hit and not weak_hit:
		return float(table.get("resist_multiplier", 1.0))
	return 1.0


static func _any_match(listed: Array, tags: Array) -> bool:
	for tag: Variant in tags:
		if listed.has(tag):
			return true
	return false
