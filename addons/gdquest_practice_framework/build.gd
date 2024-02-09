## Build script that converts solutions into practices and optionally generates Godot project folders for course modules.
##
## [b]Usage[/b]:
## [codeblock]
## godot --headless --script addons/gdquest_practice_framework/build.gd -- arg1 arg2 ...
## [/codeblock]
##
## Run with [code]--help[/code] to see the available arguments.
##
## [b]Generating practice starting files with the build script[/b]:
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
## [b]Note[/b] that:
##
## - Only-comment lines are also preserved in the practice.
## - The special [code]<[/code] and [code]>[/code] symbols can be repeated multiple times.
extends SceneTree

const Paths := preload("paths.gd")
const Utils := preload("utils.gd")

const PROJECT_FILE := "project.godot"
const PLUGINS_SECTION := "editor_plugins"
const AUTOLOAD_SECTION := "autoload"
const APP_SECTION := "application"
const APP_NAME_KEY := "config/name"

const DENTS := {"<": -1, ">": 1}
const LOG_MESSAGE := "\t%s...%s"

enum ReturnCode { OK, FAIL, RETURN_CODE_NOT_FOUND=127 }

var regex_line := RegEx.create_from_string("^(\\h*)(.*)#\\h*(.*)$")
var regex_shift := RegEx.create_from_string("^([<>]+)\\h*(.*)")


func _init() -> void:
	if "--script" in OS.get_cmdline_args():
		parse_command_line_arguments()


func parse_command_line_arguments() -> void:
	const ARG_HELP := ["-h", "--help"]
	const ARG_GENERATE_PROJECT_WORKBOOK := ["-w", "--generate-project-workbook"]
	const ARG_GENERATE_PROJECT_SOLUTIONS := ["-s", "--generate-project-solutions"]
	const ARG_PRACTICES := ["-p", "--generate-practices"]
	const ARG_DISABLE_PLUGIN := ["--disable-plugins"]
	const ARG_OUTPUT_PATH := ["-o", "--output-path"]
	var supported_args := [ARG_HELP, ARG_GENERATE_PROJECT_SOLUTIONS, ARG_GENERATE_PROJECT_WORKBOOK, ARG_PRACTICES, ARG_OUTPUT_PATH, ARG_DISABLE_PLUGIN]
	var help_message := "\n".join([
		"Build script that converts solutions into practices and optionally generates Godot project folders for course modules.",
		"Note: The script must be run from the root folder of the Godot project.",
		"",
		"Usage:",
		"",
		"[color=yellow]godot --headless --script addons/gdquest_practice_framework/build.gd -- [ARGS] ...[/color]",
		"",
		"ARGS:",
		"",
		"  [color=yellow]%s[/color]: Display this help message.",
		"  [color=yellow]%s[/color]: Generates a Godot project folder for the practice module.",
		"  [color=yellow]%s[/color]: Generates a Godot project folder for the lesson module and practices start files.",
		"  [color=yellow]%s[/color]: Generates practice files from solutions within this project (for testing).",
		"  [color=yellow]%s[/color]: Disable plugins.",
		"  [color=yellow]%s[/color]: Output directory path.",
	]) % supported_args.map(func(a: Array) -> String: return ", ".join(a))

	var user_args := OS.get_cmdline_user_args()
	for arg in ARG_HELP:
		if user_args.is_empty() or arg in user_args:
			print_rich(help_message)
			quit()
			return

	var args := {}
	var flat_supported_args := supported_args.reduce(func(acc: Array, a: Array) -> Array: return acc + a, [])
	for arg in user_args:
		var parts := arg.split("=")
		var key := parts[0]
		args[key] = parts[1] if parts.size() == 2 else null
		if not key in flat_supported_args:
			print_rich("[color=red]ERROR: Unknown command-line argument '%s' (supported arguments: %s). Skipping[/color]" % [key, supported_args])

	if not ("-o" in args or "--output-path" in args):
		args["--output-path"] = ""

	var return_code := ReturnCode.OK
	for key in args:
		if key in ARG_GENERATE_PROJECT_WORKBOOK:
			return_code = build_project("workbook", args["--output-path"], ["plug.gd", "makefile", ".import"])

		if key in ARG_GENERATE_PROJECT_SOLUTIONS:
			return_code = build_project("solutions", args["--output-path"], ["plug.gd", "makefile", ".import", "test.gd", "diff.gd",])

		if key in ARG_PRACTICES:
			var do_disable_plugins := "--disable-plugins" in user_args
			return_code = build_practices(do_disable_plugins)

		if return_code != ReturnCode.OK:
			break

	if return_code != ReturnCode.OK:
		printerr("FAIL")
	quit(return_code)


