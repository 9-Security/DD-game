# Balance simulator for the first-version battle. Development tool only; not part of the game.
# It mirrors src/battle/turn_battle.gd and src/battle/damage_calculator.gd with a baseline policy
# (every member attacks, uses its skill when it has MP, Eron heals the lowest ally). Run: python3 battle_sim.py
# target_mode: 'lowest' (current game rule) or 'random' (proposed). Results are provisional.
# Monte Carlo of the first-version TurnBattle rules, used only to inform balance decisions.
# Rules mirror src/battle/turn_battle.gd and src/battle/damage_calculator.gd. Policy is a simple
# baseline: each member attacks, uses its skill when it has MP, heals the lowest ally (Eron).
import random, json, sys

ROLL = 0.10
DEF_F = 0.5
ROUND_LIMIT = 20
MAX_CURSE = 5

SKILLS = {
    "life_resonance": {"cost": 15, "kind": "heal", "amount": 20},
    "iron_guard": {"cost": 10, "kind": "guard", "multiplier": 0.25},
    "rune_trap": {"cost": 15, "kind": "mark", "multiplier": 1.5},
    "magic_surge": {"cost": 40, "kind": "attack", "multiplier": 2.0},
}
PARTY = {
    "eron": dict(hp=90, mp=60, atk=8, dfn=6, spd=9, skill="life_resonance"),
    "freya": dict(hp=130, mp=20, atk=16, dfn=10, spd=6, skill="iron_guard", curse=True),
    "richter": dict(hp=85, mp=50, atk=10, dfn=5, spd=13, skill="rune_trap"),
    "inry": dict(hp=80, mp=90, atk=6, dfn=4, spd=10, skill="magic_surge"),
}
ENEMIES = {
    "tutorial": dict(hp=30, dfn=2, atk=6),
    "spirit_gate": dict(hp=30, dfn=1, atk=6),
    "rune_seal": dict(hp=20, dfn=0, atk=4),
    "mirror_freya": dict(hp=40, dfn=3, atk=8),
    "guardian": dict(hp=60, dfn=4, atk=10),
    "armour": dict(hp=70, dfn=6, atk=12),
}

def dmg(atk, mult, dfn, roll):
    base = atk * mult - dfn * DEF_F
    return max(1, round(base * (1 + roll)))

def fight(members, enemy, rng, target_mode="lowest"):
    m = [dict(id=k, name=k, hp=v["hp"], mp=v["mp"], atk=v["atk"], dfn=v["dfn"], spd=v["spd"],
              skill=v["skill"], curse=v.get("curse", False), stacks=0, guard=1.0)
         for k, v in members.items()]
    e = dict(hp=enemy["hp"], dfn=enemy["dfn"], atk=enemy["atk"], mark=1.0)
    rounds = 0
    while True:
        rounds += 1
        alive = [x for x in m if x["hp"] > 0]
        order = sorted(alive, key=lambda x: (-x["spd"], m.index(x)))
        for x in order:
            if x["hp"] <= 0:
                continue
            x["guard"] = 1.0
            if x["curse"]:
                x["stacks"] = min(x["stacks"] + 1, MAX_CURSE)
                if x["stacks"] >= MAX_CURSE:
                    x["stacks"] = 0
                    continue  # berserk: no action
            sk = SKILLS[x["skill"]]
            if x["mp"] >= sk["cost"] and sk["kind"] == "heal":
                allies = [a for a in m if a["hp"] > 0 and a["hp"] < max_hp(a["id"])]
                if allies:
                    t = min(allies, key=lambda a: a["hp"])
                    t["hp"] = min(max_hp(t["id"]), t["hp"] + sk["amount"])
                    x["mp"] -= sk["cost"]
                    continue
            if x["mp"] >= sk["cost"] and sk["kind"] == "guard":
                x["guard"] = sk["multiplier"]; x["mp"] -= sk["cost"]
            elif x["mp"] >= sk["cost"] and sk["kind"] == "mark":
                e["mark"] = sk["multiplier"]; x["mp"] -= sk["cost"]
            elif x["mp"] >= sk["cost"] and sk["kind"] == "attack":
                d = dmg(x["atk"], sk["multiplier"], e["dfn"], rng.uniform(-ROLL, ROLL))
                d = round(d * e["mark"]); e["mark"] = 1.0
                e["hp"] -= max(1, d); x["mp"] -= sk["cost"]
            else:
                d = dmg(x["atk"], 1.0, e["dfn"], rng.uniform(-ROLL, ROLL))
                d = round(d * e["mark"]); e["mark"] = 1.0
                e["hp"] -= max(1, d)
            if e["hp"] <= 0:
                return "won", rounds, sum(max(0, y["hp"]) for y in m)
        if e["hp"] <= 0:
            return "won", rounds, sum(max(0, y["hp"]) for y in m)
        alive = [x for x in m if x["hp"] > 0]
        if not alive:
            return "lost", rounds, 0
        t = min(alive, key=lambda a: a["hp"]) if target_mode == "lowest" else rng.choice(alive)
        d = max(1, round(dmg(e["atk"], 1.0, t["dfn"], rng.uniform(-ROLL, ROLL)) * t["guard"]))
        t["hp"] -= d
        if not [x for x in m if x["hp"] > 0]:
            return "lost", rounds, 0
        if rounds >= ROUND_LIMIT:
            return "lost", rounds, sum(max(0, y["hp"]) for y in m)

MAXHP = {k: v["hp"] for k, v in PARTY.items()}
def max_hp(i): return MAXHP[i]

def run(enemy_key, n=4000, seed=1, party=None, curse_start=0, target_mode="lowest"):
    rng = random.Random(seed)
    party = party or PARTY
    wins = 0; rounds_sum = 0; hp_left = 0
    for _ in range(n):
        p = {k: dict(v) for k, v in party.items()}
        if "freya" in p and p["freya"].get("curse"):
            p["freya"]["curse_start"] = curse_start
        outcome, r, left = fight(p, ENEMIES[enemy_key], rng, target_mode)
        if outcome == "won":
            wins += 1; rounds_sum += r; hp_left += left
    return wins / n, (rounds_sum / wins if wins else 0), (hp_left / wins if wins else 0)

if __name__ == "__main__":
    for key in ENEMIES:
        w, r, h = run(key)
        print(f"{key:14s} win {w*100:5.1f}%  avg rounds {r:4.1f}  avg hp left (wins) {h:6.1f}")
