## UI component for one practice.
@tool
extends Control

const Progress := preload("../db/progress.gd")

const GD_EXT := ".gd"
const TSCN_EXT := ".tscn"
const SOLUTION_BORDER_WIDTH := 4

## Emitted when the child button node is pressed.
signal pressed(index: int)

const COLOR_DISABLED_TEXT := Color(0.51764708757401, 0.59607845544815, 0.74509805440903)

static var button_group := ButtonGroup.new()

@export var is_free := false:
	set(value):
		is_free = value
		if not label_free:
			await ready
		label_free.visible = is_free

@export var title := "":
	set(value):
		title = value
		if not label_title:
			await ready
		label_title.text = title

@export var is_locked := false:
	set(value):
		is_locked = value
		if not label_title:
			await ready

		button.disabled = is_locked
		icon_lock.visible = is_locked
		label_symbol.visible = not is_locked
		solution_button.visible = not is_locked
		button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if is_locked else Control.CURSOR_POINTING_HAND
		if is_locked:
			label_title.add_theme_color_override("font_color", COLOR_DISABLED_TEXT)
		else:
			label_title.remove_theme_color_override("font_color")

var id: StringName = ""
var solution_path: StringName = ""

@onready var icon_lock: TextureRect = %IconLock
@onready var label_symbol: Label = %LabelSymbol
@onready var label_title: Label = %LabelTitle
@onready var label_free: Label = %LabelFree
@onready var button: Button = %Button
@onready var solution_button: Button = %SolutionButton


func _ready() -> void:
	is_free = is_free
	title = title
	is_locked = is_locked
	button.button_group = button_group
	button.pressed.connect(func emit_pressed() -> void: pressed.emit(get_index()))
	solution_button.pressed.connect(func open_solution() -> void:
		var solution_scene_path := solution_path.replace(GD_EXT, TSCN_EXT)
		if FileAccess.file_exists(solution_scene_path):
			EditorInterface.open_scene_from_path(solution_scene_path)
	)


func setup() -> void:
	if not Engine.is_editor_hint():
		return

	icon_lock.custom_minimum_size *= ThemeUtils.editor_scale
	label_symbol.custom_minimum_size *= ThemeUtils.editor_scale
	for label: Label in [label_free, label_title, label_symbol]:
		ThemeUtils.scale_font_size(label)


## Makes this selected, pressing the child button node and emitting the pressed signal.
func select(is_solution := false) -> void:
	button.set_pressed_no_signal(true)
	var button_stylebox: StyleBoxFlat = button.get("theme_override_styles/pressed")
	if is_solution:
		button_stylebox.border_color.a = 1.0
		button_stylebox.set_expand_margin_all(0)
	else:
		button_stylebox.border_color.a = 0.0
		button_stylebox.set_expand_margin_all(SOLUTION_BORDER_WIDTH)
		pressed.emit(get_index())


func deselect() -> void:
	button.set_pressed_no_signal(false)


func update(progress: Progress) -> void:
	if not id in progress.state:
		return
	label_symbol.modulate.a = 1 if progress.state[id].completion == 1 else 0
