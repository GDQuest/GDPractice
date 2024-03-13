static func edit_project_configuration() -> void:
	const INPUT_KEY := "input/%s"
	for action in InputMap.get_actions():
		if action.begins_with("ui"):
			continue
		ProjectSettings.set_setting(INPUT_KEY % action, null)
	ProjectSettings.save()
