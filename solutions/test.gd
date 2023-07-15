class_name Test extends Node

var practice: Node = null
var solution: Node = null


func setup(practice: Node, solution: Node) -> void:
	self.practice = practice
	self.solution = solution


func run() -> void:
	for d in get_script().get_script_method_list().filter(func(x: Dictionary) -> bool: return x.name.begins_with("test_")):
		Callable(self, d.name).call()
