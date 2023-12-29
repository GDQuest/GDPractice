extends Resource

const PATH := "user://progress.tres"

@export var state := {}


func _init() -> void:
	resource_path = PATH
