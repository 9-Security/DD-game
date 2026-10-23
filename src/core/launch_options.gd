class_name LaunchOptions
extends RefCounted
## Turns launch parameters from a web page URL into the option strings the desktop build reads
## from the command line, so both builds share one code path. Example:
##   ?skip=1&difficulty=assisted&demo=move,go:黑曜石之門
## becomes --skip-prologue, --difficulty=assisted, --demo-action=move, --demo-action=go:黑曜石之門.
## Recognised keys: skip (1 to skip the prologue), difficulty, load (1 to load the save slot),
## demo (comma-separated actions, performed in order).


## Converts a query string (with or without the leading "?") into option strings.
static func from_query(query: String) -> PackedStringArray:
	var result := PackedStringArray()
	for pair: String in query.trim_prefix("?").split("&", false):
		var parts: PackedStringArray = pair.split("=", true, 1)
		var key: String = parts[0].uri_decode()
		var value: String = parts[1].uri_decode() if parts.size() > 1 else ""
		match key:
			"skip":
				if value == "1":
					result.append("--skip-prologue")
			"difficulty":
				result.append("--difficulty=" + value)
			"load":
				if value == "1":
					result.append("--demo-load")
			"demo":
				for action: String in value.split(",", false):
					result.append("--demo-action=" + action)
	return result
