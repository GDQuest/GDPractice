extends "layout.gd"

@onready var sub_viewports: Array[SubViewport] = []


func _ready() -> void:
	sub_viewports.assign([practice_sub_viewport, solution_sub_viewport])


func _gui_input(event: InputEvent) -> void:
	for sub_viewport in sub_viewports:
		sub_viewport.handle_input_locally = true
		sub_viewport.push_input(event)


func set_solution(value: Node) -> void:
	super(value)
	await get_tree().process_frame
	get_tree().set_group(VISIBILITY_GROUP, "self_modulate", Color.TRANSPARENT)
	fix_tile_map_transparencty()
