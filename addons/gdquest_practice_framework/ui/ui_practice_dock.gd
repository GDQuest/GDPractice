@tool
extends VBoxContainer

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const Metadata := preload("../metadata.gd")

const MetadataList := preload("../metadata_list.gd")
const UISelectablePractice := preload("ui_selectable_practice.gd")

const UI_SELECTABLE_PRACTICE_SCENE := preload("ui_selectable_practice.tscn")

const TSCN_EXT := ".tscn"
const TRES_EXT := ".tres"

var build := Build.new()

@onready var list: VBoxContainer = %List
@onready var footer: HBoxContainer = %Footer
@onready var run_button: Button = %RunButton
@onready var reset_button: Button = %ResetButton


func _ready() -> void:
	run_button.pressed.connect(run_practice)
	reset_button.pressed.connect(reset_practice)
	for metadata_path: String in MetadataList.METADATA_PATHS:
		var ui_selectable_practice: UISelectablePractice = (
			UI_SELECTABLE_PRACTICE_SCENE.instantiate()
		)
		ui_selectable_practice.pressed.connect(_on_ui_selectable_practice_pressed)
		list.add_child(ui_selectable_practice)
		ui_selectable_practice.setup(metadata_path)
	update()


func _on_ui_selectable_practice_pressed() -> void:
	for footer_button: Button in footer.get_children():
		footer_button.disabled = false


func run_practice() -> void:
	for practice_path: String in get_practice_paths():
		EditorInterface.play_custom_scene(practice_path)
		break


func reset_practice() -> void:
	var ui_selectable_practice: UISelectablePractice = (
		UISelectablePractice.button_group.get_pressed_button().get_parent()
	)

	var db := DB.new()
	db.progress.state[ui_selectable_practice.metadata.id].completion = 0
	db.save()
	ui_selectable_practice.update(db.progress)

	var metadata_path := MetadataList.METADATA_PATHS[ui_selectable_practice.get_index()]
	var solution_dir_name := metadata_path.get_base_dir().get_file()
	build.build_practice(solution_dir_name, true)


func get_practice_paths(index := -1) -> Array[String]:
	if index == -1:
		index = UISelectablePractice.button_group.get_pressed_button().get_parent().get_index()
	return list.get_child(index).metadata.scene_file_paths


func get_practice_index(path: String) -> int:
	var result := -1
	for metadata_path: String in MetadataList.METADATA_PATHS.filter(
		func(x: String) -> bool: return x.begins_with(path)
	):
		result = MetadataList.METADATA_PATHS.find(metadata_path)
	return result


func select_practice(scene_root: Node) -> void:
	deselect()
	if (
		scene_root == null
		or (
			scene_root != null
			and (scene_root.scene_file_path.is_empty() or scene_root.get_script() == null)
		)
	):
		return
	var script_path: String = scene_root.get_script().resource_path
	var index := get_practice_index(script_path.get_base_dir())
	if index != -1:
		list.get_child(index).select(script_path.begins_with(Paths.SOLUTIONS_PATH))


func deselect() -> void:
	for ui_selectable_practice in list.get_children():
		ui_selectable_practice.deselect()

	for footer_button: Button in footer.get_children():
		footer_button.disabled = true


func update() -> void:
	var db := DB.new()
	for ui_selectable_practice in list.get_children():
		ui_selectable_practice.update(db.progress)
