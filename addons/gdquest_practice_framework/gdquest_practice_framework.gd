@tool
extends EditorPlugin

const Utils := preload("utils.gd")

const ROOT_PATH := "res://"
const TEMPLATES_DIR := "script_templates/Test"

var ui_practice_dock := preload("ui/ui_practice_dock.tscn").instantiate()


func _enter_tree() -> void:
	scene_changed.connect(ui_practice_dock.select_practice)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, ui_practice_dock)
	add_autoload_singleton("Tester", "tester/tester.tscn")
	add_templates()


func _exit_tree() -> void:
	remove_templates()
	remove_autoload_singleton("Tester")
	scene_changed.disconnect(ui_practice_dock.select_practice)
	remove_control_from_docks(ui_practice_dock)


func add_templates() -> void:
	var plugin_dir_path: String = get_script().resource_path.get_base_dir()
	var plugin_template_dir_path := plugin_dir_path.path_join(TEMPLATES_DIR)
	for plugin_template_file_path in Utils.fs_find("*.gd", plugin_template_dir_path):
		var root_template_file_path = ROOT_PATH.path_join(TEMPLATES_DIR).path_join(
			plugin_template_file_path.get_file()
		)
		if (
			FileAccess.file_exists(root_template_file_path)
			and (
				FileAccess.get_modified_time(plugin_template_file_path)
				< FileAccess.get_modified_time(root_template_file_path)
			)
		):
			continue

		DirAccess.make_dir_recursive_absolute(root_template_file_path.get_base_dir())
		DirAccess.copy_absolute(plugin_template_file_path, root_template_file_path)


func remove_templates() -> void:
	var templates_base_dir_path := ROOT_PATH.path_join(TEMPLATES_DIR.get_base_dir())
	Utils.fs_remove_dir(ROOT_PATH.path_join(TEMPLATES_DIR))
	if Utils.fs_find("*", templates_base_dir_path).is_empty():
		Utils.fs_remove_dir(templates_base_dir_path)
