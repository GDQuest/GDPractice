class_name Logger

class Payload:
	enum {TESTER, TEST, REQUIREMENT}

	var type := TESTER
	var path := ""
	var fmt := ""
	var parts: Array = []
	var msg: String:
		get:
			return fmt % parts
	var json: Variant:
		get:
			var result: Variant = JavaScriptBridge.create_object("Object")
			result.type = type
			result.path = path
			result.fmt = fmt

			var part_count := parts.size()
			var result_parts: Variant = JavaScriptBridge.create_object("Array", part_count)
			for idx in range(part_count):
				result_parts[idx] = parts[idx]
			result.parts = result_parts
			return result

	func _init(type: int, path: String, fmt: String, parts: Array = []) -> void:
		self.type = type
		self.path = path
		self.fmt = fmt
		self.parts = parts


static var _js_interface: JavaScriptObject = null
static var _title_rich_text_label: RichTextLabel = null
static var _checks_v_box_container: VBoxContainer = null


static func setup(
	title_rich_text_label: RichTextLabel,
	checks_v_box_container: VBoxContainer
) -> void:
	if is_instance_valid(title_rich_text_label):
		_title_rich_text_label = title_rich_text_label

	if is_instance_valid(checks_v_box_container):
		_checks_v_box_container = checks_v_box_container

	if OS.has_feature("web"):
		_js_interface = JavaScriptBridge.get_interface("gdquest")


static func log_title(payload: Payload) -> void:
	if _js_interface != null:
		_js_interface.log_title(payload.json)

	var msg := payload.msg
	print_rich("\n%s" % msg)

	if _title_rich_text_label == null:
		return
	_title_rich_text_label.text = msg


static func log(payload: Payload) -> void:
	if _js_interface != null:
		_js_interface.log(payload.json)

	var msg := payload.msg
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
