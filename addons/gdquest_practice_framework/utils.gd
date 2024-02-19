extends RefCounted

const SEP := "/"


static func fs_find(pattern: String = "*", path: String = "res://") -> Array[String]:
	var result: Array[String] = []
	var is_file := not pattern.ends_with(SEP)
	pattern = pattern.rstrip(SEP)

	var dir := DirAccess.open(path)
	if DirAccess.get_open_error() != OK:
		printerr("ERROR: could not open [%s]" % path)
		return result

	if dir.list_dir_begin() != OK:
		printerr("ERROR: could not list contents of [%s]" % path)
		return result

	path = dir.get_next()
	while path.is_valid_filename():
		var new_path: String = dir.get_current_dir().path_join(path)
		if dir.current_is_dir():
			if not is_file and (path == pattern or new_path.match(pattern)):
				result.push_back(new_path)
			result += fs_find(pattern, new_path)
		elif path == pattern or new_path.match(pattern):
			result.push_back(new_path)
		path = dir.get_next()
	return result


static func fs_remove_dir(base_path: String) -> void:
	if not DirAccess.dir_exists_absolute(base_path):
		return
	for path in fs_find("*", base_path):
		DirAccess.remove_absolute(path)

	var paths := fs_find("*/", base_path)
	paths.reverse()
	for path in paths:
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(base_path)


static func flatten_unique(array: Array) -> Array:
	var result := {}
	for key in flatten(array):
		result[key] = null
	return result.keys()


static func flatten(array: Array) -> Array:
	return array.reduce(func(acc: Array, xs: Array) -> Array: return acc + xs, [])
