extends Node2D

const PRACTICES_DIR := "res://practices"
const SOLUTIONS_DIR := "res://solutions"


func _ready() -> void:
	var dir := DirAccess.open(PRACTICES_DIR)
	if dir != null:
		dir.list_dir_begin()
		var node_name := dir.get_next()
		while node_name != "":
			if dir.current_is_dir():
				var base_name := node_name.split(".").slice(1)
				var scene_name := "".join(base_name + PackedStringArray([".tscn"]))

				var practice_scene := load(PRACTICES_DIR.path_join(node_name).path_join(scene_name))
				var practice_node: Node = practice_scene.instantiate()
				add_child(practice_node)

				var solution_scene := load(SOLUTIONS_DIR.path_join(node_name).path_join(scene_name))
				var solution_node: Node = solution_scene.instantiate()
				add_child(solution_node)

				var test_script := load(SOLUTIONS_DIR.path_join(node_name).path_join("_".join(base_name + PackedStringArray(["test.gd"]))))
				var test_node: Node = test_script.new()
				add_child(test_node)
				test_node.setup(practice_node, solution_node)
				test_node.run()
			node_name = dir.get_next()
