class_name BgmRules
extends RefCounted
## Chooses which background music key should play for the current screen.
##
## Returns a key only; the file behind each key is configured in assets/data/audio/bgm.json,
## so the music can change without touching code. Pure logic, so it can be unit tested.

const KEY_PROLOGUE: String = "prologue"
const KEY_EXPLORE: String = "explore"
const KEY_HEART: String = "heart"
const ENDING_KEYS: Dictionary = {
	"END_A": "ending_a",
	"END_B": "ending_b",
	"END_C": "ending_c",
}
const HEART_PLACE: String = "墜星之心"


## Returns the music key for the state: an ending reached, the prologue, the heart, or exploration.
static func key_for(in_prologue: bool, ending_id: String, place: String) -> String:
	if ending_id != "":
		return str(ENDING_KEYS.get(ending_id, KEY_EXPLORE))
	if in_prologue:
		return KEY_PROLOGUE
	if place == HEART_PLACE:
		return KEY_HEART
	return KEY_EXPLORE
