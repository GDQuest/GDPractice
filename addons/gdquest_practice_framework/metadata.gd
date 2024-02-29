## Saves and loads metadata for practices using the ConfigFile format of Godot.
const Paths := preload("paths.gd")

## The path to the file containing the metadata of all practices.
const PATH := "res://practice_solutions/metadata.cfg"


## Represents the metadata of a practice.
class PracticeMetadata:
	var lesson_number := 0
	var practice_number := 0
	var id := ""
	var title := ""
	var main_scene := ""

	func _to_string() -> String:
		return (
			'{ "id": %s, "lesson_number": %d, "practice_number": %d, "title": %s, "main_scene": %s }'
			% [id, lesson_number, practice_number, title, main_scene]
		)


## Loads the metadata of all practices contained in a config file.
static func load() -> Array[PracticeMetadata]:
	var result: Array[PracticeMetadata] = []
	var cfg := ConfigFile.new()
	var error_code := cfg.load(PATH)
	if error_code != OK:
		push_error(
			"Failed to load practices metadata file '%s', error code: %d" % [PATH, error_code]
		)
		return result

	var error_messages := []
	var dir_name_regex := RegEx.create_from_string(r"^L(\d+)\.P(\d+)\..+$")
	for section in cfg.get_sections():
		var metadata := PracticeMetadata.new()
		metadata.id = section
		for key in cfg.get_section_keys(section):
			metadata.set(key, cfg.get_value(section, key))

		var dir_name := Paths.get_dir_name(metadata.main_scene)
		var match := dir_name_regex.search(dir_name)
		if match == null:
			var msg := "Practice (id=%s) 'main_scene' dir name should be 'L-.P-.some_name', but got '%s' instead! Fix 'metadata.cfg'."
			error_messages.push_back(msg % [metadata.id, dir_name])
			continue

		metadata.lesson_number = match.strings[1].to_int()
		metadata.practice_number = match.strings[2].to_int()
		result.push_back(metadata)

	if not error_messages.is_empty():
		result = []
		push_error("\n".join(error_messages))
		print()
	return result


static func get_modified_time() -> int:
	return FileAccess.get_modified_time(PATH)
