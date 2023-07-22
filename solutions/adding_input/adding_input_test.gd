extends Test


func setup(practice: Node, solution: Node) -> void:
	super(practice, solution)
	_solution.max_speed = _practice.max_speed
	_solution.velocity = _practice.velocity
	_solution.direction = _practice.direction

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


func test_direction_uses_get_axis_function() -> bool:
	return matches_code_line(['direction=Vector2(Input.get_axis(*),Input.get_axis(*))'])


func test_get_axis_calls_use_correct_move_actions() -> bool:
	var fail_predicate := func(x: Dictionary, y: Dictionary) -> bool:
		return (
			sign(x.direction.x) != sign(y.practice.velocity.x)
			or sign(x.direction.y) != sign(y.practice.velocity.y)
		)
	return _test_sliding_window(fail_predicate)


func test_direction_is_normalized() -> bool:
	return _test_space.all(
		func(x: Dictionary) -> bool:
			return (
				not x.practice.direction.is_zero_approx()
				and x.practice.direction.is_equal_approx(x.practice.direction.normalized())
			)
	)


func test_movement_uses_direction_and_max_speed() -> bool:
	return _test_space.all(
		func(x: Dictionary) -> bool:
			return (
				is_equal_approx(x.practice.velocity.length(), _practice.max_speed)
				and x.practice.velocity.is_equal_approx(_practice.max_speed * x.practice.direction)
			)
	)


func test_velocity_is_computed_correctly() -> bool:
	return _test_space.all(
		func(x: Dictionary) -> bool:
			return x.practice.velocity == x.solution.velocity
	)


func test_position_is_computed_correctly() -> bool:
	return _test_space.all(
		func(x: Dictionary) -> bool:
			return x.practice.position == x.solution.position
	)
