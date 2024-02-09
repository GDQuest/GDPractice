## UI component for one practice.
@tool
extends MarginContainer

const DB := preload("../db/db.gd")
const Build := preload("../build.gd")
const Paths := preload("../paths.gd")
const Progress := preload("../db/progress.gd")
const Metadata := preload("../metadata.gd")

const DEFAULT_VARIATION := &"MarginContainerPractice"
const SELECTED_VARIATION := &"MarginContainerSelectedPractice"

const ITEM_FORMAT := "L%d.P%d"
const COLOR_DISABLED_TEXT := Color(0.51764708757401, 0.59607845544815, 0.74509805440903)
const CHECKBOX_TEXTURES := {
	false: preload("res://addons/gdquest_practice_framework/ui/assets/checkbox_empty.svg"),
	true: preload("res://addons/gdquest_practice_framework/ui/assets/checkbox_ticked.svg"),
}

static var button_group := ButtonGroup.new()
static var build := Build.new()

var metadata_item: Metadata.Item = null

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


func setup(metadata: Metadata.Item) -> void:
	self.metadata_item = metadata
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
	if not metadata_item.id in progress.state:
		return
	icon_checkbox.texture = CHECKBOX_TEXTURES[progress.state[metadata_item.id].completion == 1]


func open() -> void:
	for scene in metadata_item.scenes:
		var practice_scene_path = Paths.to_practice(scene.resource_path)
		if FileAccess.file_exists(practice_scene_path):
			EditorInterface.open_scene_from_path(practice_scene_path)
			await get_tree().process_frame
			select()
		break


func reset_practice() -> void:
	var db := DB.new()
	db.progress.state[metadata_item.id].completion = 0
	db.save()

	var solution_dir_name := ""
	for scene: PackedScene in metadata_item.scenes:
		solution_dir_name = scene.resource_path.get_base_dir().get_file()
		break

	if not solution_dir_name.is_empty():
		build.build_practice(solution_dir_name, true)
		update(db.progress)
