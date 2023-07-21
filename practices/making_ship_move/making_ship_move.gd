extends Sprite2D

var velocity := 100 * Vector2.RIGHT


func _process(delta: float) -> void:
	position += delta * velocity
