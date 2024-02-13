extends "res://addons/gdquest_practice_framework/tester/test.gd"

# Look at each bullet's velocity. The angle of the bullet should be like velocity.angle
const Bullet := preload("bullet.gd")

# TODO: gather bullet nodes from scene.
# TODO: check that bullets are spawned/array isn't empty
var bullets: Array[Bullet] = []


func _build() -> void:
	var c1 := Check.new()
	c1.description = "Check 1"

	var c1_1 := Check.new()
	c1_1.description = "Check 1.1 Sub"
	c1_1.hint = "Check 1.1 Hint"
	c1_1.check = func() -> bool: return false
	c1.subchecks.push_back(c1_1)

	var c1_2 := Check.new()
	c1_2.description = "Check 1.2 Sub"
	c1_2.hint = "Check 1.2 Hint"
	c1_2.check = func() -> bool: return true
	c1.subchecks.push_back(c1_2)

	var c2 := Check.new()
	c2.description = "Check 2 (Depends)"
	c2.hint = "Check 2 Hint"
	c2.check = func() -> bool: return true
	c2.dependencies.push_back(c1)
	checks.append_array([c1, c2])


func test_bullet_position_is_affected():
	for bullet in bullets:
		# TODO: check that bullets move over time
		pass
	return true


func test_bullet_rotation_is_affected():
	for bullet in bullets:
		if not is_equal_approx(bullet.rotation, bullet.velocity.angle()):
			return tr(
				"Bullets don't seem to be rotated according to the velocity vector's angle. Did you call velocity.angle() to get the velocity vector's angle? And did you assign it to the bullet's rotation?"
			)
	return true
