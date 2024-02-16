extends Button


const ICONS := {
	false: preload("../assets/icons/ghost_on_split.svg"),
	true: preload("../assets/icons/ghost_split_on.svg"),
}


func _ready() -> void:
	toggled.connect(_on_toggled)


func _on_toggled(is_toggled: bool) -> void:
	icon = ICONS[is_toggled]
