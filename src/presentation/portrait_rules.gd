class_name PortraitRules
extends RefCounted
## Chooses the portrait shown for a dialogue speaker. Narration and unknown speakers have none.
## Speakers are matched by their display name, as used in the dialogue data.

const PORTRAIT_DIR: String = "res://assets/art/portraits/"
## Speaker name to portrait file. Keep the names identical to the dialogue data.
const PORTRAITS: Dictionary = {
	"艾洛恩": "portrait_eron.png",
	"芙蕾雅": "portrait_freya.png",
	"茵芮": "portrait_inry.png",
	"國王": "portrait_king.png",
	"黎安娜": "portrait_liana.png",
	"里克特": "portrait_richter.png",
	"瑟維恩": "portrait_servien_echo.png",
}
## Every speaker that has a portrait, in the order they are listed above.
const SPEAKERS: Array[String] = ["艾洛恩", "芙蕾雅", "茵芮", "國王", "黎安娜", "里克特", "瑟維恩"]


## Returns the portrait path for a speaker, or "" when the speaker has no portrait.
static func path_for_speaker(speaker: String) -> String:
	if not PORTRAITS.has(speaker):
		return ""
	return PORTRAIT_DIR + str(PORTRAITS[speaker])
