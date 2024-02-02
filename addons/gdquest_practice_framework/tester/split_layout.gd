extends "layout.gd"


func set_solution(value: Node) -> void:
	super(value)
	await get_tree().process_frame
	get_tree().set_group(VISIBILITY_GROUP, "self_modulate", Color.WHITE)
	fix_tile_map_transparencty()
