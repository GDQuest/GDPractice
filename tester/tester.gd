extends Control

@onready var sub_viewport: SubViewport = %SubViewport
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer


func _ready() -> void:
	Logger.setup(title_rich_text_label, checks_v_box_container)
	var info := _get_current_scene_info()
	var is_practice_scene: bool = (
		info.file_path.begins_with(Builder.PRACTICES_PATH)
		and "%s.tscn" % info.dir_name == info.file_name
	)
	if not is_practice_scene:
		Logger.log("Not a practice...[color=orange]SKIP[/color]")
		queue_free()
		return

	_move_practice.call_deferred(info)
	_check_practice.call_deferred(info)


func _get_current_scene_info() -> Dictionary:
	var result := {scene = get_tree().current_scene}
	result.file_path = result.scene.scene_file_path
	result.file_name = result.file_path.get_file()
	result.base_path = result.file_path.get_base_dir()
	result.dir_name = result.base_path.get_file()
	return result


func _to_solution(path: String) -> String:
	return path.replace(Builder.PRACTICES_PATH, Builder.SOLUTIONS_PATH)


func _move_practice(practice_info: Dictionary) -> void:
	get_tree().root.remove_child(practice_info.scene)
	sub_viewport.add_child(practice_info.scene)


func _check_practice(practice_info: Dictionary) -> void:
	Logger.title("Checking...\n[b]%s[/b]" % practice_info.file_name.get_basename().capitalize())

	Requirements.setup(practice_info.base_path)
	if not Requirements.check():
		return
#
	var solution_packed_scene := load(_to_solution(practice_info.file_path))
	var solution: Node = solution_packed_scene.instantiate()
	sub_viewport.add_child(solution)
	sub_viewport.move_child(solution, 0)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var test_script := load(
		_to_solution(practice_info.base_path)
		.path_join("%s_test.gd" % practice_info.file_name.get_basename())
	)
	var test: Test = test_script.new()
	sub_viewport.add_child(test)

	await test.setup(practice_info.scene, solution)
	await test.run()
