extends Control

var _practice_info := {}

@onready var sub_viewport: SubViewport = %SubViewport
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer


func _ready() -> void:
	Logger.setup(title_rich_text_label, checks_v_box_container)

	_practice_info.scene = get_tree().current_scene
	_practice_info.file_path = _practice_info.scene.scene_file_path
	_practice_info.file_name = _practice_info.file_path.get_file()
	_practice_info.base_path = _practice_info.file_path.get_base_dir()
	_practice_info.dir_name = _practice_info.base_path.get_file()
	var is_practice_scene: bool = (
		_practice_info.file_path.begins_with(Builder.PRACTICES_PATH)
		and "%s.tscn" % _practice_info.dir_name == _practice_info.file_name
	)
	if not is_practice_scene:
		Logger.log("Not a practice...[color=orange]SKIP[/color]")
		queue_free()
		return

	_move_practice.call_deferred()
	_check_practice.call_deferred()


func _move_practice() -> void:
	get_tree().root.remove_child(_practice_info.scene)
	sub_viewport.add_child(_practice_info.scene)


func _check_practice() -> void:
	Logger.title("Checking...\n[b]%s[/b]" % _practice_info.file_name.get_basename().capitalize())

	Requirements.setup(_practice_info.base_path)
	if not Requirements.check():
		return
#
	var solution_packed_scene := load(_to_solution(_practice_info.file_path))
	var solution: Node = solution_packed_scene.instantiate()
	sub_viewport.add_child(solution)
	sub_viewport.move_child(solution, 0)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var test_script := load(
		_to_solution(_practice_info.base_path)
		.path_join("%s_test.gd" % _practice_info.file_name.get_basename())
	)
	var test: Test = test_script.new()
	sub_viewport.add_child(test)

	await test.setup(_practice_info.scene, solution)
	await test.run()


static func _to_solution(path: String) -> String:
	return path.replace(Builder.PRACTICES_PATH, Builder.SOLUTIONS_PATH)
