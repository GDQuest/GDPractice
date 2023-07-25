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


func _ready() -> void:
	Logger.setup(title_rich_text_label, checks_v_box_container)


func check() -> void:
	var practice_count := practices.size()
	for project_name in practices:
		for practice_name in practices[project_name]:
			await _check_practice(practice_name, project_name)
			await next_button.pressed
			for node in checks_v_box_container.get_children():
				node.queue_free()
		break


func _check_practice(dir_name: StringName, project_name: String) -> void:
	Logger.title("Checking...\n[b]%s:%s[/b]" % [
		project_name,
		dir_name,
	].map(func(x: String) -> String: return x.capitalize()))

	var practice_base_path := Builder.PRACTICES_PATH.path_join(dir_name)
	Requirements.setup(practice_base_path)
	# TODO: graceful exit
	if not Requirements.check():
		return

	for node in sub_viewport.get_children():
		node.queue_free()

	var scene_name := "".join([dir_name, ".tscn"])
	var solution_scene := load(Builder.SOLUTIONS_PATH.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()
	sub_viewport.add_child(solution)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var practice_scene := load(practice_base_path.path_join(scene_name))
	var practice: Node = practice_scene.instantiate()
	sub_viewport.add_child(practice)

	scene_name = "".join([dir_name, "_test.gd"])
	var test_script := load(Builder.SOLUTIONS_PATH.path_join(dir_name).path_join(scene_name))
	var test: Test = test_script.new()
	sub_viewport.add_child(test)

	await test.setup(practice, solution)
	await test.run()
