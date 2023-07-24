extends Sprite2D

var boost_speed := 1500.0
var normal_speed := 600.0

var max_speed := normal_speed

var direction := Vector2.ZERO
var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = max_speed * direction

	if Input.is_action_just_pressed("boost"):
		pass

	position += velocity * delta
	if direction:
		rotation = velocity.angle()
