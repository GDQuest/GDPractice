extends Control

const GhostLayoutScene := preload("ghost_layout.tscn")
const SplitLayoutScene := preload("split_layout.tscn")

var _practice_info := {}
var _input_map := {}

@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var title_rich_text_label: RichTextLabel = %TitleRichTextLabel
@onready var checks_v_box_container: VBoxContainer = %ChecksVBoxContainer
@onready var ghost_layout: Control = %GhostLayout
@onready var split_layout: Control = %SplitLayout
@onready var toggle_x5_button: Button = %ToggleX5Button
@onready var toggle_layout_button: Button = %ToggleLayoutButton


func _ready() -> void:
	if OS.has_feature("web"):
		h_box_container.queue_free()
	else:
		Logger.setup(title_rich_text_label, checks_v_box_container)

	_prepare_practice_info()
	if not _is_practice_scene():
		Logger.log("Not a practice...[color=orange]SKIP[/color]")
		queue_free()
		return

	_prepare_for_test()
	await _check_practice()
	_restore_from_test()


func _on_toggle_x5_button_toggled(is_toggled: bool) -> void:
	Engine.set_time_scale(5 if is_toggled else 1)


func _on_toggle_layout_button_toggled(is_toggled: bool) -> void:
	if is_toggled:
		ghost_layout.visible = false
		split_layout.visible = true
		split_layout.refresh(ghost_layout.scenes)
	else:
		ghost_layout.visible = true
		split_layout.visible = false
		ghost_layout.refresh(split_layout.scenes)


func _prepare_practice_info() -> void:
	_practice_info.scene = get_tree().current_scene
	_practice_info.file_path = _practice_info.scene.scene_file_path
	_practice_info.file_name = _practice_info.file_path.get_file()
	_practice_info.base_path = _practice_info.file_path.get_base_dir()
	_practice_info.dir_name = _practice_info.base_path.get_file()


func _is_practice_scene() -> bool:
	return (
		_practice_info.file_path.begins_with(Builder.PRACTICES_PATH)
		and "%s.tscn" % _practice_info.dir_name == _practice_info.file_name
	)


func _prepare_for_test() -> void:
	toggle_x5_button.toggled.connect(_on_toggle_x5_button_toggled)
	toggle_layout_button.toggled.connect(_on_toggle_layout_button_toggled)
	for action in InputMap.get_actions():
		_input_map[action] = InputMap.action_get_events(action)
		InputMap.action_erase_events(action)


func _restore_from_test() -> void:
	toggle_x5_button.toggled.disconnect(_on_toggle_x5_button_toggled)
	toggle_x5_button.disabled = true
	Engine.time_scale = 1
	for action in _input_map:
		for event in _input_map[action]:
			InputMap.action_add_event(action, event)


func _check_practice() -> void:
	Logger.title("Checking...\n[b]%s[/b]" % _practice_info.file_name.get_basename().capitalize())

	Requirements.setup(_practice_info.base_path)
	if not Requirements.check():
		return

	var solution_packed_scene := load(_to_solution(_practice_info.file_path))
	var solution: Node = solution_packed_scene.instantiate()
	ghost_layout.refresh([_practice_info.scene, solution])

	var test_script := load(
		_to_solution(_practice_info.base_path)
		.path_join("%s_test.gd" % _practice_info.file_name.get_basename())
	)
	var test: Test = test_script.new()
	add_child(test)

	await test.setup(_practice_info.scene, solution)
	await test.run()


static func _to_solution(path: String) -> String:
	return path.replace(Builder.PRACTICES_PATH, Builder.SOLUTIONS_PATH)
