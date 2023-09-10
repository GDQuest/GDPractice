## This class is used by [b]instructors[/b] to validate practices based on a direct comparisson
## with the solution.
class_name Test extends Node

const Logger := preload("../logger/logger.gd")
const JSPayload := preload("../logger/js_payload.gd")

## Functions that have names beginning with this string will be called in [method run]
## automatically.
const PREFIX := "_test_"
const COMMENT_REGEX := "#.*$"

## Track the call to [method _connect_timed]. If it was used then discard the first
## element fo [member _test_space] in [member run].
var is_timed := false

## Used to store [b]practice[/b] and [b]solution[/b] as well as any needed extra data for
## testing with the framework. It needs to be populated before use.
var _test_space: Array[Dictionary] = []

var _practice_base_path := ""

## Simplified [b]practice[/b] code split line by line as [Array] of [String].
var _practice_code: Array[String] = []

## The [b]practice[/b] scene.
var _practice: Node = null

## The [b]solution[/b] scene.
var _solution: Node = null


## Sets up references to the practice and solution scenes and awaits: [br]
## - [i]virtual[/i] [method _setup_state]: to update the solution state based on the practice
## initial conditions. [br]
## - [i]virtual[/i] [method _setup_populate_test_space]: to acquire state for comparisson between
## practice and solution scenes.
##
## These [code]_setup_*()[/code] methods are helpers for breaking the tasks into smaller chunks.
func setup(practice: Node, solution: Node) -> void:
	_practice = practice
	_solution = solution

	var _practice_script: Script = _practice.get_script()
	_practice_base_path = _practice_script.resource_path.get_base_dir()
	_practice_code = _preprocess_practice_code(_practice_script)

	Logger.add_separator()
	Logger.log("[b]Tests...[/b]")
	await _setup_state()

	var message := "Setting practice <=> solution state"
	JSPayload.new(JSPayload.Type.TEST, JSPayload.Status.DONE, _practice_base_path, message)
	Logger.log("\t%s...[color=green]DONE[/color]" % message)
	await _setup_populate_test_space()
	message = "Populating test space"
	JSPayload.new(JSPayload.Type.TEST, JSPayload.Status.DONE, _practice_base_path, message)
	Logger.log("\t%s...[color=green]DONE[/color]" % message)


## Runs all functions with names that begin with [constant PREFIX].
func run() -> void:
	if is_timed:
		_test_space = _test_space.slice(1)
	for d in get_method_list().filter(func(x: Dictionary) -> bool: return x.name.begins_with(PREFIX)):
		var hint: String = await call(d.name)
		Logger.log("\tTesting %s...%s" % [d.name.trim_prefix(PREFIX).capitalize(), "[color=%s]%s[/color]" % (["green", "PASS"] if hint.is_empty() else ["red", "FAIL"])])
		if not hint.is_empty():
			JSPayload.new(
				JSPayload.Type.TEST,
				JSPayload.Status.PASS if hint.is_empty() else JSPayload.Status.FAIL,
				_practice_base_path,
				hint,
			)
			Logger.log("\t\t%s" % hint)


## Assign here the [b]practice[/b] state to the [b]solution[/b] state so they both start with the
## same initial conditions.
func _setup_state() -> void:
	pass


## Acquire both [b]practice[/b] and [b]solution[/b] state data for test validation.
func _setup_populate_test_space() -> void:
	pass


## Connects [param callback] to [param sig] signal for the given amount of [param time] by waiting
## for [signal SceneTreeTimer.timeout] and disconnecting at the end.
func _connect_timed(time: float, sig: Signal, callback: Callable) -> void:
	sig.connect(callback)
	await get_tree().create_timer(time).timeout
	sig.disconnect(callback)
	is_timed = true


## Returns [code]true[/code] if a line in the input [code]code[/code] matches one of the
## [param target_lines]. Uses [method String.match] to match lines, so you can use
## [code]?[/code] and [code]*[/code] in [param target_lines].
func _is_code_line_match(target_lines: Array) -> bool:
	for line in _practice_code:
		for match_pattern in target_lines:
			if line.match(match_pattern):
				return true
	return false


## Retruns [code]true[/code] if the [param fail_predicate] [Callable] is [code]true[/code] for all
## pairs of consecutive items in [member _test_space]. Otherwise it returns [code]false[/code]. [br]
## [br]
## Parameters: [br]
## - [param fail_predicate] is a [Callable] that expects a pair of parameters fed from
## [member _test_space].
func _is_sliding_window_pass(fail_predicate: Callable) -> bool:
	var result := true
	var x: Dictionary = _test_space[0]
	for y in _test_space.slice(1):
		if fail_predicate.call(x, y):
			result = false
			break
		x = y
	return result


## Set [param property_path] to [param value] for both [member _practice] and [member _solution].
## If [param property_path] base name (index [code]0[/code] of the [NodePath]) isn't found in
## [member _practice] or [member _solution] push an error to the debugger that it failed to set
## the [param value].[br]
## [br]
## Say for example we have a scene with a [TextEdit] node referenced by the [code]text_edit[/code]
## variable in code. Then we can call this function to set a property on [code]text_edit[/code]
## for both [b]practice[/b] and [b]solution[/b] scenes like this:
##
## [codeblock]
## var input := "world"
## _set_all("text_edit:text", input)
## [/codeblock]
##
## Known issues or limitations:[br]
## - If [param property_path] referes to a non-existing deep-nested property, the function
## does nothing and reports no errors.
func _set_all(property_path: NodePath, value: Variant) -> void:
	if property_path.is_empty():
		push_error("Can't set empty property path with value %s." % value)
		return

	for node in [_practice, _solution]:
		var property_name := property_path.get_name(0)
		if not property_name in node:
			push_error("Error setting property '%s.%s' with value '%s'. Property not found." % [node, property_name, value])
		node.set_indexed(property_path, value)


## Calls [param method] with [param arg_array] using [method Object.callv] on both
## [member _practice] and [member _solution]. Returns the result of the [param method] calls
## as a [Dictionary] with keys [code]practice[/code]
## and [code]solution[/code].
func _call_all(method: String, arg_array: Array = []) -> Dictionary:
	return {
		practice = _practice.callv(method, arg_array),
		solution = _solution.callv(method, arg_array)
	}


## Helper to simplify the [b]practice[/b] script code. It returns the simplified code split
## line by line as [Array] of [String].
static func _preprocess_practice_code(practice_script: Script) -> Array[String]:
	var result: Array[String] = []
	var comment_suffix := RegEx.new()
	comment_suffix.compile(COMMENT_REGEX)
	for line in practice_script.source_code.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if not (line.is_empty() or line.begins_with("#")):
			result.push_back(comment_suffix.sub(line, ""))
	return result
