@tool
extends Node

## Saves and loads metadata for practices using the ConfigFile format of Godot.
const Paths := preload("paths.gd")

const NAME := "Metadata"


## Represents the metadata of a practice.
class PracticeMetadata:
	var _cache := {}
	var _dir_name_regex := RegEx.create_from_string(r"^L(\d+)\.P(\d+)\..+$")

	var lesson_number := 0
	var practice_number := 0
	var packed_scene_path := ""
	var item := ""
	var full_title := ""

	var id := ""
	var title := ""
	var packed_scene: PackedScene = null

	func _init(id: String, title: String, packed_scene: PackedScene) -> void:
		self.id = id
		self.title = title
		self.packed_scene = packed_scene

		packed_scene_path = packed_scene.resource_path
		var dir_name := Paths.get_dir_name(packed_scene_path)
		var match := _dir_name_regex.search(dir_name)
		lesson_number = match.strings[1].to_int()
		practice_number = match.strings[2].to_int()
		item = "L%d.P%d" % [lesson_number, practice_number]
		full_title = "%s %s" % [item, title]

	func _to_string() -> String:
		return str(to_dictionary())

	func to_dictionary(exclude: Array[String] = ["@*", "_*"]) -> Dictionary:
		if "dictionary" in _cache:
			return _cache.dictionary

		var result := inst_to_dict(self)
		var predicate := func(k: String) -> bool: return exclude.any(
			func(e: String) -> bool: return k.match(e)
		)

		for key in result.keys().filter(predicate):
			result.erase(key)

		_cache.dictionary = result
		return result


var list: Array[PracticeMetadata] = []
