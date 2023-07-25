class_name Requirements

static var _name_sorter := func(x: Dictionary, y: Dictionary) -> bool: return x.name < y.name

static var _erase_arg_name_transformer := func(f: Dictionary) -> Dictionary:
	f.args.map(func(arg: Dictionary) -> Dictionary:
		arg.erase("name")
		return arg)
	return f

static var _index_node_transformer := func(x: int, state: SceneState) -> Dictionary:
	return {path_for_parent = state.get_node_path(x, true), name = state.get_node_name(x), type = state.get_node_type(x)}

static var _list := {}


static func setup(practice_base_path: String) -> void:
	var path_transformer := func(x: String) -> Dictionary:
		return {
			practice = x,
			solution = x.replace(Builder.PRACTICES_PATH, Builder.SOLUTIONS_PATH),
		}

	var file_exists_predicate := func(x: Dictionary) -> bool:
		return FileAccess.file_exists(x.solution)

	var load_transformer := func(x: Dictionary) -> Dictionary:
		return {practice = load(x.practice), solution = load(x.solution)}

	var patterns := {scripts = "*.gd", scenes = "*.tscn"}
	for key in patterns:
		_list[key] = (
			Utils.fs_find(patterns[key], practice_base_path)
			.map(path_transformer)
			.filter(file_exists_predicate)
			.map(load_transformer)
		)
	Logger.log("[b]Requirements...[/b]")


static func check() -> bool:
	if _list.scripts.is_empty():
		Logger.log("Nothing to do...[color=orange]SKIP[/color]")
		return true
	return _check_constants() and _check_properties() and _check_methods() and _check_signals() and _check_nodes()


static func _check_methods() -> bool:
	Logger.log("Methods...")
	return _list.scripts.all(func(script: Dictionary) -> bool:
		var practice_method_list: Array[Dictionary] = script.practice.get_script_method_list()
		var solution_method_list: Array[Dictionary] = script.solution.get_script_method_list()
		practice_method_list.sort_custom(_name_sorter)
		solution_method_list.sort_custom(_name_sorter)

		var result := practice_method_list.map(_erase_arg_name_transformer) == solution_method_list.map(_erase_arg_name_transformer)
		_log_item(script, result)
		return result
	)


static func _check_properties() -> bool:
	Logger.log("Properties...")
	return _list.scripts.all(func(script: Dictionary) -> bool:
		var script_file_name: String = script.practice.resource_path.get_file()
		var predicate := func(prop: Dictionary) -> bool: return prop.name != script_file_name
		var practice_property_list: Array[Dictionary] = script.practice.get_script_property_list().filter(predicate)
		var solution_property_list: Array[Dictionary] = script.solution.get_script_property_list().filter(predicate)
		practice_property_list.sort_custom(_name_sorter)
		solution_property_list.sort_custom(_name_sorter)

		var result := practice_property_list == solution_property_list
		_log_item(script, result)
		return result
	)


static func _check_signals() -> bool:
	Logger.log("Signals...")
	return _list.scripts.all(func(script: Dictionary) -> bool:
		var practice_signal_list: Array[Dictionary] = script.practice.get_script_signal_list()
		var solution_signal_list: Array[Dictionary] = script.solution.get_script_signal_list()
		practice_signal_list.sort_custom(_name_sorter)
		solution_signal_list.sort_custom(_name_sorter)

		var result := practice_signal_list.map(_erase_arg_name_transformer) == solution_signal_list.map(_erase_arg_name_transformer)
		_log_item(script, result)
		return result
	)


static func _check_constants() -> bool:
	Logger.log("Constants...")
	return _list.scripts.all(func(script: Dictionary) -> bool:
		var practice_constant_map: Dictionary = script.practice.get_script_constant_map()
		var solution_constant_map: Dictionary = script.solution.get_script_constant_map()

		var result := practice_constant_map == solution_constant_map
		_log_item(script, result)
		return result
	)


static func _check_nodes() -> bool:
	Logger.log("Nodes...")
	return _list.scenes.all(func(scene: Dictionary) -> bool:
		var practice_scene_tree_proxy := _get_scene_tree_proxy(scene.practice.get_state())
		var solution_scene_tree_proxy := _get_scene_tree_proxy(scene.solution.get_state())

		var result := practice_scene_tree_proxy == solution_scene_tree_proxy
		_log_item(scene, result)
		return result
	)


static func _get_scene_tree_proxy(state: SceneState) -> Dictionary:
	var result := {}
	for idx in range(state.get_node_count()):
		var path_for_parent := state.get_node_path(idx, true)
		if not path_for_parent in result:
			result[path_for_parent] = []

		var type := state.get_node_type(idx)
		result[path_for_parent].append(type)

	for key in result:
		result[key].sort()
	return result


static func _log_item(item: Dictionary, is_valid: bool) -> void:
	var file_name: String = item.practice.resource_path.get_file()
	Logger.log("\t%s...[color=%s]%s[/color]" % (
		[file_name] + (["green", "PASS"] if is_valid else ["red", "FAIL"])
	))
