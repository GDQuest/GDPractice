extends Control

## Add solution nodes to this group to hide them when testing in the Ghost layout.
const VISIBILITY_GROUP := &"GDFExcludeVisibility"

var practice: Node = null:
	set = set_practice
var solution: Node = null:
	set = set_solution

var scenes: Array[Node]:
	get:
		return [practice, solution]

@onready var practice_sub_viewport: SubViewport = %PracticeSubViewport
@onready var solution_sub_viewport: SubViewport = %SolutionSubViewport


func refresh(scenes: Array) -> void:
	if scenes.size() != 2:
		return
	practice = scenes[0]
	solution = scenes[1]


func set_practice(value: Node) -> void:
	if value == null:
		return
	practice = value
	var practice_parent := practice.get_parent()
	if practice_parent:
		practice_parent.remove_child.call_deferred(practice)
	practice_sub_viewport.add_child.call_deferred(practice)


func set_solution(value: Node) -> void:
	if value == null:
		return
	solution = value
	var solution_parent := solution.get_parent()
	if solution_parent:
		solution_parent.remove_child.call_deferred(solution)
	solution_sub_viewport.add_child.call_deferred(solution)


func fix_tile_map_transparencty() -> void:
	var tile_maps := get_tree().get_nodes_in_group(VISIBILITY_GROUP).filter(
		func(n: Node) -> bool: return n is TileMap
	)
	for tile_map: TileMap in tile_maps:
		tile_map.visible = !tile_map.visible
		tile_map.set_visible.call_deferred(!tile_map.visible)
