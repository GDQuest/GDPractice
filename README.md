# Godot practice framework

A toolkit for creating interactive practices in the Godot engine.

### Editing project configuration at build time

You can edit the project settings (the `project.godot` file) at build time by creating a script named `diff.gd` in the `res://practice_solutions/` folder.

This is useful for removing or adding input actions, changing the project's main scene, or changing the project settings in the workbook and solution projects.

The project settings are used as the reference for the solution project, and the `diff.gd` script is applied when generating the workbook project.

For example, this code snippet removes all input actions from the workbook, except for the `ui_*` actions included by default by Godot.

```gdscript
static func edit_project_configuration() -> void:
    const INPUT_KEY := "input/%s"
    for action in InputMap.get_actions():
        if action.begins_with("ui"):
            continue
        ProjectSettings.set_setting(INPUT_KEY % action, null)
    ProjectSettings.save()
```
