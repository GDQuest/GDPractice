class_name Test extends Node

const PREFIX := "test_"
const COMMENT_REGEX := "#.*$"

var _test_space: Array[Dictionary] = []
var _practice_code: Array[String] = []
var _practice: Node = null
var _solution: Node = null


func setup(practice: Node, solution: Node) -> void:
	_practice = practice
	_solution = solution
	_practice_code = _preprocess_practice_code(_practice.get_script())

	Logger.add_separator()
	Logger.log("[b]Tests...[/b]")
	await setup_state()
	Logger.log("\tSetting practice <=> solution state...[color=green]DONE[/color]")
	await setup_populate()
	Logger.log("\tPopulating test space...[color=green]DONE[/color]")


func setup_state() -> void:
	pass


func setup_populate() -> void:
	pass


func run() -> void:
	_test_space = _test_space.slice(1)
	for d in get_method_list().filter(func(x: Dictionary) -> bool: return x.name.begins_with(PREFIX)):
		var has_passed: bool = await call(d.name)
		Logger.log("\tTesting %s...%s" % [
			d.name.trim_prefix(PREFIX).capitalize(),
			"[color=%s]%s[/color]" % (["green", "PASS"] if has_passed else ["red", "FAIL"])
		])


# Returns true if a line in the input `code` matches one of the `target_lines`.
# Uses String.match to match lines, so you can use ? and * in `target_lines`.
func _matches_code_line(target_lines: Array) -> bool:
	for line in _practice_code:
		for match_pattern in target_lines:
			if line.match(match_pattern):
				return true
	return false


func _connect_for(sig: Signal, callback: Callable, time: float) -> void:
	sig.connect(callback)
	await get_tree().create_timer(time).timeout
	sig.disconnect(callback)


func _test_sliding_window(fail_predicate: Callable) -> bool:
	var result := true
	var x: Dictionary = _test_space[0]
	for y in _test_space.slice(1):
		if fail_predicate.call(x, y):
			result = false
			break
		x = y
	return result


static func _preprocess_practice_code(practice_script: Script) -> Array[String]:
	var result: Array[String] = []
	var comment_suffix := RegEx.new()
	comment_suffix.compile(COMMENT_REGEX)
	for line in practice_script.source_code.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if not (line.is_empty() or line.begins_with("#")):
			result.push_back(comment_suffix.sub(line, ""))
	return result
