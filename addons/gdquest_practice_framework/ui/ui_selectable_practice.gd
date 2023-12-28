## UI component for one practice.
@tool
extends Control

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
		button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if is_locked else Control.CURSOR_POINTING_HAND
		if is_locked:
			label_title.add_theme_color_override("font_color", COLOR_DISABLED_TEXT)
		else:
			label_title.remove_theme_color_override("font_color")

@onready var icon_lock: TextureRect = %IconLock
@onready var label_symbol: Label = %LabelSymbol
@onready var label_title: Label = %LabelTitle
@onready var label_free: Label = %LabelFree
@onready var button: Button = %Button


func _ready() -> void:
	is_free = is_free
	title = title
	is_locked = is_locked
	button.button_group = button_group
	button.pressed.connect(func emit_pressed(): pressed.emit(get_index()))


func setup() -> void:
	if not Engine.is_editor_hint():
		return

	icon_lock.custom_minimum_size *= ThemeUtils.editor_scale
	label_symbol.custom_minimum_size *= ThemeUtils.editor_scale
	for label: Label in [label_free, label_title, label_symbol]:
		ThemeUtils.scale_font_size(label)


## Makes this selected, pressing the child button node and emitting the pressed signal.
func select() -> void:
	button.set_pressed_no_signal(true)
	pressed.emit(get_index())


func deselect() -> void:
	button.set_pressed_no_signal(false)
