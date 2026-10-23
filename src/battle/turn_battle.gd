class_name TurnBattle
extends RefCounted
## Interactive turn-based battle for one party against one enemy (design D1, first-version scope).
##
## A round lets every living party member act once, in speed order (highest first; equal speed
## keeps the party order). When the last member has acted, the enemy strikes the living member with
## the lowest HP, and the next round begins. The caller drives the battle by calling act() for the
## member whose turn it is. Rolls are supplied by the caller and cycled, so results are deterministic.
##
## Party member: { id, name, hp, max_hp, mp, atk, def, speed, skill }
## Enemy:        { name, hp, max_hp, def, atk }
## Skills:       { skill_id: { cost, kind, amount?, multiplier? } }, kind is heal, guard, mark or attack.

## Chance of a successful retreat is 50 percent; a roll of at least this value succeeds.
const RETREAT_ROLL_THRESHOLD: float = 0.0
## Damage taken while defending is multiplied by this value.
const DEFEND_MULTIPLIER: float = 0.5

var rounds: int = 1

var _members: Array = []
var _enemy: Dictionary = {}
var _rolls: Array = []
var _roll_index: int = 0
var _round_limit: int = 20
var _skills: Dictionary = {}
var _pending: Array[String] = []
var _outcome: String = ""


## party: member dictionaries in party order. enemy: enemy dictionary.
## rolls: variance values in [-0.10, 0.10], cycled. round_limit: rounds allowed before the party loses.
## skills: skill definitions keyed by skill id.
func _init(party: Array, enemy: Dictionary, rolls: Array, round_limit: int, skills: Dictionary) -> void:
	for member: Dictionary in party:
		var copy: Dictionary = member.duplicate(true)
		copy["guard"] = 1.0
		_members.append(copy)
	_enemy = enemy.duplicate(true)
	_enemy["mark"] = 1.0
	_rolls = rolls
	_round_limit = round_limit
	_skills = skills
	_start_round()


## Ids of the living members who have not yet acted this round, in the order they act.
func turn_order() -> Array[String]:
	return _pending.duplicate()


## Performs one command for the member whose turn it is.
## command: "attack", "defend", "retreat" or "skill". target_id is used by heal skills.
## Returns { ok: bool, message: String }. Refused actions change nothing.
func act(member_id: String, command: String, target_id: String = "") -> Dictionary:
	if _outcome != "":
		return _refuse("戰鬥已結束。")
	if _pending.is_empty() or _pending[0] != member_id:
		return _refuse("還沒有輪到這位角色。")

	var member: Dictionary = _find(member_id)
	var cursed: bool = member.has("curse_stacks")
	var stacks_after: int = mini(int(member.get("curse_stacks", 0)) + 1, BloodCurse.MAX_STACKS)
	if cursed and stacks_after >= BloodCurse.MAX_STACKS:
		# A full curse makes this turn berserk: the stacks reset and the member does nothing.
		member["curse_stacks"] = 0
		member["guard"] = 1.0
		return _end_action("%s 陷入狂亂，本回合無法行動。" % member["name"])

	# Refused commands must change nothing, so the guard is restored if the command is refused.
	var previous_guard: float = float(member["guard"])
	member["guard"] = 1.0
	var message: String = ""
	match command:
		"attack":
			message = _attack_enemy(member, 1.0)
		"defend":
			member["guard"] = DEFEND_MULTIPLIER
			message = "%s 採取防禦。" % member["name"]
		"retreat":
			message = _retreat(member)
		"skill":
			var skill_result: Dictionary = _use_skill(member, target_id)
			if not skill_result["ok"]:
				member["guard"] = previous_guard
				return skill_result
			message = str(skill_result["message"])
		_:
			member["guard"] = previous_guard
			return _refuse("未知的指令：%s" % command)

	if cursed:
		member["curse_stacks"] = stacks_after
	return _end_action(message)


## Current blood-curse stacks of a member; 0 for members without a curse.
func curse_stacks(member_id: String) -> int:
	return int(_find(member_id).get("curse_stacks", 0))


## Blood-curse stacks of every cursed member, keyed by member id.
func curse_stacks_by_member() -> Dictionary:
	var stacks: Dictionary = {}
	for member: Dictionary in _members:
		if member.has("curse_stacks"):
			stacks[str(member["id"])] = int(member["curse_stacks"])
	return stacks


## Finishes the acting member's turn and returns the result of the action.
func _end_action(message: String) -> Dictionary:
	_pending.remove_at(0)
	_drop_fallen_from_pending()
	if _outcome == "" and _enemy_defeated():
		_outcome = "won"
	if _outcome == "" and _pending.is_empty():
		_end_round()
	return {"ok": true, "message": message}


## Current HP of a party member, or 0 when the id is unknown.
func member_hp(member_id: String) -> int:
	return int(_find(member_id).get("hp", 0))


## Current MP of a party member, or 0 when the id is unknown.
func member_mp(member_id: String) -> int:
	return int(_find(member_id).get("mp", 0))


## Current HP of the enemy.
func enemy_hp() -> int:
	return int(_enemy["hp"])


