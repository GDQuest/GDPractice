extends Control

const Logger := preload("../logger/logger.gd")
const JSPayload := preload("../logger/js_payload.gd")
const Paths := preload("../paths.gd")
const Requirements := preload("requirements.gd")
const DB := preload("../db/db.gd")
const Test := preload("../tester/test.gd")
const Metadata := preload("../metadata.gd")

var _practice_info := {}
var _input_map := {}

var db := DB.new()

@onready var log_panel_container: PanelContainer = %LogPanelContainer
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer
@onready var ghost_layout: Control = %GhostLayout
@onready var split_layout: Control = %SplitLayout
@onready var toggle_x5_button: Button = %ToggleX5Button
@onready var ghost_button: Button = %GhostButton
@onready var split_button: Button = %SplitButton
@onready var input_panel_container: PanelContainer = %InputPanelContainer


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
		return

	if OS.has_feature("web"):
		log_panel_container.free()
		title_rich_text_label = null
		checks_v_box_container = null
		JSPayload.setup()

	Logger.setup(title_rich_text_label, checks_v_box_container)
	_prepare_practice_info()
	if _is_practice_scene():
		_prepare_for_test()
		var completion := await _check_practice()
		_restore_from_test(completion)
	else:
		var message := "Not a practice"
		JSPayload.new(
			JSPayload.Type.TESTER, JSPayload.Status.SKIP, _practice_info.file_path, message
		)
		Logger.log("%s...[color=orange]SKIP[/color]" % message)
		queue_free()


func _on_toggle_x5_button_toggled(is_toggled: bool) -> void:
	Engine.set_time_scale(5 if is_toggled else 1)


func _on_layout_button_group_pressed(button: BaseButton) -> void:
	if button == ghost_button:
		ghost_layout.visible = true
		split_layout.visible = false
		ghost_layout.refresh(split_layout.scenes)
	elif button == split_button:
		ghost_layout.visible = false
		split_layout.visible = true
		split_layout.refresh(ghost_layout.scenes)


func _prepare_practice_info() -> void:
	_practice_info.scene = get_tree().current_scene
	_practice_info.file_path = _practice_info.scene.scene_file_path
	_practice_info.dir_name = Paths.get_dir_name(_practice_info.file_path, Paths.PRACTICES_PATH)
	_practice_info.base_path = Paths.PRACTICES_PATH.path_join(_practice_info.dir_name)

	var metadata := Metadata.load()
	for practice_metadata: Metadata.PracticeMetadata in metadata:
		var path := Paths.to_practice(practice_metadata.main_scene)
		if path == _practice_info.file_path:
			_practice_info.metadata = practice_metadata
			break


func _is_practice_scene() -> bool:
	return (
		_practice_info.file_path.begins_with(Paths.PRACTICES_PATH) and "metadata" in _practice_info
	)


func _prepare_for_test() -> void:
	toggle_x5_button.toggled.connect(_on_toggle_x5_button_toggled)
	ghost_button.button_group.pressed.connect(_on_layout_button_group_pressed)
	input_panel_container.warn()
	for action in InputMap.get_actions():
		_input_map[action] = InputMap.action_get_events(action)
		InputMap.action_erase_events(action)


func _restore_from_test(completion: int) -> void:
	toggle_x5_button.toggled.disconnect(_on_toggle_x5_button_toggled)
	toggle_x5_button.disabled = true
	Engine.time_scale = 1
	input_panel_container.safe()
	for action in _input_map:
		for event in _input_map[action]:
			InputMap.action_add_event(action, event)


func _check_practice() -> int:
	var result := 0
	var message: String = _practice_info.dir_name.capitalize()
	JSPayload.new(JSPayload.Type.TESTER, JSPayload.Status.TITLE, _practice_info.base_path, message)
	# Logger.log_title("Checking...\n[b]%s[/b]" % message)

	var solution_packed_scene := load(Paths.to_solution(_practice_info.file_path))
	var solution: Node = solution_packed_scene.instantiate()
	ghost_layout.refresh([_practice_info.scene, solution])

	Requirements.setup(_practice_info.base_path)
	if not Requirements.check():
		return result

	var test_script := load(Paths.to_solution(_practice_info.base_path).path_join("test.gd"))
	var test: Test = test_script.new()
	add_child(test)

	await test.setup(_practice_info.scene, solution)
	result = await test.run()
	db.update({_practice_info.metadata.id: {completion = result}})
	db.save()
	return result
