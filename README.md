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
		{include = ["addons/gdpractice", "addons/gdquest_sparkly_bag", "addons/gdquest_theme_utils"]},
	)
```

Then, run the following command in your terminal to download the addons:

```bash
godot --headless --script plug.gd update
```

## How to use

Due to our current workload, we still have limited documentation for GDPractice. However, several example practices are in the `practice_solutions/` folder of this repository.

A limitation of Godot is that we do not have a great system to register entry points or hooks to tell an add-on what configuration to use. So we rely on having GDScript files at specific paths to make GDPractice work:

1. `res://practice_solutions/metadata.gd`: This file should extend the `res://addons/gdpractice/metadata.gd` class. It's used to register and list the practices in your project.
2. `res://practice_solutions/build_settings.gd`: This file is optional. It's used to override the default build settings. Open the `res://addons/gdpractice/build_settings.gd` file to see the available settings you can override.
3. `res://practice_solutions/diff.gd`: This file is optional. It's used to edit the project settings at build time. For example, you can remove all input actions from the workbook project if the course or some practices require students to create them.

### Building projects

To build the workbook and solution projects, you can use the `build.gd` script in the `res://addons/gdpractice/` folder. Run the script with `godot --headless --script addons/gdpractice/build.gd -- --help` to get its documentation and all the options.

To build, and for practices to work, the system requires you to create a practice metadata file at the path `res://practice_solutions/metadata.gd`. This file should extend the class `res://addons/gdpractice/metadata.gd`.

### Changing build settings

You can control the settings applied at build time by creating a file named `res://practice_solutions/build_settings.gd`. This file should extend the `res://addons/gdpractice/build_settings.gd` class.

Open the `res://addons/gdpractice/build_settings.gd` file to see the available settings you can override.

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

## How practice tests run

Every practice has a script named test.gd that extends the built-in script tester/test.gd. This script is responsible for running the practice tests. The test.gd script exposes a few virtual functions it calls in preparation before running the checks.

The testing system waits for nodes in the tree to be ready before running the tests. It ensures that the practice and solution are initialized before collecting data.

The system runs the following functions in order and in relatively rapid succession:

1. `_build_requirements()`: checks pre-requisites before running other functions.
2. `_setup_state()`: used to harmonize the properties of the student practice and solution scene.
3. `_setup_populate_test_space()`: used to collect data from the running practice and solution scene.
4. `_build_checks()`: creates unit tests used to test student code.

Here's some more detail. Two functions are provided to build requirements and checks:

1. `_build_requirements()`: This function is called before the practice starts running. It should check if the practice has all the necessary variables, functions, signal connections, and so on to run without errors. For example, you can use this to check if a node or property exists in the student practice so that you can safely access it without error later on. If the requirements are not met, the other functions will not run to avoid errors. To add requirements, add `Requirement` objects to the `requirements` array.
2. `_build_checks()`: This function is called after the practice has run for a moment. It should be used to check if the practice is behaving as expected. If the checks fail, the practice will be marked as failed. To add checks, create `Check` objects and add them to the `checks` array.

Two functions allow the practice system to capture data from the practice and solution:

1. `_setup_state()`: This async function is called before the practice starts running, once all nodes are ready in the scene tree. It should be used to copy the state of the practice to the solution. Use this to ensure that the practice and solution start with the same properties. For example, you can copy the speed or health of a character from the practice to the solution.
2. `_setup_populate_test_space()`: This async function is called right after `_setup_state()`. It should be used to capture data from the practice and solution. Use this to collect the state of the practice and the solution during the practice. For example, you can capture the position of a character in the practice and solution to compare them later.

The two functions above run one after the other and are separated just for conceptual clarity.

## How to collect data from the practice and solution

The needs of practice tests are very different, so the data you collect and how you collect it is entirely up to you. You collect all the data you need in `_setup_populate_test_space()`. You can store the data however you want, though I recommend using the provided `_test_space` array. Some helper functions in the `Test` class make it easier to check the data later on.

### Storing data over multiple frames

To store data from multiple frames, use `await` in the `_setup_populate_test_space()` function. This will allow you to run code over multiple frames. For example, you can use the following code to store the position of a character in the practice and solution over ten frames:

```gdscript
func _setup_populate_test_space() -> void:
	for i in range(10):
		var data := {
			"practice_global_position": _practice.global_position,
			"solution_global_position": _solution.global_position
		}
		_test_space.append(data)
		await get_tree().physics_frame
```

I prefer using an inner class to store the data, to get static typing, and to make it easier to access the data later on. Here's the same example using an inner class:

```gdscript
class TestData:
	var practice_global_position := Vector2.ZERO
	var solution_global_position := Vector2.ZERO


func _setup_populate_test_space() -> void:
	for i in range(10):
		var data := TestData.new()
		data.practice_global_position = _practice.global_position
		data.solution_global_position = _solution.global_position
		_test_space.append(data)
		await get_tree().physics_frame
```

Alternatively, the test script provides the method `_connect_timed()` to collect data over some time. Here's a typical example: collecting frame data over one second:

```gdscript
func _setup_populate_test_space() -> void:
	await _connect_timed(1.0, get_tree().process_frame, _populate_test_space)


func _populate_test_space() -> void:
	var data := TestData.new()
	data.practice_global_position = _practice.global_position
	data.solution_global_position = _solution.global_position
	_test_space.append(data)
```

## Simulating player input

One key difference between game dev practices and usual interactive programming exercises is that we simulate player input and need to ensure that the student code accounts for this input.

Godot has two main ways to check for player input:

1. Polling in the `_process()` and `_physics_process()` functions.
2. Using the `_input()` functions with input events.

Similarly, we use two different approaches to inject and simulate inputs depending on the approach used by the practice:

1. Polling: We can simulate player input in the processing loop by calling `Input.action_press()` and `Input.action_release()`.
2. Input events: We can simulate player input by creating an `InputEvent` object and calling `Input.parse_input_event()`.

### Examples

The following example simulates the player moving to the right for 0.3 seconds and collecting data in the test space.

```gdscript
func _setup_populate_test_space() -> void:
	Input.action_press("move_right")
	await _connect_timed(0.3, get_tree().process_frame, _populate_test_space)
	Input.action_release("move_right")


func _populate_test_space() -> void:
	_test_space.append({
		"practice_position": _practice.position,
		"solution_position": _practice.position,
	})
```

For input events, it's different as we need to create an `InputEvent` object and call `Input.parse_input_event()`. We use them more for one-time events like mouse clicks or key presses. Here's an example of simulating pressing the space bar:

```gdscript
func _setup_populate_test_space() -> void:
	var event = InputEventKey.new()
	event.scancode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)

	# ... collect data
```

## Troubleshooting

### Instantiated scenes in the workbook project practices point to solution scenes

In some cases, the instantiated scenes in the workbook project practices may appear to point to the solution scenes instead of the files in the `res://practices/` folder.

This can be due to a cache problem in the Godot editor. To fix this, you can try the following:

1. Close the Godot editor.
2. Delete the `.godot/` folder in the project directory.
3. Open the Godot editor and reload the project.

You can also open the `.tscn` files of generated practices in a text editor and ensure the paths to the scenes are correct.