## "won", "lost", "fled", or "" while the battle continues.
func outcome() -> String:
	return _outcome


func _refuse(message: String) -> Dictionary:
	return {"ok": false, "message": message}


func _find(member_id: String) -> Dictionary:
	for member: Dictionary in _members:
		if member["id"] == member_id:
			return member
	return {}


func _alive(member: Dictionary) -> bool:
	return int(member["hp"]) > 0


func _enemy_defeated() -> bool:
	return int(_enemy["hp"]) <= 0


func _next_roll() -> float:
	if _rolls.is_empty():
		return 0.0
	var roll: float = float(_rolls[_roll_index % _rolls.size()])
	_roll_index += 1
	return roll


## Builds the order for a new round: living members by speed, ties keep party order.
func _start_round() -> void:
	var order: Array = []
	for index: int in range(_members.size()):
		if _alive(_members[index]):
			order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool:
		var speed_a: int = int(_members[a]["speed"])
		var speed_b: int = int(_members[b]["speed"])
		return speed_a > speed_b or (speed_a == speed_b and a < b))
	_pending.clear()
	for index: int in order:
		_pending.append(str(_members[index]["id"]))


func _attack_enemy(member: Dictionary, multiplier: float) -> String:
	var damage: int = DamageCalculator.calculate(int(member["atk"]), multiplier, int(_enemy["def"]), _next_roll())
	damage = roundi(damage * float(_enemy["mark"]))
	_enemy["mark"] = 1.0
	_enemy["hp"] = maxi(0, int(_enemy["hp"]) - maxi(1, damage))
	return "%s 攻擊，對敵人造成 %d 點傷害。" % [member["name"], maxi(1, damage)]


func _retreat(member: Dictionary) -> String:
	if _next_roll() >= RETREAT_ROLL_THRESHOLD:
		_outcome = "fled"
		return "%s 成功撤退。" % member["name"]
	var text: String = "%s 撤退失敗，敵人獲得一次額外攻擊。" % member["name"]
	return text + "\n" + _enemy_strike()


func _use_skill(member: Dictionary, target_id: String) -> Dictionary:
	var skill_id: String = str(member.get("skill", ""))
	if not _skills.has(skill_id):
		return _refuse("此角色沒有可用的技能。")
	var skill: Dictionary = _skills[skill_id]
	var cost: int = int(skill["cost"])
	if int(member["mp"]) < cost:
		return _refuse("魔力不足，無法施放技能。")
	member["mp"] = int(member["mp"]) - cost

	match str(skill["kind"]):
		"heal":
			var target: Dictionary = _find(target_id)
			if target.is_empty() or not _alive(target):
				member["mp"] = int(member["mp"]) + cost
				return _refuse("請選擇一位存活的隊員作為目標。")
			var healed: int = mini(int(skill["amount"]), int(target["max_hp"]) - int(target["hp"]))
			target["hp"] = int(target["hp"]) + healed
			return {"ok": true, "message": "%s 施放生命共鳴，為 %s 回復 %d 點生命。" % [member["name"], target["name"], healed]}
		"guard":
			member["guard"] = float(skill["multiplier"])
			return {"ok": true, "message": "%s 展開鐵壁，受到的傷害大幅減少。" % member["name"]}
		"mark":
			_enemy["mark"] = float(skill["multiplier"])
			return {"ok": true, "message": "%s 設下符文陷阱，敵人下一次受到的傷害提高。" % member["name"]}
		"attack":
			return {"ok": true, "message": _attack_enemy(member, float(skill["multiplier"]))}
	return _refuse("未知的技能種類。")


## Ends the round: the enemy strikes, then either the party is wiped out, the round limit is
## reached, or the next round begins.
func _end_round() -> void:
	if not _living_members().is_empty():
		_enemy_strike()
	if _living_members().is_empty():
		_outcome = "lost"
		return
	rounds += 1
	if rounds > _round_limit:
		_outcome = "lost"
		return
	_start_round()


## A member knocked out by an enemy strike mid-round must not act again this round.
func _drop_fallen_from_pending() -> void:
	var still_waiting: Array[String] = []
	for member_id: String in _pending:
		if _alive(_find(member_id)):
			still_waiting.append(member_id)
	_pending = still_waiting


func _living_members() -> Array:
	var living: Array = []
	for member: Dictionary in _members:
		if _alive(member):
			living.append(member)
	return living


## The enemy hits the living member with the lowest HP. Returns the description.
func _enemy_strike() -> String:
	var target: Dictionary = {}
	for member: Dictionary in _living_members():
		if target.is_empty() or int(member["hp"]) < int(target["hp"]):
			target = member
	if target.is_empty():
		return ""
	var raw: int = DamageCalculator.calculate(int(_enemy["atk"]), 1.0, int(target["def"]), _next_roll())
	var damage: int = maxi(1, roundi(raw * float(target["guard"])))
	target["hp"] = maxi(0, int(target["hp"]) - damage)
	var text: String = "敵人攻擊 %s，造成 %d 點傷害。" % [target["name"], damage]
	if not _alive(target):
		text += "\n%s 倒下了。" % target["name"]
	if _living_members().is_empty():
		_outcome = "lost"
	return text
