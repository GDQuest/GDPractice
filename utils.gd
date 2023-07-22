class_name Utils

const SEP := "/"


static func fs_find(pattern: String = "*", path: String = "res://") -> Array:
	var result := []
	var is_file := not pattern.ends_with(SEP)

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
			if path.match(pattern.rstrip(SEP)) and not is_file:
				result.push_back(new_path)
			result += fs_find(pattern, new_path)
		elif path.match(pattern):
			result.push_back(new_path)
		path = dir.get_next()

	return result
