extends Node2D

const PRACTICES_DIR := "res://practices"
const SOLUTIONS_DIR := "res://solutions"


func _ready() -> void:
	await check("making_ship_move", true)
	await check("adding_input", false)


func check(dir_name: StringName, do_free: bool) -> void:
	var scene_name := "".join([dir_name, ".tscn"])

	var solution_scene := load(SOLUTIONS_DIR.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()
	add_child(solution)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var practice_scene := load(PRACTICES_DIR.path_join(dir_name).path_join(scene_name))
	var practice: Node = practice_scene.instantiate()
	add_child(practice)

	var test_script := load(SOLUTIONS_DIR.path_join(dir_name).path_join("".join([dir_name, "_test.gd"])))
	var test: Node = test_script.new()
	add_child(test)
	await test.setup(practice, solution)

	print(dir_name.capitalize())
	await test.run()

	if do_free:
		for node in [practice, solution, test]:
			node.queue_free()


func build(dir_name: StringName) -> void:
	var scene_name := "".join([dir_name, ".tscn"])
	var solution_scene := load(SOLUTIONS_DIR.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()

	var diff_path := SOLUTIONS_DIR.path_join(dir_name).path_join("".join([dir_name, "_diff.gd"]))
	if FileAccess.file_exists(diff_path):
		var diff := load(diff_path)
		diff.run(solution)

	var scene := PackedScene.new()
	if scene.pack(solution) == OK:
		ResourceSaver.save(scene, "res://test.tscn")
