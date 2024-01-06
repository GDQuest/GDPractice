@tool
extends VBoxContainer

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const SolutionsList := preload("../solutions_list.gd")
const UISelectablePractice := preload("ui_selectable_practice.gd")

const UI_SELECTABLE_PRACTICE_SCENE := preload("ui_selectable_practice.tscn")

const GD_EXT := ".gd"
const TSCN_EXT := ".tscn"

var build := Build.new()

@onready var list: VBoxContainer = %List
@onready var footer: HBoxContainer = %Footer
@onready var run_button: Button = %RunButton
@onready var reset_button: Button = %ResetButton


func _ready() -> void:
	run_button.pressed.connect(run_practice)
	reset_button.pressed.connect(reset_practice)
	for Solution in SolutionsList.SOLUTIONS:
		var ui_selectable_practice: UISelectablePractice = UI_SELECTABLE_PRACTICE_SCENE.instantiate()
		ui_selectable_practice.pressed.connect(_on_ui_selectable_practice_pressed)
		list.add_child(ui_selectable_practice)
		ui_selectable_practice.setup()
		var metadata: PracticeMetadata = Solution.new().metadata
		ui_selectable_practice.title = metadata.title
		ui_selectable_practice.id = metadata.id
		ui_selectable_practice.solution_dir_name = Solution.resource_path.get_base_dir().get_file()
		ui_selectable_practice.is_free = FileAccess.file_exists(solution_to_practice_path(Solution.resource_path))
		ui_selectable_practice.is_locked = not ui_selectable_practice.is_free
	update()


func _on_ui_selectable_practice_pressed(index: int) -> void:
	EditorInterface.open_scene_from_path(get_practice_path(index))
	for footer_button: Button in footer.get_children():
		footer_button.disabled = false


func run_practice() -> void:
	EditorInterface.play_custom_scene(get_practice_path())


func reset_practice() -> void:
	var ui_selectable_practice := UISelectablePractice.button_group.get_pressed_button().get_parent()
	var db := DB.new()
	db.progress.state[ui_selectable_practice.id].completion = 0
	db.save()
	ui_selectable_practice.update(db.progress)
	build.build_solution(ui_selectable_practice.solution_dir_name, true)


static func solution_to_practice_path(path: String) -> String:
	return path.replace(Paths.SOLUTIONS_PATH, Paths.PRACTICES_PATH).replace(GD_EXT, TSCN_EXT)


func get_practice_path(index := -1) -> String:
	if index == -1:
		index = UISelectablePractice.button_group.get_pressed_button().get_parent().get_index()
	return solution_to_practice_path(SolutionsList.SOLUTIONS[index].resource_path)


func get_practice_index(path: String) -> int:
	var result := -1
	for Solution in SolutionsList.SOLUTIONS.filter(func(x: Script) -> bool: return (x.resource_path == path)):
		result = SolutionsList.SOLUTIONS.find(Solution)
	return result


func select_practice(scene_root: Node) -> void:
	deselect()
	if (
		scene_root == null
		or (
			scene_root != null
			and (
				scene_root.scene_file_path.begins_with(Paths.SOLUTIONS_PATH)
				or scene_root.scene_file_path.is_empty()
				or scene_root.get_script() == null
			)
		)
	):
		return
	var path: String = scene_root.get_script().resource_path.replace(Paths.PRACTICES_PATH, Paths.SOLUTIONS_PATH)
	var index := get_practice_index(path)
	if index != -1:
		list.get_child(index).select()


func deselect() -> void:
	for ui_selectable_practice in list.get_children():
		ui_selectable_practice.deselect()

	for footer_button: Button in footer.get_children():
		footer_button.disabled = true


func update() -> void:
	var db := DB.new()
	for ui_selectable_practice in list.get_children():
		ui_selectable_practice.update(db.progress)
