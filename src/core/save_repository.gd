class_name SaveRepository
extends RefCounted
## Reads and writes JSON save files. All disk access for saves is isolated here,
## so game logic can be unit tested without touching the file system.


## Writes the data as JSON to the given path. Returns false when the file cannot be opened.
static func write(path: String, data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for writing: %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


## Reads a JSON save file. Returns null when the file is missing, unreadable,
## or does not contain a JSON object.
static func read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("Save file is not a valid JSON object: %s" % path)
		return null
	return parsed
