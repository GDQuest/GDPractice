@tool
extends Resource

@export var title := &""
@export var id := &""

var scene_file_paths: Array[String] = []


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "scene_file_paths",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [TYPE_OBJECT, PROPERTY_HINT_FILE, "*.tscn"],
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
		},
	]


func is_free() -> bool:
	return not scene_file_paths.is_empty()
