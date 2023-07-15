class_name Test extends Node

const PREFIX := "test_"
const MAP := {
	true: "PASS",
	false: "FAIL",
}
const COLOR := {
	true: "green",
	false: "red",
}

var practice: Node = null
var solution: Node = null


func setup(practice: Node, solution: Node) -> void:
	self.practice = practice
	self.solution = solution


func run() -> void:
	for d in get_method_list().filter(func(x: Dictionary) -> bool: return x.name.begins_with(PREFIX)):
		print("Testing: %s..." % d.name.trim_prefix(PREFIX).capitalize())
		var has_passed: bool = await Callable(self, d.name).call()
		print_rich("[color=%s]%s[/color]\n" % [COLOR[has_passed], MAP[has_passed]])
