## UI component for one practice.
@tool
extends Control

signal pressed

const ThemeUtils := preload("res://addons/gdquest_practice_framework/utils/theme_utils.gd")
const Paths := preload("../paths.gd")
const Progress := preload("../db/progress.gd")
const Metadata := preload("../metadata/metadata.gd")

const COLOR_DISABLED_TEXT := Color(0.51764708757401, 0.59607845544815, 0.74509805440903)

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
		button.mouse_default_cursor_shape = (
			Control.CURSOR_FORBIDDEN if is_locked else Control.CURSOR_POINTING_HAND
		)
		if is_locked:
			label_title.add_theme_color_override("font_color", COLOR_DISABLED_TEXT)
		else:
			label_title.remove_theme_color_override("font_color")

var metadata: Metadata = null
var button_group: ButtonGroup = null


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
	button.pressed.connect(open)

	if not Engine.is_editor_hint():
		return

	icon_lock.custom_minimum_size *= ThemeUtils.editor_scale
	label_symbol.custom_minimum_size *= ThemeUtils.editor_scale
	for label: Label in [label_free, label_title, label_symbol]:
		ThemeUtils.scale_font_size(label)


func setup(metadata: Metadata, button_group: ButtonGroup) -> void:
	self.metadata = metadata
	self.button_group = button_group
	title = metadata.title
	is_free = metadata.is_free()
	is_locked = not is_free


## Makes this selected, pressing the child button node and emitting the pressed signal.
func select() -> void:
	button.set_pressed_no_signal(true)
	pressed.emit()


func deselect() -> void:
	button.set_pressed_no_signal(false)


func update(progress: Progress) -> void:
	if not metadata.id in progress.state:
		return
	label_symbol.modulate.a = 1 if progress.state[metadata.id].completion == 1 else 0


func open() -> void:
	for scene_file_path in metadata.scene_file_paths:
		scene_file_path = Paths.to_practice(scene_file_path)
		if FileAccess.file_exists(scene_file_path):
			EditorInterface.open_scene_from_path(scene_file_path)
			await get_tree().process_frame
			select()
		break
	pressed.emit()
