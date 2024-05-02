extends "res://addons/gdpractice/tester/test.gd"


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


func _build() -> void:
	var c1 := Check.new()
	c1.description = "Direction uses [b]get_axis()[/b] function"
	c1.hint = "Can't find [b]Input.get_axis()[/b] calls"
	c1.check = _test_direction_uses_get_axis_function

	var c2 := Check.new()
	c2.description = "[b]get_axis()[/b] calls use correct move actions"
	c2.hint = "[b]Input.get_axis()[/b] calls seem to use incorrect actions"
	c2.check = _test_get_axis_calls_use_correct_move_actions

	var c3 := Check.new()
	c3.description = "Direction is normalized"
	c3.hint = "Check if [b]direction[/b] is properly normalized"
	c3.check = _test_direction_is_normalized

	var c4 := Check.new()
	c4.description = "Movement uses [b]direction[/b] and [b]max_speed[/b]"
	c4.hint = "Velocity doesn't seem to use [b]direction[/b] and/or [b]max_speed[/b]"
	c4.check = _test_movement_uses_direction_and_max_speed

	var c5 := Check.new()
	c5.description = "[b]velocity[/b] is computed correctly"
	c5.hint = "Practice [b]velocity[/b] doesn't match solution [b]velocity[/b]"
	c5.check = _test_velocity_is_computed_correctly

	var c6 := Check.new()
	c6.description = "[b]position[/b] is computed correctly"
	c6.hint = "Practice [b]position[/b] doesn't match solution [b]position[/b]"
	c6.check = _test_position_is_computed_correctly
	checks.append_array([c1, c2, c3, c4, c5, c6])


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


func _test_direction_uses_get_axis_function() -> bool:
	return _is_code_line_match(['direction=Vector2(Input.get_axis(*),Input.get_axis(*))'])


func _test_get_axis_calls_use_correct_move_actions() -> bool:
	var fail_predicate := func(x: Dictionary, y: Dictionary) -> bool:
		return (
			sign(x.direction.x) != sign(y.practice.velocity.x)
			or sign(x.direction.y) != sign(y.practice.velocity.y)
		)
	return _is_sliding_window_pass(fail_predicate)


func _test_direction_is_normalized() -> bool:
	var predicate := func(x: Dictionary) -> bool:
		return (
			not x.practice.direction.is_zero_approx()
			and x.practice.direction.is_equal_approx(x.practice.direction.normalized())
		)
	return _test_space.all(predicate)


func _test_movement_uses_direction_and_max_speed() -> bool:
	var predicate := func(x: Dictionary) -> bool:
		return (
			is_equal_approx(x.practice.velocity.length(), _practice.max_speed)
			and x.practice.velocity.is_equal_approx(_practice.max_speed * x.practice.direction)
		)
	return _test_space.all(predicate)


func _test_velocity_is_computed_correctly() -> bool:
	var predicate := func(x: Dictionary) -> bool: return x.practice.velocity == x.solution.velocity
	return _test_space.all(predicate)


func _test_position_is_computed_correctly() -> bool:
	var predicate := func(x: Dictionary) -> bool: return x.practice.position == x.solution.position
	return _test_space.all(predicate)
