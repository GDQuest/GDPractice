extends Test


func setup(practice: Node, solution: Node) -> void:
	super(practice, solution)
	if not _are_requirements_valid:
		get_tree().quit()
		return

	if not practice.velocity.is_zero_approx():
		solution.velocity = practice.velocity
	await _connect_for(get_tree().process_frame, populate_test_space, 1.0)


func populate_test_space() -> void:
	_test_space.append({
		practice_position = _practice.position,
		solution_position = _solution.position,
		delta = get_process_delta_time(),
	})


func test_velocity_is_not_zero() -> bool:
	return not _practice.velocity.is_zero_approx()


func test_position_changes_every_frame() -> bool:
	var fail_predicate := func(x: Dictionary, y: Dictionary) -> bool:
		return x.practice_position.is_equal_approx(y.practice_position)
	return _test_sliding_window(fail_predicate)


func test_movement_takes_delta_into_account() -> bool:
	var fail_predicate := func(x: Dictionary, y: Dictionary) -> bool:
		return not is_zero_approx(y.practice_position.distance_to(x.practice_position) / _practice.velocity.length() - x.delta)
	return _test_sliding_window(fail_predicate)


func test_position_is_computed_correctly() -> bool:
	return _test_space.all(func(x: Dictionary) -> bool: return x.practice_position == x.solution_position)