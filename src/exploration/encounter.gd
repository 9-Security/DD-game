class_name Encounter
extends RefCounted
## One encounter: an enemy or obstacle the party can answer with one of several approaches.
## Combat is always offered; other approaches need a matching party skill (ApproachRules).
## Approaches:
##   "combat":  a skirmish against the encounter's enemy.
##   "persuade": succeeds when the roll reaches persuade_threshold; otherwise a fight follows.
##   "puzzle":  solved without a fight.
##   "summon":  a fight with one extra summoned member.

const KNOWN_APPROACHES: Array[String] = ["combat", "persuade", "puzzle", "summon"]
const FIGHTING_APPROACHES: Array[String] = ["combat", "persuade", "summon"]
const DEFAULT_PERSUADE_THRESHOLD: float = 0.5
const DEFAULT_SUMMON_ATK: int = 12
const DEFAULT_ENEMY_ATK: int = 5

var id: String
var text: String
var enemy_name: String
var sprite: String
var enemy_hp: int
var enemy_def: int
var enemy_atk: int
var enemy_tags: Array
var approaches: Array
var persuade_threshold: float
var on_loss: Dictionary


func _init(entry: Dictionary) -> void:
	id = str(entry.get("id", ""))
	text = str(entry.get("text", ""))
	enemy_name = str(entry.get("name", "敵人"))
	sprite = str(entry.get("sprite", ""))
	enemy_hp = int(entry.get("enemy_hp", 0))
	enemy_def = int(entry.get("enemy_def", 0))
	enemy_atk = int(entry.get("enemy_atk", DEFAULT_ENEMY_ATK))
	enemy_tags = entry.get("enemy_tags", [])
	approaches = entry.get("approaches", [])
	persuade_threshold = float(entry.get("persuade_threshold", DEFAULT_PERSUADE_THRESHOLD))
	on_loss = entry.get("on_loss", {})


## Returns human-readable errors for one entry. An empty list means valid.
static func validate(entry: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(entry.get("id", "")) == "":
		errors.append("id is required")
	var list: Variant = entry.get("approaches", [])
	if not (list is Array) or (list as Array).is_empty():
		errors.append("approaches must contain at least one approach")
		return errors
	for approach: Variant in list:
		if not KNOWN_APPROACHES.has(str(approach)):
			errors.append("unknown approach: %s" % str(approach))
	var fights: bool = false
	for approach: Variant in list:
		if FIGHTING_APPROACHES.has(str(approach)):
			fights = true
	if fights and int(entry.get("enemy_hp", 0)) <= 0:
		errors.append("enemy_hp must be greater than 0 when a fight is possible")
	return errors


## Approaches the party may choose, given the skills they have.
func available(party_skill_ids: Array, approach_skills: Dictionary) -> Array[String]:
	return ApproachRules.available_approaches(approaches, party_skill_ids, approach_skills)


## Resolves one approach. members: built skirmish members. rolls: variance and persuade rolls.
## summon: the extra member for a summon approach. Returns a result dictionary with "outcome".
func resolve(approach: String, members: Array, rolls: Array, affinity: Dictionary, summon: Dictionary) -> Dictionary:
	if approach == "puzzle":
		return {"outcome": "solved", "rounds": 0, "weak_hits": 0, "resist_hits": 0, "persuade_failed": false}

	var persuade_failed: bool = false
	if approach == "persuade":
		var roll: float = float(rolls[0]) if not rolls.is_empty() else 0.0
		if roll >= persuade_threshold:
			return {"outcome": "persuaded", "rounds": 0, "weak_hits": 0, "resist_hits": 0, "persuade_failed": false}
		persuade_failed = true

	var fighters: Array = members.duplicate()
	if approach == "summon":
		var extra: Dictionary = summon if not summon.is_empty() else {"atk": DEFAULT_SUMMON_ATK, "attack_tag": "light"}
		fighters.append(extra)

	var result: Dictionary = Skirmish.resolve(
		fighters, enemy_hp, enemy_def, rolls, Skirmish.DEFAULT_ROUND_LIMIT,
		{"enemy_tags": enemy_tags, "affinity": affinity})
	return {
		"outcome": "won" if result["won"] else "lost",
		"rounds": result["rounds"],
		"weak_hits": result["weak_hits"],
		"resist_hits": result["resist_hits"],
		"persuade_failed": persuade_failed,
		"enemy_hp_left": result["enemy_hp_left"],
	}
