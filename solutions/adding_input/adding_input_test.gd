# TODO: convert all tests
extends Test


func setup(practice: Node, solution: Node) -> void:
	super(practice, solution)
	solution.max_speed = practice.max_speed
	solution.velocity = practice.velocity

	var actionss := [
		["move_left"],
		["move_right"],
		["move_up"],
		["move_down"],
		["move_left", "move_up"],
		["move_right", "move_down"],
		["move_right", "move_up"],
		["move_left", "move_down"],
	]
	for actions in actionss:
		for action in actions:
			Input.action_press(action)
		await _connect_for(get_tree().process_frame, populate_test_space, 0.3)
		for action in actions:
			Input.action_release(action)


func populate_test_space() -> void:
	_test_space.append({
		practice_position = _practice.position,
		solution_position = _solution.position,
	})


func test_direction_uses_get_axis_function() -> bool:
	return matches_code_line(['var*=Vector2(Input.get_axis(*),Input.get_axis(*))'])


func test_get_axis_calls_use_correct_move_actions() -> bool:
	return _test_space.all(func(x: Dictionary) -> bool: return x.practice_position == x.solution_position)
