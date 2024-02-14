## UI component for one practice.
@tool
extends MarginContainer

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const Progress := preload("../db/progress.gd")
const Metadata := preload("../metadata.gd")
const ThemeUtils := preload("../utils/theme_utils.gd")

const DEFAULT_VARIATION := &"MarginContainerPractice"
const SELECTED_VARIATION := &"MarginContainerSelectedPractice"

const ITEM_FORMAT := "L%d.P%d"
const COLOR_DISABLED_TEXT := Color(0.51764708757401, 0.59607845544815, 0.74509805440903)
const CHECKBOX_TEXTURES := {
	false: preload("../assets/checkbox_empty.svg"),
	true: preload("../assets/checkbox_ticked.svg"),
}

static var button_group := ButtonGroup.new()
static var build := Build.new()

var practice_metadata: Metadata.PracticeMetadata = null

@onready var label_item: Label = %LabelItem
@onready var label_title: Label = %LabelTitle
@onready var button: Button = %Button
@onready var reset_button: Button = %ResetButton
@onready var run_button: Button = %RunButton
@onready var icon_checkbox: TextureRect = %IconCheckbox
@onready var run_button_container: VBoxContainer = %RunButtonContainer


func _ready() -> void:
	button.button_group = button_group
	button.pressed.connect(open)
	run_button.pressed.connect(EditorInterface.play_current_scene)
	reset_button.pressed.connect(reset_practice)
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	theme = ThemeUtils.generate_scaled_theme(theme)
	for control: Control in find_children("", "TextureRect") + find_children("", "TextureButton"):
		control.custom_minimum_size *= EditorInterface.get_editor_scale()


func setup(metadata: Metadata.PracticeMetadata) -> void:
	self.practice_metadata = metadata
	label_title.text = metadata.title
	label_item.text = ITEM_FORMAT % [metadata.lesson_number, metadata.practice_number]


## Makes this selected, pressing the child button node and emitting the pressed signal.
func select() -> void:
	button.set_pressed_no_signal(true)
	theme_type_variation = SELECTED_VARIATION
	reset_button.visible = true
	run_button_container.visible = true


func deselect() -> void:
	button.set_pressed_no_signal(false)
	theme_type_variation = DEFAULT_VARIATION
	reset_button.visible = false
	run_button_container.visible = false


func update(progress: Progress) -> void:
	if not practice_metadata.id in progress.state:
		return
	icon_checkbox.texture = CHECKBOX_TEXTURES[progress.state[practice_metadata.id].completion == 1]


func open() -> void:
	var practice_scene_path = Paths.to_practice(practice_metadata.main_scene)
	if FileAccess.file_exists(practice_scene_path):
		EditorInterface.open_scene_from_path(practice_scene_path)
		await get_tree().process_frame
		select()


func reset_practice() -> void:
	var db := DB.new()
	db.progress.state[practice_metadata.id].completion = 0
	db.save()

	var solution_dir_name := Paths.get_dir_name(practice_metadata.main_scene)
	if not solution_dir_name.is_empty():
		build.build_practice(solution_dir_name, true)
		update(db.progress)
