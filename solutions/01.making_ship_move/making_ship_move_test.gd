extends Test

const ERR := 1e-3

var test_space: Array[Dictionary] = []


func setup(practice: Node, solution: Node) -> void:
	super(practice, solution)
	solution.velocity = practice.velocity

	await get_tree().create_timer(1.0).timeout
	get_tree().physics_frame.connect(populate_test_space)
	await get_tree().create_timer(1.0).timeout
	get_tree().physics_frame.disconnect(populate_test_space)


func populate_test_space() -> void:
	test_space.append({
		practice_position = practice.position,
		solution_position = solution.position,
		delta = get_physics_process_delta_time(),
	})


func test_velocity_is_not_zero() -> bool:
	return not practice.velocity.is_zero_approx()


func test_position_changes_every_frame() -> bool:
	var result := true
	var x: Dictionary = test_space[0]
	for y in test_space.slice(1):
		if x.practice_position.is_equal_approx(y.practice_position):
			result = false
			break
		x = y
	return result


func test_movement_takes_delta_into_account() -> bool:
	var result := true
	var delta := get_physics_process_delta_time()
	var deltas: Array[float] = []
	var x: Dictionary = test_space[0]
	for y in test_space.slice(1):
		if not abs(y.practice_position.distance_to(x.practice_position) / practice.velocity.length() - delta) < ERR:
			result = false
			break
		x = y
	return result


func test_position_matches_solution() -> bool:
	return test_space.all(func(x: Dictionary) -> bool: return x.practice_position == x.solution_position)
