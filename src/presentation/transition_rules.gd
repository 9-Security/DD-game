class_name TransitionRules
extends RefCounted
## Chooses the transition illustration shown for a moment in the story. Pure logic, so it can be
## unit tested. The kinds are fixed; the file behind each kind is an illustration in assets/art/chapters/.

const KIND_PARTY: String = "party"
const KIND_CHAPTER: String = "chapter"
const KIND_TRAVEL: String = "travel"
const KIND_CRITICAL: String = "critical"
const KIND_ENDING: String = "ending"
const KINDS: Array[String] = [KIND_PARTY, KIND_CHAPTER, KIND_TRAVEL, KIND_CRITICAL, KIND_ENDING]

## The party gathers as the prologue ends and the first day begins.
const PARTY_PATH: String = "res://assets/art/chapters/transition_party.png"
## A new story day begins ("一般章節轉場").
const CHAPTER_PATH: String = "res://assets/art/chapters/transition_book.png"
## The party moves to another place.
const TRAVEL_PATH: String = "res://assets/art/chapters/transition_map.png"
## A final choice is made at the palace.
const CRITICAL_PATH: String = "res://assets/art/chapters/transition_critical_choice.png"
## An ending is reached.
const ENDING_PATH: String = "res://assets/art/chapters/transition_ending.png"


## Returns the illustration path for a transition kind, or "" for an unknown kind.
static func path_for(kind: String) -> String:
	match kind:
		KIND_PARTY:
			return PARTY_PATH
		KIND_CHAPTER:
			return CHAPTER_PATH
		KIND_TRAVEL:
			return TRAVEL_PATH
		KIND_CRITICAL:
			return CRITICAL_PATH
		KIND_ENDING:
			return ENDING_PATH
	return ""
