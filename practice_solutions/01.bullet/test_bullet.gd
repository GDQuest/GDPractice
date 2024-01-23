extends Node

# Look at each bullet's velocity. The angle of the bullet should be like velocity.angle
const Bullet := preload("bullet.gd")

# TODO: gather bullet nodes from scene.
# TODO: check that bullets are spawned/array isn't empty
var bullets: Array[Bullet] = []



func test_bullet_position_is_affected():
	for bullet in bullets:
		# TODO: check that bullets move over time
		pass
	return true


func test_bullet_rotation_is_affected():
	for bullet in bullets:
		if not is_equal_approx(bullet.rotation, bullet.velocity.angle()):
			return tr("Bullets don't seem to be rotated according to the velocity vector's angle. Did you call velocity.angle() to get the velocity vector's angle? And did you assign it to the bullet's rotation?")
	return true
