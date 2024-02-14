@tool
extends PanelContainer

const UISelectablePractice := preload("ui_selectable_practice.gd")

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const Metadata := preload("../metadata.gd")
const ThemeUtils := preload("../utils/theme_utils.gd")

const UI_SELECTABLE_PRACTICE_SCENE := preload("ui_selectable_practice.tscn")

var metadata_modified_time := 0
var build := Build.new()

@onready var list: VBoxContainer = %List
@onready var module_labels: Array[Label] = [%LabelModuleNumber, %LabelModuleName]
@onready var gdquest_logo: BaseButton = %GDQuestLogo


func _ready() -> void:
	gdquest_logo.pressed.connect(OS.shell_open.bind("https://www.gdquest.com/"))
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(construct_panel_list)
	construct_panel_list()
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	theme = ThemeUtils.generate_scaled_theme(theme)
	for control: Control in find_children("", "TextureRect") + find_children("", "TextureButton"):
		control.custom_minimum_size *= EditorInterface.get_editor_scale()


func construct_panel_list() -> void:
	var new_metadata_modified_time := Metadata.get_modified_time()
	if metadata_modified_time == new_metadata_modified_time:
		return

	metadata_modified_time = new_metadata_modified_time
	for ui_selectable_practice: UISelectablePractice in list.get_children():
		ui_selectable_practice.queue_free()

	var metadata := Metadata.load()
	for practice_metadata: Metadata.PracticeMetadata in metadata:
		var ui_selectable_practice = UI_SELECTABLE_PRACTICE_SCENE.instantiate()
		list.add_child(ui_selectable_practice)
		ui_selectable_practice.setup(practice_metadata)
	set_module_name()
	update()


func get_practice_index(path: String) -> int:
	var result := -1
	if not path.begins_with(Paths.PRACTICES_PATH):
		return result

	path = Paths.to_solution(path)
	var checker := func(p: PackedScene) -> bool: return path == p.resource_path
	for idx in range(list.get_child_count()):
		var ui_selectable_practice: UISelectablePractice = list.get_child(idx)
		if path == ui_selectable_practice.practice_metadata.main_scene:
			result = idx
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


func update() -> void:
	var db := DB.new()
	for ui_selectable_practice in list.get_children():
		ui_selectable_practice.update(db.progress)


func set_module_name() -> void:
	const SUFFIX := "(Workbook)"
	var project_name: String = ProjectSettings.get_setting("application/config/name")
	if not project_name.is_empty():
		var module_info := project_name.replace(SUFFIX, "").strip_edges().split(".")
		var module_info_size := module_info.size()
		if module_info_size != module_labels.size():
			return

		for idx in range(module_info_size):
			module_labels[idx].text = ("%s." % module_info[idx]) if idx == 0 else module_info[idx]
