## Utility script to handle paths and file names for practice and solution files.
extends RefCounted

const RES := "res://"
const PRACTICES_PATH := RES + "practices"
const SOLUTIONS_PATH := RES + "practice_solutions"


static func to_solution(path: String) -> String:
	return path.replace(PRACTICES_PATH, SOLUTIONS_PATH)


static func to_practice(path: String) -> String:
	return path.replace(SOLUTIONS_PATH, PRACTICES_PATH)


static func get_dir_name(path: String, relative_to := SOLUTIONS_PATH) -> String:
	const DELIM := "/"
	var result := path.replace(relative_to, "")
	result = "" if result == path else result.lstrip(DELIM).get_slice(DELIM, 0)
	return result
