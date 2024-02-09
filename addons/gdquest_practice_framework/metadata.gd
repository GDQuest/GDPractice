const PATH := "res://practice_solutions/metadatas.cfg"


class Item:
	var lesson_number := 0
	var practice_number := 0
	var id := &""
	var title := &""
	var scenes: Array = []

	func _to_string() -> String:
		return (
			'{ "id": %s, "lesson_number": %d, "practice_number": %d, "title": %s, "scenes": %s }'
			% [id, lesson_number, practice_number, title, scenes]
		)


static func load() -> Array[Item]:
	var result: Array[Item] = []
	var cfg := ConfigFile.new()
	cfg.load(PATH)

	var lesson_number := 0
	var practice_number := 1
	for section in cfg.get_sections():
		var metadata := Item.new()
		metadata.id = section
		for key in cfg.get_section_keys(section):
			metadata.set(key, cfg.get_value(section, key))

		if lesson_number != metadata.lesson_number:
			lesson_number = metadata.lesson_number
			practice_number = 1
		metadata.practice_number = practice_number
		practice_number += 1
		result.push_back(metadata)
	return result
