class_name Test extends Node

const PREFIX := "test_"
const COMMENT_REGEX := "#.*$"
const MAP := {
	true: "PASS",
	false: "FAIL",
}
const COLOR := {
	true: "green",
	false: "red",
}

var _test_space: Array[Dictionary] = []

var _practice: Node = null
var _practice_code: Array[String] = []

var _solution: Node = null


func setup(practice: Node, solution: Node) -> void:
	_practice = practice
	_solution = solution
	_preprocess_practice_code(_practice.get_script())


func run() -> void:
	for d in get_method_list().filter(func(x: Dictionary) -> bool: return x.name.begins_with(PREFIX)):
		print("\tTesting: %s..." % d.name.trim_prefix(PREFIX).capitalize())
		var has_passed: bool = await Callable(self, d.name).call()
		print_rich("\t[color=%s]%s[/color]\n" % [COLOR[has_passed], MAP[has_passed]])


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

# Returns true if a line in the input `code` matches one of the `target_lines`.
# Uses String.match to match lines, so you can use ? and * in `target_lines`.
func matches_code_line(target_lines: Array) -> bool:
	for line in _practice_code:
		for match_pattern in target_lines:
			if line.match(match_pattern):
				return true
	return false


func _preprocess_practice_code(practice_script: Script) -> void:
	var comment_suffix := RegEx.new()
	comment_suffix.compile(COMMENT_REGEX)
	for line in practice_script.source_code.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if not (line.is_empty() or line.begins_with("#")):
			_practice_code.append(comment_suffix.sub(line, ""))
