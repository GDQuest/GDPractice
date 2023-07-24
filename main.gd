extends Control

const DENTS := {"<": -1, ">": 1}
const PRACTICES_PATH := "res://practices"
const SOLUTIONS_PATH := "res://solutions"

const Test := preload("%s/test.gd" % SOLUTIONS_PATH)

var practices := {
	"to space and beyond": [
		"making_ship_move",
		"adding_input",
#		"adding_timer",
	],
}

@onready var sub_viewport: SubViewport = %SubViewport
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer
@onready var next_button: Button = %NextButton


func _ready() -> void:
	build()
#	check()


func check() -> void:
	var practice_count := practices.size()
	for project_name in practices:
		for practice_name in practices[project_name]:
			await check_practice(practice_name, project_name)
			await next_button.pressed
			for node in checks_v_box_container.get_children():
				node.queue_free()


func check_practice(dir_name: StringName, project_name: String) -> void:
	for node in sub_viewport.get_children():
		node.queue_free()

	var scene_name := "".join([dir_name, ".tscn"])
	var solution_scene := load(SOLUTIONS_PATH.path_join(dir_name).path_join(scene_name))
	var solution: Node = solution_scene.instantiate()
	sub_viewport.add_child(solution)
	if solution is Node2D:
		solution.modulate.a = 0.5

	var practice_scene := load(PRACTICES_PATH.path_join(dir_name).path_join(scene_name))
	var practice: Node = practice_scene.instantiate()
	sub_viewport.add_child(practice)

	scene_name = "".join([dir_name, "_test.gd"])
	var test_script := load(SOLUTIONS_PATH.path_join(dir_name).path_join(scene_name))
	var test: Test = test_script.new()
	sub_viewport.add_child(test)
#
	title_rich_text_label.text = "Checking...\n[b]%s:%s[/b]" % [
		project_name,
		dir_name,
	].map(func(x: String) -> String: return x.capitalize())
	print_rich("\n%s" % title_rich_text_label.text)
	await test.setup(practice, solution)
	await test.run(checks_v_box_container)


func build() -> void:
	var regex_line := RegEx.new()
	var regex_shift := RegEx.new()
	regex_line.compile("^(\\h*)(.*)#\\h*(.*)$")
	regex_shift.compile("^([<>]+)\\h*(.*)")
	for dir_name in DirAccess.get_directories_at(SOLUTIONS_PATH):
		print_rich("Building [b]%s[/b]..." % dir_name)
		build_solution(dir_name, regex_line, regex_shift)


func build_solution(dir_name: StringName, regex_line: RegEx, regex_shift: RegEx) -> void:
	var solution_dir_path := SOLUTIONS_PATH.path_join(dir_name)
	var solution_file_paths := Utils.fs_find("*", solution_dir_path)
	solution_file_paths.assign(solution_file_paths.filter(func(x: String) -> bool: return not (x.ends_with("_test.gd") or x.ends_with("_diff.gd") or x.get_extension() == "import")))

	var solution_diff_path := solution_dir_path.path_join("%s_diff.gd" % dir_name)
	var solution_diff: GDScript = null
	if FileAccess.file_exists(solution_diff_path):
		solution_diff = load(solution_diff_path)

	var log_message := "\t%s...%s"
	for solution_file_path in solution_file_paths:
		var extension := solution_file_path.get_extension()
		var practice_file_path: String = solution_file_path.replace(SOLUTIONS_PATH, PRACTICES_PATH)
		var practice_file_modified_time := FileAccess.get_modified_time(practice_file_path)
		if (
			FileAccess.file_exists(practice_file_path)
			and practice_file_modified_time > FileAccess.get_modified_time(solution_file_path)
			and practice_file_modified_time > FileAccess.get_modified_time(solution_diff_path)
		):
			print_rich(log_message % [practice_file_path, "[color=orange]SKIP[/color]"])
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
				print_rich(log_message % [solution_file_path, "[color=blue]DIFF[/color]"])

		else:
			DirAccess.copy_absolute(solution_file_path, practice_file_path)
			print_rich(log_message % [practice_file_path, "[color=green]COPY[/color]"])

		if extension in ["gd", "tscn"]:
			var contents := FileAccess.get_file_as_string(practice_file_path)
			if extension == "gd":
				contents = _process_gd(contents, regex_line, regex_shift)
			contents = contents.replace(SOLUTIONS_PATH, PRACTICES_PATH)
			FileAccess.open(practice_file_path, FileAccess.WRITE).store_string(contents)
			print_rich(log_message % [practice_file_path, "[color=yellow]PROCESS[/color]"])


static func _process_gd(contents: String, regex_line: RegEx, regex_shift: RegEx) -> String:
	var partial_result := []
	for line in contents.split("\n"):
		var processed := _process_line(line, regex_line, regex_shift)
		if processed.do_skip:
			continue
		partial_result.push_back(processed.line)
	return "\n".join(partial_result).strip_edges() + "\n"


static func _process_line(line: String, regex_line: RegEx, regex_shift: RegEx) -> Dictionary:
	var result := {line = line, do_skip = false}
	var regex_line_match := regex_line.search(line)
	if regex_line_match != null and not regex_line_match.strings[2].is_empty():
		result.line = _process_tabs(regex_line_match.strings[1], regex_line_match.strings[3].strip_edges(), regex_shift)
		result.do_skip = not line.strip_edges().is_empty() and result.line.strip_edges().is_empty()
	return result


static func _process_tabs(prefix: String, line: String, regex_shift: RegEx) -> String:
	var tabs := prefix.count("\t")
	var regex_shift_match := regex_shift.search(line)
	if regex_shift_match != null:
		for shift in regex_shift_match.strings[1]:
			tabs += DENTS[shift]
		line = regex_shift_match.strings[2]
	return "\t".repeat(tabs) + line
