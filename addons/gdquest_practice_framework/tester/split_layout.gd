extends "layout.gd"

@onready var practice_sub_viewport: SubViewport = %PracticeSubViewport
@onready var solution_sub_viewport: SubViewport = %SolutionSubViewport


func set_practice(value: Node) -> void:
	super(value)
	var practice_parent := practice.get_parent()
	if practice_parent:
		practice_parent.remove_child.call_deferred(practice)
	practice_sub_viewport.add_child.call_deferred(practice)


func set_solution(value: Node) -> void:
	super(value)
	var solution_parent := solution.get_parent()
	if solution_parent:
		solution_parent.remove_child.call_deferred(solution)
	solution_sub_viewport.add_child.call_deferred(solution)
	if solution is CanvasItem:
		solution.modulate.a = 1.0
