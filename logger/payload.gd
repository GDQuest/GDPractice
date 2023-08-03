class_name Payload

enum Type {TESTER, TEST, REQUIREMENT}

var type := Type.TESTER
var path := ""
var fmt := ""
var parts: Array = []
var msg: String:
	get:
		return fmt % parts
var json: Variant:
	get:
		var result: Variant = JavaScriptBridge.create_object("Object")
		result.type = Type.keys()[type]
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
