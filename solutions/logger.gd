class_name Logger

static var _title_rich_text_label: RichTextLabel = null
static var _checks_v_box_container: VBoxContainer = null


static func setup(title_rich_text_label: RichTextLabel, checks_v_box_container: VBoxContainer) -> void:
	_title_rich_text_label = title_rich_text_label
	_checks_v_box_container = checks_v_box_container


static func title(msg: String) -> void:
	print_rich("\n%s" % msg)
	if _title_rich_text_label == null:
		return
	_title_rich_text_label.text = msg


static func log(msg: String) -> void:
	print_rich(msg)
	if _checks_v_box_container == null:
		return
	var check_rich_text_label := CheckRichTextLabel.new()
	_checks_v_box_container.add_child(check_rich_text_label)
	check_rich_text_label.text = msg


static func add_separator() -> void:
	if _checks_v_box_container == null:
		return
	_checks_v_box_container.add_child(HSeparator.new())
