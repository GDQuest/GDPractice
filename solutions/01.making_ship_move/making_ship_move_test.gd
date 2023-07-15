extends Test


func test_velocity_should_be_100_right() -> void:
	prints(practice.velocity, practice.velocity == solution.velocity)


func test_position_update_with_velocity() -> void:
	var test_space := []
	var populate_test_space := func() -> void: test_space.append(practice.position == solution.position)
	get_tree().physics_frame.connect(populate_test_space)
	await get_tree().create_timer(1.0).timeout
	get_tree().physics_frame.disconnect(populate_test_space)
	print(test_space.all(func(x: bool) -> bool: return x))
