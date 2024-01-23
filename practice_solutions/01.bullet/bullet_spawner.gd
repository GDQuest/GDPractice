extends Node2D

# This defines a signal to help detect when a bullet was spawned.
signal bullet_spawned(new_bullet)


func _ready() -> void:
	# We have a cyclical timer that times out every second. This line makes it
	# so every time the timer times out, the engine will call the spawn_bullet
	# function.
	%Timer.timeout.connect(spawn_bullet)


# This function spawns a new bullet.
func spawn_bullet():
	# Before spawning a bullet we need to load the corresponding scene.
	# A scene is like a blueprint we can create instances from.
	# Note that Godot is smart and will only load the scene once.
	const BulletScene := preload("bullet.tscn")

	# We create an instance of the bullet scene here.
	var bullet_instance := BulletScene.instantiate()
	# For each new bullet we spawn we calculate a random velocity pointing in a
	# different direction to test your code.
	var random_angle := randf_range(-PI, PI)
	bullet_instance.velocity = Vector2.RIGHT.rotated(random_angle) * 500.0
	# We need to add the instance to the game's node tree for it to show up. We
	# use the add_child function for that.
	add_child(bullet_instance)
	bullet_spawned.emit(bullet_instance)
