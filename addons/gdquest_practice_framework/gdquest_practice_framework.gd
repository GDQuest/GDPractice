@tool
extends EditorPlugin

const Metadata := preload("metadata.gd")
const Paths := preload("paths.gd")
const UISolutionWarning := preload("ui/ui_solution_warning.gd")
const Utils := preload("../gdquest_sparkly_bag/sparkly_bag_utils.gd")

const PracticeMetadata := Metadata.PracticeMetadata

const ROOT_PATH := "res://"
const TEMPLATES_DIR := "script_templates/Test"

var metadata: Array[PracticeMetadata] = Metadata.load()

var editor_run_bar: MarginContainer = null

var ui_practice_dock := preload("ui/ui_practice_dock.tscn").instantiate()
var ui_solution_warning: UISolutionWarning = preload("ui/ui_solution_warning.tscn").instantiate()


func _enter_tree() -> void:
	scene_changed.connect(_on_scene_changed)
	EditorInterface.get_editor_main_screen().add_child(ui_solution_warning)

	editor_run_bar = EditorInterface.get_base_control().find_child("*EditorRunBar*", true, false)
	editor_run_bar.stop_pressed.connect(ui_practice_dock.update)
	scene_changed.connect(ui_practice_dock.select_practice)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, ui_practice_dock)
	add_autoload_singleton("Tester", "tester/ui_test_panel.tscn")
	# Removed for now because this should not happen to the user's project. It's a tool for teachers creating practices.
	# add_templates()


func _exit_tree() -> void:
	editor_run_bar.stop_pressed.disconnect(ui_practice_dock.update)
	# remove_templates()
	remove_autoload_singleton("Tester")
	scene_changed.disconnect(ui_practice_dock.select_practice)
	remove_control_from_docks(ui_practice_dock)
	ui_practice_dock.queue_free()
	ui_solution_warning.queue_free()


func _on_scene_changed(scene_root: Node) -> void:
	var is_solution := scene_root != null
	is_solution = is_solution and scene_root.scene_file_path.begins_with(Paths.SOLUTIONS_PATH)
	ui_solution_warning.visible = is_solution
	if not is_solution:
		return

	var solution_file_path := scene_root.scene_file_path
	var solution_dir_path := solution_file_path.get_base_dir()
	var predicate := func(m: PracticeMetadata) -> bool: return m.main_scene.begins_with(
		solution_dir_path
	)
	for pm: PracticeMetadata in metadata.filter(predicate):
		var practice_title := "L%d.P%d %s" % [pm.lesson_number, pm.practice_number, pm.title]
		ui_solution_warning.set_text(
			solution_file_path, Paths.to_practice(pm.main_scene), practice_title
		)


## Copies practice template scripts to the project root directory.
func add_templates() -> void:
	var plugin_dir_path: String = get_script().resource_path.get_base_dir()
	var plugin_template_dir_path := plugin_dir_path.path_join(TEMPLATES_DIR)
	var found := Utils.fs_find("*.gd", plugin_template_dir_path)
	if found.return_code != Utils.ReturnCode.OK:
		return

	for plugin_template_file_path: String in found.result:
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


## Removes practice template scripts from the project.
func remove_templates() -> void:
	var templates_base_dir_path := ROOT_PATH.path_join(TEMPLATES_DIR.get_base_dir())
	Utils.fs_remove_dir(ROOT_PATH.path_join(TEMPLATES_DIR))
	if Utils.fs_find("*", templates_base_dir_path).result.is_empty():
		Utils.fs_remove_dir(templates_base_dir_path)
