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

var test_space: Array[Dictionary] = []

var practice: Node = null
var solution: Node = null


func setup(practice: Node, solution: Node) -> void:
	self.practice = practice
	self.solution = solution

	if self.has_method("populate_test_space"):
		var populate_test_space := Callable(self, "populate_test_space")
		await get_tree().create_timer(1.0).timeout
		get_tree().physics_frame.connect(populate_test_space)
		await get_tree().create_timer(1.0).timeout
		get_tree().physics_frame.disconnect(populate_test_space)


func run() -> void:
	for d in get_method_list().filter(func(x: Dictionary) -> bool: return x.name.begins_with(PREFIX)):
		print("Testing: %s..." % d.name.trim_prefix(PREFIX).capitalize())
		var has_passed: bool = await Callable(self, d.name).call()
		print_rich("[color=%s]%s[/color]\n" % [COLOR[has_passed], MAP[has_passed]])
