extends Sprite2D

var velocity := 10 * Vector2.RIGHT # var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	position += delta * velocity # position
