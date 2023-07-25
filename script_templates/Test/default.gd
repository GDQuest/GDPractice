extends Test


func setup_state() -> void:
	# Make sure to check corner cases like `_practice.velocity = Vector2.ZERO`
	if not _practice.velocity.is_zero_approx():
		_solution.velocity = _practice.velocity


func setup_populate_test_space() -> void:
	await _connect_timed(1.0, get_tree().process_frame, populate_test_space)


func populate_test_space() -> void:
	_test_space.append({
		practice_position = _practice.position,
		solution_position = _solution.position,
		delta = get_process_delta_time(),
	})


func test_velocity_is_not_zero() -> bool:
	return not _practice.velocity.is_zero_approx()
