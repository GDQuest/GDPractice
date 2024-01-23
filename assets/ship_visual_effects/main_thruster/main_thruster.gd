@tool
extends Line2D

@export var size_curve: Curve
@export var alpha_curve: Curve
@export var max_length := 160.0
@export var power = 1.0:
	set(value):
		power = clamp(value, 0.0, 1.0)
		length = size_curve.sample(power)
		self_modulate.a = alpha_curve.sample(power)
		if not gpu_particles_2d:
			return
		gpu_particles_2d.emitting = power > 0.45
@export var curl = 0.0:
	set(value):
		curl = value
		_do_redraw = true

var length = 100.0: 
	set(value):
		length = value * max_length
		_do_redraw = true
var resolution : int = 3

var _last_frame_rotation := global_rotation
var _angle_difference_smoothed := 0.0
var _do_redraw := false

@onready var gpu_particles_2d = %GPUParticles2D


func _ready():
	_update_drawing()
	gpu_particles_2d.emitting = Engine.is_editor_hint()
	if not Engine.is_editor_hint():
		power = 0.0


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction.length() > 0.0:
			power = lerp(power, 1.0, 10.0 * delta)
		else:
			power = max(0.0, power - 2.0 * delta)

		var angle_difference := wrapf(_last_frame_rotation - global_rotation, -PI, PI)
		_last_frame_rotation = global_rotation
		_angle_difference_smoothed = lerp_angle(_angle_difference_smoothed, angle_difference, 8.0 * delta)
		curl = _angle_difference_smoothed * 8.0

	if _do_redraw:
		_do_redraw = false
		_update_drawing()


func _update_drawing():
	width = length * 0.45
	var new_points := PackedVector2Array([Vector2(0, 0)])
	new_points.resize(resolution)
	var segment_length = length / float(resolution)
	for index in range(1, resolution):
		var ratio := index / float(resolution - 1)
		var point_previous := new_points[index - 1]
		new_points[index] = Vector2.from_angle(curl * ratio) * segment_length + point_previous
		
	points = new_points
