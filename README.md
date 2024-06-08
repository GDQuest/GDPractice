# GDPractice

GDPractice is a complete solution for creating interactive coding practices in the Godot engine.

After iterating over solutions for interactive practices, which we first open-sourced in [Learn GDScript from Zero](https://github.com/GDQuest/learn-gdscript), we went back to the drawing board to create a more robust and flexible solution with Godot 4. GDPractice is the result of that work. It's already used in [Learn 2D Gamedev From Zero with Godot 4](https://school.gdquest.com/products/learn_2d_gamedev_godot_4/) to teach game development to high school students and aspiring developers worldwide.

## Features

- **Requirements and checks:** You can register requirements and checks to validate the user's work. Requirements are prerequisites needed for your practice tests to run that help avoid errors if learners remove or rename properties, functions, etc. Checks are the actual tests that validate the user's work. The framework provides a simple API to create common checks and requirements.
- **Test space:** To make practices suitable for teaching gamedev, writing unit tests that check the learner's code is not enough. A lot of production game code is not designed to be testable with unit tests. What if you want to check that the player is looking at the mouse each frame or that entering an area triggers a particular animation? GDPractice allows you to apply parameters of the learner's code to the solution at runtime, capture state from both the solution and the practice copy, and compare the two over time to validate the learner's work.
- **Simulate and display simulated input:** You can simulate input events required to test the user's work deterministically*. GDPractice captures these events and displays them to the learner.
- **Build system:**
    - The framework generates practice starter files based on the solution, so there's a single source of truth for each practice. It supports diffing scenes, scripts, and other resources.
    - You can generate two projects from a single Godot project: a workbook project for the user to complete the practices and a solution project with the correct solutions. It allows teachers to control the solutions and distribute the workbook projects to students.
    - Change any project settings when generating workbook projects. For example, you can remove all input actions from the workbook project if the practice requires the learner to create them.
- **Hides addon files:** GDPractice hides the addons/ and other files from the user in the workbook project to offer them a more streamlined experience browsing the project. The files are hidden from the FileSystem dock and quick picker dialogs.

\* Note that the practices' behavior can vary a little depending on the system, the learner's framerate, and input devices. 

## How to integrate into other projects

You can copy three of the addons/ in this repository to your project to use GDPractice:

- `addons/gdpractice/`
- `addons/gdquest_sparkly_bag`
- `addons/gdquest_theme_utils`

The first addon is the framework itself, and the last two are little code libraries used by GDPractice and some other open-source technologies we maintain, like [GDTour](https://github.com/GDQuest/gdtour), the interactive Godot tutorial framework.

The repository also comes with [gdplug](https://github.com/imjp94/gd-plug), a powerful tool to manage add-ons in your Godot projects and download them from open-source repositories. You can use it to add GDPractice or any other Godot addon to your project. First, copy the `addons/gdplug/` folder to your project, then create a file named `plug.gd` at the root of your Godot project with the following content:

```gdscript
#!/usr/bin/env -S godot --headless --script
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
 plug(
 "git@github.com:GDQuest/GDPractice.git",
 {include = ["addons/gdpractice", "addons/gdquest_sparkly_bag", "addons/gdquest_theme_utils"]}
 )
```

Then, run the following command in your terminal to download the addons:

```bash
godot --headless --script plug.gd update
```

## How to use

Due to our current workload, we still have limited documentation for GDPractice. However, several example practices are in the `practice_solutions/` folder of this repository.

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

## Troubleshooting

### Instantiated scenes in the workbook project practices point to solution scenes

In some cases, the instantiated scenes in the workbook project practices may appear to point to the solution scenes instead of the files in the `res://practices/` folder.

This can be due to a cache problem in the Godot editor. To fix this, you can try the following:

1. Close the Godot editor.
2. Delete the `.godot/` folder in the project directory.
3. Open the Godot editor and reload the project.

You can also open the `.tscn` files of generated practices in a text editor and ensure the paths to the scenes are correct.