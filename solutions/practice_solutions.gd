# TODO: take what's needed
const ROOT_PATH := "res://"
const USER_PATH := "user://"
const SOLUTION_PATH := "res://addons/PracticeTester/solutions/"
const DENTS := {"<": -1, ">": 1}
const PROJECT_SETTINGS := {
	"instructor_mode": {"value": true, "name": "practice_tester/instructor/is_instructor_mode", "type": TYPE_BOOL}
}


static func build(is_user_mode := true, path := SOLUTION_PATH, force := false) -> void:
	var regex_line := RegEx.new()
	var regex_shift := RegEx.new()
	regex_line.compile("^(\\h*)(.*)#\\h*(.*)$")
	regex_shift.compile("^([<>]+)\\h*(.*)")

	var prefix_path := USER_PATH if is_user_mode else ROOT_PATH
	var file := File.new()
	var dir := Directory.new()
	var err := dir.open(prefix_path)
	if err != OK:
		print("ERR: Can't open ", prefix_path, " (", err, ")")

	for solution_path in find_solution_paths("*", path):
		var starting_path: String = solution_path.replace(SOLUTION_PATH, prefix_path)
		var extension: String = solution_path.get_extension()
		dir.make_dir_recursive(starting_path.get_base_dir())
		if force or not file.file_exists(starting_path) or file.file_exists(starting_path) and file.get_modified_time(starting_path) < file.get_modified_time(solution_path):
			if not extension in ["gd", "tscn"]:
				dir.copy(solution_path, starting_path)
			elif extension != "import":
				file.open(solution_path, File.READ)
				var contents := file.get_as_text()
				file.close()

				if starting_path.get_extension() == "gd":
					contents = _process_gd(contents, regex_line, regex_shift)
				elif starting_path.get_extension() == "tscn":
					contents = contents.replace(SOLUTION_PATH, prefix_path)

				file.open(starting_path, File.WRITE)
				file.store_string(contents)
				file.close()


static func _process_gd(solution: String, regex_line: RegEx, regex_shift: RegEx) -> String:
	var partial_result := []
	for line in solution.split("\n"):
		var processed := _process_line(line, regex_line, regex_shift)
		if processed.do_skip:
			continue
		partial_result.push_back(processed.line)
	return "\n".join(partial_result).strip_edges() + "\n"


static func _process_line(line: String, regex_line: RegEx, regex_shift: RegEx) -> Dictionary:
	var result := {line = line, do_skip = false}
	var regex_line_match := regex_line.search(line)
	if regex_line_match != null and not regex_line_match.strings[2].empty():
		result.line = _process_tabs(regex_line_match.strings[1], regex_line_match.strings[3].strip_edges(), regex_shift)
		result.do_skip = not line.strip_edges().empty() and result.line.strip_edges().empty()
	return result


static func _process_tabs(prefix: String, line: String, regex_shift: RegEx) -> String:
	var tabs := prefix.count("\t")
	var regex_shift_match := regex_shift.search(line)
	if regex_shift_match != null:
		for shift in regex_shift_match.strings[1]:
			tabs += DENTS[shift]
		line = regex_shift_match.strings[2]
	return "\t".repeat(tabs) + line


static func find_solution_paths(pattern: String = "*", path: String = SOLUTION_PATH) -> Array:
	var result := []
	var dir := Directory.new()

	if dir.open(path) != OK:
		printerr("ERROR: could not open [%s]" % [path])
		return result

	if dir.list_dir_begin(true, true) != OK:
		printerr("ERROR: could not list contents of [%s]" % [path])
		return result

	path = dir.get_next()
	while path != "":
		path = dir.get_current_dir().plus_file(path)
		if dir.current_is_dir():
			result += find_solution_paths(pattern, path)
		elif path.match(pattern):
			result.push_back(path)
		path = dir.get_next()

	return result
