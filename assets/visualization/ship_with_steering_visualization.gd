extends Sprite2D

var boost_speed := 1500.0
var normal_speed := 600.0

var max_speed := normal_speed
var velocity := Vector2(0, 0)
var steering_factor := 10.0

var desired_velocity := Vector2(0, 0)
var steering := Vector2(0, 0)


func _ready() -> void:
	Engine.time_scale = 0.1


func _process(delta: float) -> void:
	var direction := Vector2(0, 0)
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 1.0:
		direction = direction.normalized()

	if Input.is_action_just_pressed("boost"):
		max_speed = boost_speed
		get_node("Timer").start()

	desired_velocity = max_speed * direction
	steering = desired_velocity - velocity
	velocity += steering * steering_factor * delta
	position += velocity * delta

	if direction.length() > 0.0:
		rotation = velocity.angle()


func _on_timer_timeout() -> void:
	max_speed = normal_speed
