static func adding_timer(scene: Node) -> void:
	var timer: Timer = scene.get_node("Timer")
	scene.remove_child(timer)
