class_name Layout extends Control

var practice: Node = null: set = set_practice
var solution: Node = null: set = set_solution

var scenes: Array[Node]:
	get:
		return [practice, solution]


func refresh(scenes: Array) -> void:
	if scenes.size() != 2:
		return
	practice = scenes[0]
	solution = scenes[1]


func set_practice(value: Node) -> void:
	practice = value


func set_solution(value: Node) -> void:
	solution = value
