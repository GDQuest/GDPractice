@tool
extends PanelContainer

const UISelectablePractice := preload("ui_selectable_practice.gd")

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const Metadata := preload("../metadata/metadata.gd")
const MetadataList := preload("../metadata/metadata_list.gd")
const ThemeUtils := preload("../utils/theme_utils.gd")

const UI_SELECTABLE_PRACTICE_SCENE := preload("ui_selectable_practice.tscn")

var build := Build.new()
var metadata_list: MetadataList = load(Paths.SOLUTIONS_PATH.path_join("metadata_list.tres"))

@onready var list: VBoxContainer = %List
@onready var module_labels: Array[Label] = [%LabelModuleNumber, %LabelModuleName]
@onready var gdquest_logo: BaseButton = %GDQuestLogo


func _ready() -> void:
	for module_idx in range(metadata_list.metadatas.size()):
		for practice_idx in range(metadata_list.metadatas[module_idx].size()):
			var metadata: Metadata = metadata_list.metadatas[module_idx][practice_idx]
			var ui_selectable_practice = UI_SELECTABLE_PRACTICE_SCENE.instantiate()
			list.add_child(ui_selectable_practice)
			ui_selectable_practice.setup(metadata, module_idx, practice_idx)
	set_module_name()
	update()

	gdquest_logo.pressed.connect(OS.shell_open.bind("https://www.gdquest.com/"))

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	theme = ThemeUtils.generate_scaled_theme(theme)
	gdquest_logo.custom_minimum_size *= EditorInterface.get_editor_scale()


func get_practice_index(path: String) -> int:
	var result := -1
	path = Paths.to_solution(path)
	var metadata_path := path.get_base_dir().path_join("metadata.tres")
	if FileAccess.file_exists(path) and FileAccess.file_exists(metadata_path):
		var metadata: Metadata = load(path.get_base_dir().path_join("metadata.tres"))
		for scene_file_path in metadata.scene_file_paths:
			if path == scene_file_path:
				for idx in range(list.get_child_count()):
					if metadata == list.get_child(idx).metadata:
						result = idx
						break
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