func build_project(suffix: String, output_path: String, exclude_slugs: Array[String] = []) -> ReturnCode:
	var return_code := ReturnCode.OK
	const EXE := "godot"

	var plugin_dir_path: String = get_script().resource_path.get_base_dir()
	var solution_dir_path := plugin_dir_path.path_join(Paths.SOLUTIONS_PATH.get_file())

	var source_project_dir_path := ProjectSettings.globalize_path(Paths.RES).get_base_dir()
	var source_solution_dir_path := ProjectSettings.globalize_path(Paths.SOLUTIONS_PATH)
	var destination_project_dir_path := "%s_%s" % [source_project_dir_path, suffix] if output_path == "" else output_path.path_join("%s_%s" % [source_project_dir_path.get_file(), suffix])
	var destination_plugin_dir_path := ProjectSettings.globalize_path(plugin_dir_path).replace(
		source_project_dir_path, destination_project_dir_path
		)
	var lessons_reference_dir_path := Paths.RES.path_join("lessons_reference")
	var script_templates_dir_path = Paths.RES.path_join("script_templates")
	var should_be_copied := func(path: String) -> bool:
		var path_starts_to_exclude := [Paths.PRACTICES_PATH, script_templates_dir_path]
		if suffix == "solutions":
			path_starts_to_exclude.append(plugin_dir_path)
		elif suffix == "workbook":
			path_starts_to_exclude.append(lessons_reference_dir_path)
		return not (
			path_starts_to_exclude.any(func(path_start: String) -> bool: return path.begins_with(path_start))
			or exclude_slugs.any(func(slug: String) -> bool: return (path.ends_with(slug)))
		)
	var source_file_paths := Utils.fs_find().filter(should_be_copied)
	for source_file_path: String in source_file_paths:
		source_file_path = ProjectSettings.globalize_path(source_file_path)
		var destination_file_path := source_file_path.replace(
			source_project_dir_path, destination_project_dir_path
		)
		if suffix == "workbook" and source_file_path.begins_with(source_solution_dir_path):
			destination_file_path = source_file_path.replace(
				source_project_dir_path, destination_plugin_dir_path
			)
		DirAccess.make_dir_recursive_absolute(destination_file_path.get_base_dir())
		DirAccess.copy_absolute(source_file_path, destination_file_path)

		var extension := source_file_path.get_extension()
		var do_replace := (
			destination_file_path == destination_plugin_dir_path.path_join("paths.gd")
			or (suffix == "workbook" and source_file_path.begins_with(source_solution_dir_path) and extension in ["gd", "tscn", "tres"])
		)
		if do_replace:
			var contents := FileAccess.get_file_as_string(destination_file_path)
			contents = contents.replace(Paths.SOLUTIONS_PATH, solution_dir_path)
			FileAccess.open(destination_file_path, FileAccess.WRITE).store_string(contents)

	var project_file_path := destination_project_dir_path.path_join(PROJECT_FILE)
	var cfg = ConfigFile.new()
	cfg.load(project_file_path)
	cfg.set_value(APP_SECTION, APP_NAME_KEY, "%s (%s)" % [ProjectSettings.get_setting(APP_SECTION.path_join(APP_NAME_KEY)), suffix.capitalize()])
	for section in [PLUGINS_SECTION, AUTOLOAD_SECTION]:
		if cfg.has_section(section):
			cfg.erase_section(section)
	cfg.save(project_file_path)

	# If generating the workbook project, ensure lessons directory is present and generate practice files from solutions.
	if suffix == "workbook":
		Utils.fs_remove_dir(
			source_solution_dir_path.replace(source_project_dir_path, destination_project_dir_path)
		)

		if not DirAccess.dir_exists_absolute(destination_project_dir_path.path_join("lessons")):
			DirAccess.make_dir_recursive_absolute(destination_project_dir_path.path_join("lessons"))

		var output := []
		return_code = OS.execute(
			EXE,
			["--path", destination_project_dir_path, "--headless", "--script", plugin_dir_path.path_join("build.gd"), "--", "--generate-practices", "--disable-plugins"],
			output,
			true
		)
		if return_code == ReturnCode.RETURN_CODE_NOT_FOUND:
			print_rich("[color=red]ERROR: Godot 4 executable expected at '%s' but not found. Aborting.[/color]" % EXE)

		if output.any(func(s: String) -> bool: return 'FAIL' in s):
			return_code = ReturnCode.FAIL
			Utils.fs_remove_dir(destination_project_dir_path)

		for line: String in output:
			print_rich(line)

	return return_code


