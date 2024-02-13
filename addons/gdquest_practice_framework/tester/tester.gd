extends Control

const Test := preload("test.gd")
const LogEntry := preload("log_entry/log_entry.gd")
const Paths := preload("../paths.gd")
const Requirements := preload("requirements.gd")
const DB := preload("../db/db.gd")
const Metadata := preload("../metadata.gd")

const LogEntryPackedScene := preload("log_entry/log_entry.tscn")

const ICON_PATH := "../assets/icons/%s.svg"
const ITEM := "L%d.P%d"
const REPORT_STATUS := {
	0: {text = "FAIL", theme_type_variation = &"LabelTesterStatusFail"},
	1: {text = "PASS", theme_type_variation = &"LabelTesterStatusPass"},
}
const REPORT_STEPS = {
	prep = {text = "Setting up the test..."},
	setup_fail = {text = "Test setup failed."},
	testing = {text = "Verifying your practice tasks..."},
	test_fail = {text = "Looks like you've got some things to fix."},
	test_pass = {text = "Congradulations! You aced this practice."},
}

var _practice_info := {}
var _input_map := {}

var db := DB.new()

@onready var item_label: Label = %ItemLabel
@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel

@onready var report_texture_rect: TextureRect = %ReportTextureRect
@onready var report_label: Label = %ReportLabel
@onready var input_panel_container: PanelContainer = %InputPanelContainer
@onready var log_v_box_container: VBoxContainer = %LogVBoxContainer

@onready var ghost_layout: Control = %GhostLayout
@onready var split_layout: Control = %SplitLayout

@onready var toggle_show_button: Button = %ToggleShowButton
@onready var toggle_x5_button: Button = %ToggleX5Button
@onready var ghost_button: Button = %GhostButton
@onready var split_button: Button = %SplitButton

@onready var tween: Tween = create_tween()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
		return

	tween.kill()
	toggle_show_button.toggled.connect(_on_toggle_show_button)

	_prepare_practice_info()
	_report_prep()

	if _is_practice_scene():
		_prepare_for_test()
		_report({report_label: REPORT_STEPS.testing})

		var test := await _check_practice()
		var completion := test.get_completion()
		db.update({_practice_info.metadata.id: {completion = completion}})
		db.save()

		_restore_from_test()
		_report_checks(test)
		_report_test(completion)
	else:
		queue_free()


func _on_toggle_show_button(is_toggled: bool) -> void:
	tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN)
	if is_toggled:
		toggle_show_button.icon = preload(ICON_PATH % "hide")
		tween.tween_property(self, "custom_minimum_size:x", 1920, 0.1)
	else:
		toggle_show_button.icon = preload(ICON_PATH % "show")
		tween.tween_property(self, "custom_minimum_size:x", 2340, 0.1)


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


func _restore_from_test() -> void:
	toggle_x5_button.toggled.disconnect(_on_toggle_x5_button_toggled)
	toggle_x5_button.disabled = true
	Engine.time_scale = 1
	input_panel_container.safe()
	for action in _input_map:
		for event in _input_map[action]:
			InputMap.action_add_event(action, event)


func _check_practice() -> Test:
	var result: Test = null
	var solution_packed_scene := load(Paths.to_solution(_practice_info.file_path))
	var solution: Node = solution_packed_scene.instantiate()
	ghost_layout.refresh([_practice_info.scene, solution])

	Requirements.setup(_practice_info.base_path)
	if Requirements.check():
		var test_script := load(Paths.to_solution(_practice_info.base_path).path_join("test.gd"))
		var test: Test = test_script.new()
		add_child(test)

		await test.setup(_practice_info.scene, solution)
		await test.run()
		result = test
	return result


func _report(info: Dictionary) -> void:
	for node: Control in info:
		for prop: String in info[node]:
			node.set(prop, info[node][prop])


func _report_prep() -> void:
	if not "metadata" in _practice_info:
		return

	var pm: Metadata.PracticeMetadata = _practice_info.metadata
	_report(
		{
			item_label: {text = ITEM % [pm.lesson_number, pm.practice_number]},
			title_label: {text = pm.title},
			report_label: REPORT_STEPS.prep,
		}
	)


func _report_checks(test: Test) -> void:
	for check in test.checks:
		_report_check(check)
		for subcheck in check.subchecks:
			_report_check(subcheck, true)


func _report_check(check: Test.Check, is_subcheck := false) -> void:
	var log_entry := LogEntryPackedScene.instantiate()
	log_v_box_container.add_child(log_entry)

	var has_subchecks := not check.subchecks.is_empty()
	var info: Dictionary = log_entry.get_variation("check_default")
	if is_subcheck and check.status == Test.Status.FAIL:
		info = log_entry.get_variation("subcheck_fail")
	elif is_subcheck and check.status == Test.Status.PASS:
		info = log_entry.get_variation("subcheck_pass")
	elif is_subcheck and check.status == Test.Status.DISABLE:
		info = log_entry.get_variation("subcheck_default")
	elif not is_subcheck and has_subchecks and check.status == Test.Status.FAIL:
		info = log_entry.get_variation("check_fail")
	elif not is_subcheck and has_subchecks and check.status == Test.Status.PASS:
		info = log_entry.get_variation("check_pass")
	elif not is_subcheck and not has_subchecks and check.status == Test.Status.FAIL:
		info = log_entry.get_variation("check_no_subchecks_fail")
	elif not is_subcheck and not has_subchecks and check.status == Test.Status.PASS:
		info = log_entry.get_variation("check_no_subchecks_pass")

	info[log_entry.rich_text_label].merge({text = check.description})
	info[log_entry.extra_rich_text_label].merge({text = check.hint})
	_report(info)


func _report_test(completion: int) -> void:
	var info := {}
	info[status_label] = REPORT_STATUS[completion]
	if completion == 0:
		info[report_label] = REPORT_STEPS.test_fail
		info[report_texture_rect] = {visible = false, texture = preload(ICON_PATH % "fail")}
	else:
		info[report_label] = REPORT_STEPS.test_pass
		info[report_texture_rect] = {visible = true, texture = preload(ICON_PATH % "pass")}
	_report(info)
