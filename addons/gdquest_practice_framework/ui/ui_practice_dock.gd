@tool
extends VBoxContainer

const UISelectablePractice := preload("ui_selectable_practice.gd")

const UI_SELECTABLE_PRACTICE_SCENE := preload("ui_selectable_practice.tscn")

const PRACTICES := [
	preload("res://solutions/adding_input/adding_input.gd"),
	preload("res://solutions/adding_timer/adding_timer.gd"),
	preload("res://solutions/making_ship_move/making_ship_move.gd"),
]

@onready var list: VBoxContainer = %List
@onready var footer: HBoxContainer = %Footer


func _ready() -> void:
	for Practice in PRACTICES:
		var practice: Node = Practice.new()
		var ui_selectable_practice: UISelectablePractice = UI_SELECTABLE_PRACTICE_SCENE.instantiate()
		list.add_child(ui_selectable_practice)
		ui_selectable_practice.setup()
		ui_selectable_practice.pressed.connect(enable_footer_buttons, CONNECT_ONE_SHOT)
		ui_selectable_practice.title = practice.metadata.title


func enable_footer_buttons() -> void:
	for button: Button in footer.get_children():
		button.disabled = false
