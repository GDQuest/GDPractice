extends "layout.gd"

@onready var sub_viewport: SubViewport = %SubViewport


func set_practice(value: Node) -> void:
	super(value)
	var practice_parent := practice.get_parent()
	if practice_parent:
		practice_parent.remove_child.call_deferred(practice)
	sub_viewport.add_child.call_deferred(practice)


func set_solution(value: Node) -> void:
	super(value)
	var solution_parent := solution.get_parent()
	if solution_parent:
		solution_parent.remove_child.call_deferred(solution)
	sub_viewport.add_child.call_deferred(solution)
	sub_viewport.move_child.call_deferred(solution, 0)
	if solution is CanvasItem:
		solution.modulate.a = 0.5
