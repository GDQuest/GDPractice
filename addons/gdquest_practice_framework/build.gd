#!/usr/bin/env -S godot --headless --script
## Build script that converts solutions into practices. On Linux run with:
##
## [codeblock]
## # might need to run:
## chmod +x build.gd
## ./build.gd
## [/codeblock]
##
## The build script also processes practice code lines by replacing them with the given
## comments at the end of the line in [b]GDScript[/b] files.
##
## [codeblock]
## position += delta * velocity # position
## [/codeblock]
##
## Results in the following practice code:
##
## [codeblock]
## position
## [/codeblock]
##
## In some cases we want to remove the line completely for more complex code. Empty comments at
## the end of the line result in deletion of the line in the practice GDScript file.
##
## Furthermore, we can use a special syntax like [code]# >[/code] and [code]# <[/code] to indent
## and respectively dedent the given line of code in the practice script, otherwise the indentation
## is preserved:
##
## [codeblock]
## func generate_gems(columns: int, rows: int) -> void:
##     # Add two nested loops to generate cell coordinates.
##     # Generate the columns with the first loop and the rows with the second.
##
##     # You'll need to indent the lines below to be inside the inner loop block.
##     # You can select the lines with the mouse and press Tab to do so.
##     # Update the cell value to represent the cell coordinates on each loop iteration.
##     for column in range(columns): #
##         for row in range(rows): #
##             var cell := Vector2(column, row) # << var cell := Vector2(0, 0)
##             generate_one_gem(cell) # << generate_one_gem(cell)
## [/codeblock]
##
## Results in the following practice code:
##
## [codeblock]
## func generate_gems(columns: int, rows: int) -> void:
##     # Add two nested loops to generate cell coordinates.
##     # Generate the columns with the first loop and the rows with the second.
##
##     # You'll need to indent the lines below to be inside the inner loop block.
##     # You can select the lines with the mouse and press Tab to do so.
##     # Update the cell value to represent the cell coordinates on each loop iteration.
##     var cell := Vector2(0, 0)
##     generate_one_gem(cell)
## [/codeblock]
##
## The build script [b]fails[/b] if there are solutions with no [code]metadata.tres[/code] file.[br]
## [br]
## [b]Note[/b] that:[br]
## - Only-comment lines are also preserved in the practice.[br]
## - The special [code]<[/code] and [code]>[/code] symbols can be repeated multiple times.
extends SceneTree

const Paths := preload("paths.gd")
const Utils := preload("utils.gd")
const Metadata := preload("metadata/metadata.gd")

const DENTS := {"<": -1, ">": 1}
const LOG_MESSAGE := "\t%s...%s"

enum Continuation { STOP, CONTINUE }

var regex_line := RegEx.create_from_string("^(\\h*)(.*)#\\h*(.*)$")
var regex_shift := RegEx.create_from_string("^([<>]+)\\h*(.*)")


func _init() -> void:
	var user_args := OS.get_cmdline_user_args()
	if "--practice-project" in user_args:
		build_project("practice", ["plug.gd", "makefile", ".import"])
	if "--lesson-project" in user_args:
		build_project("lesson", ["plug.gd", "makefile", ".import"])
	if "--practices" in user_args:
		build_practices(true)
	quit()


