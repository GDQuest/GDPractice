extends Control

const PRACTICES_DIR := "res://practices"
const SOLUTIONS_DIR := "res://solutions"

const Test := preload("%s/test.gd" % SOLUTIONS_DIR)

var practices := {
	"to space and beyond": [
		"making_ship_move",
		"adding_input",
		"adding_timer",
	],
}

@onready var sub_viewport: SubViewport = %SubViewport
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer
@onready var next_button: Button = %NextButton


func _ready() -> void:
	build("adding_timer")
#	var practice_count := practices.size()
#	for project_name in practices:
#		for practice_name in practices[project_name]:
#			await check(practice_name, project_name)
#			await next_button.pressed
#			for node in checks_v_box_container.get_children():
#				node.queue_free()


func check(dir_name: StringName, project_name: String) -> void:
	for node in sub_viewport.get_children():
		node.queue_free()

	var scene_name := "".join([dir_name, ".tscn"])
	var solution_scene := load(SOLUTIONS_DIR.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()
	sub_viewport.add_child(solution)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var practice_scene := load(PRACTICES_DIR.path_join(dir_name).path_join(scene_name))
	var practice: Node = practice_scene.instantiate()
	sub_viewport.add_child(practice)

	var test_script := load(SOLUTIONS_DIR.path_join(dir_name).path_join("".join([dir_name, "_test.gd"])))
	var test: Test = test_script.new()
	sub_viewport.add_child(test)

	title_rich_text_label.text = "Checking...\n[b]%s:%s[/b]" % [
		project_name,
		dir_name,
	].map(func(x: String) -> String: return x.capitalize())
	print_rich("\n%s" % title_rich_text_label.text)
	await test.setup(practice, solution)
	await test.run(checks_v_box_container)


func build(dir_name: StringName) -> void:
	var scene_name := "".join([dir_name, ".tscn"])
	var solution_dir := SOLUTIONS_DIR.path_join(dir_name)
	var solution_scene := load(solution_dir.path_join(scene_name))
	var solution: Node = solution_scene.instantiate()

	var diff_path := solution_dir.path_join("".join([dir_name, "_diff.gd"]))
	if FileAccess.file_exists(diff_path):
		var diff := load(diff_path)
		diff.run(solution)

	var scene := PackedScene.new()
	if scene.pack(solution) == OK:
		var practice_dir := PRACTICES_DIR.path_join(dir_name)
		if DirAccess.dir_exists_absolute(practice_dir):
			for paths in ["*", "*/"].map(func(x: String) -> Array: return Utils.fs_find(x, practice_dir)):
				for path in paths:
					DirAccess.remove_absolute(path)
		DirAccess.make_dir_absolute(practice_dir)

		for path in Utils.fs_find("*", solution_dir):
			var file_name: String = path.get_file()
			if not ["_test.gd", "_diff.gd"].any(func(x: String) -> bool: return path.ends_with(x)):
				DirAccess.copy_absolute(path, practice_dir.path_join(file_name))
		ResourceSaver.save(scene, practice_dir.path_join(scene_name))
