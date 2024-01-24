extends Sprite2D

var velocity := 100 * Vector2.RIGHT # var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	position += delta * velocity # position
