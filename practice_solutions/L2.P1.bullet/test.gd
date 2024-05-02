extends "res://addons/gdpractice/tester/test.gd"


func _build_requirements() -> void:
	_add_actions_requirement(["missing_input_action_1", "missing_input_action_2"])


func _build_checks() -> void:
	var c1 := Check.new()
	c1.description = "Check 1"

	var c1_1 := Check.new()
	c1_1.description = "Check 1.1 Sub"
	c1_1.checker = func() -> String: return "Check 1.1 Hint"
	c1.subchecks.push_back(c1_1)

	var c1_2 := Check.new()
	c1_2.description = "Check 1.2 Sub"
	c1_2.checker = func() -> String: return "Check 1.2 Hint"
	c1.subchecks.push_back(c1_2)

	var c2 := Check.new()
	c2.description = "Check 2 (Depends)"
	c2.checker = func() -> String: return "Check 2 Hint"
	c2.dependencies.push_back(c1)
	checks.append_array([c1, c2])
