class_name ApproachRules
extends RefCounted
## Decides which approaches an encounter offers. Combat is always available.
## Every other approach needs at least one party skill mapped to it.


## encounter_approaches: approaches the encounter lists.
## party_skill_ids: skill IDs the party has acquired (starting or extra).
## approach_skills: approach name -> array of skill IDs that unlock it.
static func available_approaches(encounter_approaches: Array, party_skill_ids: Array, approach_skills: Dictionary) -> Array[String]:
	var options: Array[String] = []
	for approach: Variant in encounter_approaches:
		var name: String = str(approach)
		if name == "combat":
			options.append(name)
			continue
		var required: Array = approach_skills.get(name, [])
		for skill_id: Variant in party_skill_ids:
			if required.has(skill_id):
				options.append(name)
				break
	return options
