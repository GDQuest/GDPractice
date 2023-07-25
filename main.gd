extends Control

@onready var tester: Tester = %Tester


func _ready() -> void:
	Builder.build()
	tester.check()