func build_practices(do_disable_plugins := false) -> ReturnCode:
	var result := ReturnCode.OK
	if do_disable_plugins:
		var cfg = ConfigFile.new()
		cfg.load(PROJECT_FILE)
		for section in [PLUGINS_SECTION, AUTOLOAD_SECTION]:
			if cfg.has_section(section):
				cfg.erase_section(section)
		cfg.save(PROJECT_FILE)

	for dir_name in DirAccess.get_directories_at(Paths.SOLUTIONS_PATH):
		result = build_practice(dir_name)
		if result == ReturnCode.FAIL:
			break
	return result


func build_practice(dir_name: StringName, is_forced := false) -> ReturnCode:
	print_rich("Building [b]%s[/b]..." % dir_name)
	var solution_dir_path := Paths.SOLUTIONS_PATH.path_join(dir_name)
	var solution_file_paths := Utils.fs_find("*", solution_dir_path)

	solution_file_paths.assign(
		solution_file_paths.filter(
			func(x: String) -> bool: return not (
				x.ends_with("/test.gd")
				or x.ends_with("/diff.gd")
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
		var was_copied := false
		if extension == "tscn" and solution_diff != null:
			var solution_scene: Node = load(solution_file_path).instantiate()
			var func_name := solution_file_path.get_file().get_basename()
			if func_name in solution_diff:
				solution_diff.call(func_name, solution_scene)
				var practice_packed_scene := PackedScene.new()
				practice_packed_scene.pack(solution_scene)
				ResourceSaver.save(practice_packed_scene, practice_file_path)
				was_copied = true
				print_rich(LOG_MESSAGE % [solution_file_path, "[color=blue]DIFF[/color]"])
			else:
				print_rich("[color=red]ERROR: Found diff.gd script for %s, and expected a function named %s, but it was not found. Copying the practice scene as-is.[/color]" % [solution_file_path, func_name])

		if not was_copied:
			DirAccess.copy_absolute(solution_file_path, practice_file_path)
			print_rich(LOG_MESSAGE % [practice_file_path, "[color=green]COPY[/color]"])

		if extension in ["gd", "tscn", "tres"]:
			var contents := FileAccess.get_file_as_string(practice_file_path)
			if extension == "gd":
				contents = _process_gd(contents)
			contents = Paths.to_practice(contents)
			FileAccess.open(practice_file_path, FileAccess.WRITE).store_string(contents)
			print_rich(LOG_MESSAGE % [practice_file_path, "[color=yellow]PROCESS[/color]"])
	return ReturnCode.OK


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
