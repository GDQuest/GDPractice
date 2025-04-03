@tool
extends "res://addons/gdpractice/metadata.gd"


func _init() -> void:
	list += [
		PracticeMetadata.new(
			"bullet_spawn",
			"Bullet Spawn",
			preload("res://practice_solutions/L2.P1.bullet/bullet_spawner.tscn")
		),
		PracticeMetadata.new(
			"adding_input",
			"Adding Input",
			preload("res://practice_solutions/L2.P2.adding_input/adding_input.tscn"),
			# This opens a custom script in case a practice has multiple scripts.
			["res://practice_solutions/L2.P2.adding_input/adding_input.gd"]
		),
		PracticeMetadata.new(
			"adding_timer",
			"Adding Timer",
			preload("res://practice_solutions/L2.P3.adding_timer/adding_timer.tscn")
		),
		PracticeMetadata.new(
			"making_ship_move",
			"Making ship move",
			preload("res://practice_solutions/L3.P1.making_ship_move/making_ship_move.tscn"),
			# Example of specifying multiple scripts to open automatically. The
			# last script will be in focus in the script editor.
			[
				"res://practices/L3.P1.making_ship_move/other_demo_script.gd",
				"res://practices/L3.P1.making_ship_move/making_ship_move.gd",
			]
		),
	]
