@tool
extends PanelContainer

const Paths := preload("../paths.gd")

const IS_SOLUTION_TEXT := """You are viewing the [b]%s[/b] file which is part of the solution for [b]%s[/b] practice.

[b]Instead, to complete the practice[/b], you need to open the [b][url]%s[/url][/b] file.
"""

const HAS_SOLUTION_TEXT := (
	"""You added nodes from the [b]%s[/b] folder.

Tests will not run correctly until you remove them:
"""
	% Paths.SOLUTIONS_PATH
)

@onready var rich_text_label: RichTextLabel = %RichTextLabel


func _ready() -> void:
	rich_text_label.meta_clicked.connect(_on_rich_text_label_meta_clicked)


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	EditorInterface.open_scene_from_path(str(meta))


func set_is_solution_text(
	scene_path: String, practice_path: String, practice_title: String
) -> void:
	rich_text_label.text = IS_SOLUTION_TEXT % [scene_path, practice_title, practice_path]


func set_has_solution_text(nodes: Array[Node]) -> void:
	var mapper := func(n: Node) -> String: return (
		"[ul][b]%s[/b] from [b]%s[/b][/ul]" % [n.name, n.scene_file_path]
	)
	rich_text_label.text = HAS_SOLUTION_TEXT + "\n".join(nodes.map(mapper))
