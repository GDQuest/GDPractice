extends ColorRect

@onready var _camera: Camera2D


func _ready() -> void:
	await get_tree().root.ready
	_camera = get_viewport().get_camera_2d()
	set_process(_camera != null)


func _process(_delta: float) -> void:
	material.set_shader_parameter("view_offset", _camera.global_position)
