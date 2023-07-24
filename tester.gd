class_name Tester extends Control

var practices := {
	"to space and beyond": [
		"making_ship_move",
		"adding_input",
#		"adding_timer",
	],
}

@onready var sub_viewport: SubViewport = %SubViewport
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer
@onready var next_button: Button = %NextButton


func check() -> void:
	var practice_count := practices.size()
	for project_name in practices:
		for practice_name in practices[project_name]:
			await check_practice(practice_name, project_name)
			await next_button.pressed
			for node in checks_v_box_container.get_children():
				node.queue_free()
		break


func check_practice(dir_name: StringName, project_name: String) -> void:
	for node in sub_viewport.get_children():
		node.queue_free()

	var scene_name := "".join([dir_name, ".tscn"])
	var solution_scene := load(Builder.SOLUTIONS_PATH.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()
	sub_viewport.add_child(solution)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var practice_scene := load(Builder.PRACTICES_PATH.path_join(dir_name).path_join(scene_name))
	var practice: Node = practice_scene.instantiate()
	sub_viewport.add_child(practice)

	scene_name = "".join([dir_name, "_test.gd"])
	var test_script := load(Builder.SOLUTIONS_PATH.path_join(dir_name).path_join(scene_name))
	var test: Test = test_script.new()
	sub_viewport.add_child(test)
#
	title_rich_text_label.text = "Checking...\n[b]%s:%s[/b]" % [
		project_name,
		dir_name,
	].map(func(x: String) -> String: return x.capitalize())
	print_rich("\n%s" % title_rich_text_label.text)
	await test.setup(practice, solution)
	await test.run(checks_v_box_container)
