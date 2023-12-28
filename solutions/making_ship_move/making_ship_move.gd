extends Sprite2D
var metadata := PracticeMetadata.new("Making Ship Move", "MAKING_SHIP_MOVE_ID") #

var velocity := 100 * Vector2.RIGHT # var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	position += delta * velocity # position
