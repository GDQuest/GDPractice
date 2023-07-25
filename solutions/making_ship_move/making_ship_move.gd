extends Sprite2D

const A := 1.0
const TEST := 3

var velocity := 100 * Vector2.RIGHT # var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	position += delta * velocity # position
