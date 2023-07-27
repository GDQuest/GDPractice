extends Control

var practice: Node = null:
	set(value):
		practice = value
		var practice_parent := practice.get_parent()
		if practice_parent:
			practice_parent.remove_child.call_deferred(practice)
		practice_sub_viewport.add_child.call_deferred(practice)

var solution: Node = null:
	set(value):
		solution = value
		var solution_parent := solution.get_parent()
		if solution_parent:
			solution_parent.remove_child.call_deferred(solution)
		solution_sub_viewport.add_child.call_deferred(solution)

@onready var practice_sub_viewport: SubViewport = %PracticeSubViewport
@onready var solution_sub_viewport: SubViewport = %SolutionSubViewport


func add_scenes(scenes: Array) -> void:
	if scenes.size() != 2:
		return
	practice = scenes[0]
	solution = scenes[1]