func build_project(suffix: String, exclude: Array[String] = []) -> void:
	const EXE := "godot"

	var lessons_dir_path := Paths.RES.path_join("lessons_reference")
	var plugin_dir_path: String = get_script().resource_path.get_base_dir()
	var solution_dir_path := plugin_dir_path.path_join(Paths.SOLUTIONS_PATH.get_file())

	var source_project_dir_path := ProjectSettings.globalize_path(Paths.RES).get_base_dir()
	var source_solution_dir_path := ProjectSettings.globalize_path(Paths.SOLUTIONS_PATH)
	var destination_project_dir_path := "%s_%s" % [source_project_dir_path, suffix]
	var destination_plugin_dir_path := ProjectSettings.globalize_path(plugin_dir_path).replace(
		source_project_dir_path, destination_project_dir_path
	)

	var predicate := func(p: String) -> bool:
		return not (
			(suffix == "lesson" and (p.begins_with(Paths.SOLUTIONS_PATH) or p.begins_with(plugin_dir_path)))
			or p.begins_with(Paths.PRACTICES_PATH)
			or p.begins_with(lessons_dir_path)
			or exclude.any(func(e: String) -> bool: return (p.ends_with(e)))
		)
	var source_file_paths := Utils.fs_find().filter(predicate)
	for source_file_path: String in source_file_paths:
		source_file_path = ProjectSettings.globalize_path(source_file_path)
		var destination_file_path := source_file_path.replace(
			source_project_dir_path, destination_project_dir_path
		)
		if source_file_path.begins_with(source_solution_dir_path):
			destination_file_path = source_file_path.replace(
				source_project_dir_path, destination_plugin_dir_path
			)
		DirAccess.make_dir_recursive_absolute(destination_file_path.get_base_dir())
		DirAccess.copy_absolute(source_file_path, destination_file_path)

		var extension := source_file_path.get_extension()
		var do_replace := (
			destination_file_path == destination_plugin_dir_path.path_join("paths.gd")
			or (
				source_file_path.begins_with(source_solution_dir_path)
				and extension in ["gd", "tscn", "tres"]
			)
		)
		if do_replace:
			var contents := FileAccess.get_file_as_string(destination_file_path)
			contents = contents.replace(Paths.SOLUTIONS_PATH, solution_dir_path)
			FileAccess.open(destination_file_path, FileAccess.WRITE).store_string(contents)
	Utils.fs_remove_dir(
		source_solution_dir_path.replace(source_project_dir_path, destination_project_dir_path)
	)

	var args := ["--path", destination_project_dir_path, "--headless"]
	if suffix == "practice":
		var output := []
		OS.execute(
			EXE,
			args + ["--script", plugin_dir_path.path_join("build.gd"), "--", "--practices"],
			output,
			true
		)
		for line: String in output:
			print_rich(line)
	OS.execute(EXE, args + ["--editor", "--quit-after", 60])


func build_practices(do_enable_plugins := false) -> void:
	const PROJECT_FILE := "project.godot"
	const SECTION := "editor_plugins"
	const KEY := "enabled"
	const CFG_FILE_NAME := "plugin.cfg"
	const ADDONS_DIR_NAME := "addons"

	var cfg := ConfigFile.new()
	if do_enable_plugins:
		cfg.load(PROJECT_FILE)
		cfg.set_value(SECTION, KEY, PackedStringArray())
		cfg.save(PROJECT_FILE)

	for dir_name in DirAccess.get_directories_at(Paths.SOLUTIONS_PATH):
		if build_practice(dir_name) == Continuation.STOP:
			break

	if do_enable_plugins:
		var plugin_cfg_paths := Utils.fs_find(CFG_FILE_NAME, Paths.RES.path_join(ADDONS_DIR_NAME))
		cfg.set_value(SECTION, KEY, PackedStringArray(plugin_cfg_paths))
		cfg.save(PROJECT_FILE)


