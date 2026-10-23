class_name BackdropRules
extends RefCounted
## Chooses which full-screen illustration sits behind the game screen.
##
## Priority: an ending reached, then the prologue, then the chapter of the current day.
## Pure logic with no scene access, so it can be unit tested.

## Illustration shown while the prologue lines are read.
const PROLOGUE_PATH: String = "res://assets/art/chapters/prologue.png"

## One illustration per story day, index 0 is day one.
const CHAPTER_PATHS: Array[String] = [
	"res://assets/art/chapters/ch01_departure.png",
	"res://assets/art/chapters/ch02_obsidian_gate.png",
	"res://assets/art/chapters/ch03_cursed_wall_maze.png",
	"res://assets/art/chapters/ch04_garden_of_silence.png",
	"res://assets/art/chapters/ch05_blood_oath_cavern.png",
	"res://assets/art/chapters/ch06_fallen_star_heart.png",
	"res://assets/art/chapters/ch07_abyss_wish.png",
]


## Returns the backdrop path for the current state.
## `ending_path` is the illustration of the ending reached, or "" while the story continues.
static func path_for(in_prologue: bool, day: int, ending_path: String) -> String:
	if ending_path != "":
		return ending_path
	if in_prologue:
		return PROLOGUE_PATH
	var index: int = clampi(day - 1, 0, CHAPTER_PATHS.size() - 1)
	return CHAPTER_PATHS[index]
