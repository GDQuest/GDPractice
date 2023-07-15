extends Node2D

const PRACTICES_DIR := "res://practices"
const SOLUTIONS_DIR := "res://solutions"


func _ready() -> void:
	check("01.making_ship_move")


func check(dir_name: StringName) -> void:
	var base_name := dir_name.split(".").slice(1)
	var scene_name := "".join(base_name + PackedStringArray([".tscn"]))

	var practice_scene := load(PRACTICES_DIR.path_join(dir_name).path_join(scene_name))
	var practice: Node = practice_scene.instantiate()
	add_child(practice)

	var solution_scene := load(SOLUTIONS_DIR.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()
	add_child(solution)

	var test_script := load(SOLUTIONS_DIR.path_join(dir_name).path_join("".join(base_name + PackedStringArray(["_test.gd"]))))
	var test: Node = test_script.new()
	add_child(test)
	await test.setup(practice, solution)
	await test.run()
