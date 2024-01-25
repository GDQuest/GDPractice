@tool
extends VBoxContainer

const UISelectablePractice := preload("ui_selectable_practice.gd")

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const Metadata := preload("../metadata/metadata.gd")
const MetadataList := preload("../metadata/metadata_list.gd")

const UI_SELECTABLE_PRACTICE_SCENE := preload("ui_selectable_practice.tscn")

var button_group: ButtonGroup = null

var build := Build.new()
var metadata_list: MetadataList = load(Paths.SOLUTIONS_PATH.path_join("metadata_list.tres"))

@onready var list: VBoxContainer = %List
@onready var footer: HBoxContainer = %Footer
@onready var run_button: Button = %RunButton
@onready var reset_button: Button = %ResetButton


func _ready() -> void:
	button_group = ButtonGroup.new()
	run_button.pressed.connect(run_practice)
	reset_button.pressed.connect(reset_practice)
	for metadata in metadata_list.metadatas:
		var ui_selectable_practice = UI_SELECTABLE_PRACTICE_SCENE.instantiate()
		ui_selectable_practice.setup(metadata, button_group)
		list.add_child(ui_selectable_practice)
		ui_selectable_practice.pressed.connect(_on_ui_selectable_practice_pressed)
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
		button_group.get_pressed_button().get_parent()
	)

	var db := DB.new()
	db.progress.state[ui_selectable_practice.metadata.id].completion = 0
	db.save()
	ui_selectable_practice.update(db.progress)

	var metadata_path := metadata_list.metadatas[ui_selectable_practice.get_index()].resource_path
	var solution_dir_name := metadata_path.get_base_dir().get_file()
	build.build_practice(solution_dir_name, true)


func get_practice_paths(index := -1) -> Array[String]:
	var result: Array[String] = []
	if index == -1:
		index = button_group.get_pressed_button().get_parent().get_index()
	result.assign(
		list.get_child(index).metadata.scene_file_paths.map(
			func(x: String) -> String: return Paths.to_practice(x)
		)
	)
	return result


func get_practice_index(path: String) -> int:
	var result := -1
	path = Paths.to_solution(path)
	var metadata_path := path.get_base_dir().path_join("metadata.tres")
	if FileAccess.file_exists(path) and FileAccess.file_exists(metadata_path):
		var metadata: Metadata = load(path.get_base_dir().path_join("metadata.tres"))
		for scene_file_path in metadata.scene_file_paths:
			if path == scene_file_path:
				result = metadata_list.metadatas.find(metadata)
			break
	return result


func select_practice(scene_root: Node) -> void:
	deselect()
	if scene_root == null or (scene_root != null and scene_root.scene_file_path.is_empty()):
		return
	var index := get_practice_index(scene_root.scene_file_path)
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
