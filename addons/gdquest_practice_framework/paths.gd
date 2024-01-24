const PRACTICES_PATH := "res://practices"
const SOLUTIONS_PATH := "res://addons/gdquest_practice_framework/solutions"


static func to_solution(path: String) -> String:
	return path.replace(PRACTICES_PATH, SOLUTIONS_PATH)


static func to_practice(path: String) -> String:
	return path.replace(SOLUTIONS_PATH, PRACTICES_PATH)
