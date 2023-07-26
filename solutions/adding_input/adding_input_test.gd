extends Test


func _setup_state() -> void:
	_solution.max_speed = _practice.max_speed
	_solution.velocity = _practice.velocity
	_solution.direction = _practice.direction


func _setup_populate_test_space() -> void:
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
		await _connect_timed(0.3, get_tree().process_frame, _populate_test_space)
		for action in actions:
			Input.action_release(action)


func _populate_test_space() -> void:
	_test_space.append({
		practice = {
			direction = _practice.direction,
			position = _practice.position,
			velocity = _practice.velocity,
		},
		solution = {
			direction = _solution.direction,
			position = _solution.position,
			velocity = _solution.velocity,
		},
		direction = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		),
	})


func _test_direction_uses_get_axis_function() -> String:
	if not _is_code_line_match(['direction=Vector2(Input.get_axis(*),Input.get_axis(*))']):
		return "can't find [code]Input.get_axis()[/code] calls"
	return ""


func _test_get_axis_calls_use_correct_move_actions() -> String:
	var fail_predicate := func(x: Dictionary, y: Dictionary) -> bool:
		return (
			sign(x.direction.x) != sign(y.practice.velocity.x)
			or sign(x.direction.y) != sign(y.practice.velocity.y)
		)
	if not _is_sliding_window_pass(fail_predicate):
		return "[code]Input.get_axis()[/code] calls seem to use incorrect actions"
	return ""


func _test_direction_is_normalized() -> String:
	var predicate := func(x: Dictionary) -> bool:
		return (
			not x.practice.direction.is_zero_approx()
			and x.practice.direction.is_equal_approx(x.practice.direction.normalized())
		)
	if not _test_space.all(predicate):
		return "direction isn't normalized"
	return ""


func _test_movement_uses_direction_and_max_speed() -> String:
	var predicate := func(x: Dictionary) -> bool:
		return (
			is_equal_approx(x.practice.velocity.length(), _practice.max_speed)
			and x.practice.velocity.is_equal_approx(_practice.max_speed * x.practice.direction)
		)
	if not _test_space.all(predicate):
		return "velocity doesn't seem to use [code]direction[/code] and/or [code]max_speed[/code]"
	return ""


func _test_velocity_is_computed_correctly() -> String:
	var predicate := func(x: Dictionary) -> bool: return x.practice.velocity == x.solution.velocity
	if not _test_space.all(predicate):
		return "practice velocity doesn't match solution velocity"
	return ""


func _test_position_is_computed_correctly() -> String:
	var predicate := func(x: Dictionary) -> bool: return x.practice.position == x.solution.position
	if not _test_space.all(predicate):
		return "practice position doesn't match solution position"
	return ""
