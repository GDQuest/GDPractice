extends Sprite2D

var max_speed := 600.0
var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	# Calculate the input direction using Input.get_axis().
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")) # var direction := Vector2.ZERO

	# Limit the direction vector's length by normalizing the vector.
	# You need to replace "pass" below.
	if direction.length() > 1.0:
		pass
#		direction = direction.normalized()

	# Complete this line to move the ship.
	velocity = max_speed * direction

	position += velocity * delta
	if direction:
		rotation = velocity.angle()