func build_practice(dir_name: StringName, is_forced := false) -> Continuation:
	print_rich("Building [b]%s[/b]..." % dir_name)
	var solution_dir_path := Paths.SOLUTIONS_PATH.path_join(dir_name)
	var solution_file_paths := Utils.fs_find("*", solution_dir_path)
	var metadata_file_path := solution_dir_path.path_join("metadata.tres")

	var do_exit := false
	if FileAccess.file_exists(metadata_file_path):
		var metadata: Metadata = load(metadata_file_path)
		do_exit = metadata.title.is_empty() or metadata.id.is_empty()
	else:
		do_exit = true

	if do_exit:
		print_rich(LOG_MESSAGE % [metadata_file_path, "[color=red]FAIL[/color]"])
		return Continuation.STOP

	solution_file_paths.assign(
		solution_file_paths.filter(
			func(x: String) -> bool: return not (
				x.ends_with("/test.gd")
				or x.ends_with("/diff.gd")
				or x.ends_with("/metadata.tres")
				or x.get_extension() == "import"
			)
		)
	)

	if solution_file_paths.is_empty():
		print_rich(LOG_MESSAGE % ["Nothing to do", "[color=orange]SKIP[/color]"])

	var solution_diff_path := solution_dir_path.path_join("diff.gd")
	var solution_diff: GDScript = null
	if FileAccess.file_exists(solution_diff_path):
		solution_diff = load(solution_diff_path)

	for solution_file_path in solution_file_paths:
		var extension := solution_file_path.get_extension()
		var practice_file_path: String = solution_file_path.replace(
			Paths.SOLUTIONS_PATH, Paths.PRACTICES_PATH
		)
		var practice_file_modified_time := FileAccess.get_modified_time(practice_file_path)
		if (
			(
				FileAccess.file_exists(practice_file_path)
				and practice_file_modified_time > FileAccess.get_modified_time(solution_file_path)
				and practice_file_modified_time > FileAccess.get_modified_time(solution_diff_path)
			)
			and not is_forced
		):
			print_rich(LOG_MESSAGE % [practice_file_path, "[color=orange]SKIP[/color]"])
			continue

		DirAccess.make_dir_recursive_absolute(practice_file_path.get_base_dir())
		if extension == "tscn" and solution_diff != null:
			var solution_scene: Node = load(solution_file_path).instantiate()
			var func_name := solution_file_path.get_file().get_basename()
			if func_name in solution_diff:
				solution_diff.call(func_name, solution_scene)
				var practice_packed_scene := PackedScene.new()
				practice_packed_scene.pack(solution_scene)
				ResourceSaver.save(practice_packed_scene, practice_file_path)
				print_rich(LOG_MESSAGE % [solution_file_path, "[color=blue]DIFF[/color]"])

		else:
			DirAccess.copy_absolute(solution_file_path, practice_file_path)
			print_rich(LOG_MESSAGE % [practice_file_path, "[color=green]COPY[/color]"])

		if extension in ["gd", "tscn", "tres"]:
			var contents := FileAccess.get_file_as_string(practice_file_path)
			if extension == "gd":
				contents = _process_gd(contents)
			contents = Paths.to_practice(contents)
			FileAccess.open(practice_file_path, FileAccess.WRITE).store_string(contents)
			print_rich(LOG_MESSAGE % [practice_file_path, "[color=yellow]PROCESS[/color]"])

	return Continuation.CONTINUE


func _process_gd(contents: String) -> String:
	var partial_result := []
	for line in contents.split("\n"):
		var processed := _process_line(line)
		if processed.do_skip:
			continue
		partial_result.push_back(processed.line)
	return "\n".join(partial_result).strip_edges() + "\n"


func _process_line(line: String) -> Dictionary:
	var result := {line = line, do_skip = false}
	var regex_line_match := regex_line.search(line)
	if regex_line_match != null and not regex_line_match.strings[2].is_empty():
		result.line = _process_tabs(
			regex_line_match.strings[1], regex_line_match.strings[3].strip_edges()
		)
		result.do_skip = not line.strip_edges().is_empty() and result.line.strip_edges().is_empty()
	return result


func _process_tabs(prefix: String, line: String) -> String:
	var tabs := prefix.count("\t")
	var regex_shift_match := regex_shift.search(line)
	if regex_shift_match != null:
		for shift in regex_shift_match.strings[1]:
			tabs += DENTS[shift]
		line = regex_shift_match.strings[2]
	return "\t".repeat(tabs) + line
