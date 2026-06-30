extends SceneTree
## Headless scene operator called via:
##   Godot --headless --path <project> --script scene_operator.gd -- <json-operation>
##
## Operations:
##   {"operation":"create_scene","path":"...","root_type":"...","root_name":"..."}
##   {"operation":"add_node","scene_path":"...","parent_path":"...","node_type":"...","node_name":"...","properties":{...}}
##   {"operation":"attach_script","scene_path":"...","node_path":"...","script_path":"..."}
##   {"operation":"connect_signal","scene_path":"...","signal":"...","from":"...","to":"...","method":"..."}
##   {"operation":"inspect","scene_path":"..."}


func _init() -> void:
	_initialize()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()

	if args.size() == 0:
		_output_error("No operation JSON provided")
		quit(1)
		return

	var raw_json: String = ""
	for i: int in range(args.size()):
		if i > 0:
			raw_json += " "
		raw_json += args[i]

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(raw_json)
	if parse_err != OK:
		_output_error("Invalid JSON input: %s" % json.get_error_message())
		quit(1)
		return

	var op: Variant = json.get_data()
	if typeof(op) != TYPE_DICTIONARY:
		_output_error("Operation must be a JSON object")
		quit(1)
		return

	var op_dict: Dictionary = op
	var operation: String = str(op_dict.get("operation", ""))

	match operation:
		"create_scene":
			_handle_create_scene(op_dict)
		"add_node":
			_handle_add_node(op_dict)
		"attach_script":
			_handle_attach_script(op_dict)
		"connect_signal":
			_handle_connect_signal(op_dict)
		"inspect":
			_handle_inspect(op_dict)
		_:
			_output_error("Unknown operation: %s" % operation)
			quit(1)


func _handle_create_scene(op: Dictionary) -> void:
	var relative_path: String = str(op.get("path", ""))
	var root_type: String = str(op.get("root_type", ""))
	var root_name: String = str(op.get("root_name", ""))

	if relative_path.is_empty() or root_type.is_empty() or root_name.is_empty():
		_output_error("Missing required fields: path, root_type, root_name")
		quit(1)
		return

	if not ClassDB.class_exists(root_type):
		_output_error("Unknown node type: %s" % root_type)
		quit(1)
		return

	if not ClassDB.is_parent_class(root_type, "Node"):
		_output_error("root_type must inherit from Node: %s" % root_type)
		quit(1)
		return

	var root_node: Node = ClassDB.instantiate(root_type)
	root_node.name = root_name

	var res_path: String = "res://%s" % relative_path
	if FileAccess.file_exists(res_path):
		var existing_scene: PackedScene = load(res_path)
		if existing_scene != null:
			var existing_root: Node = existing_scene.instantiate()
			if existing_root != null and existing_root.name == root_name and existing_root.get_class() == root_type:
				existing_root.free()
				root_node.free()
				_output_ok({
					"created": false,
					"already_exists": true,
					"path": relative_path,
					"root_type": root_type,
					"root_name": root_name
				})
				quit(0)
				return
			if existing_root != null:
				existing_root.free()

	var packed_scene: PackedScene = PackedScene.new()
	var pack_err: Error = packed_scene.pack(root_node)
	if pack_err != OK:
		root_node.free()
		_output_error("Failed to pack scene: error %d" % pack_err)
		quit(1)
		return

	_ensure_directory(res_path)

	var save_err: Error = ResourceSaver.save(packed_scene, res_path)
	if save_err != OK:
		root_node.free()
		_output_error("Failed to save scene: error %d" % save_err)
		quit(1)
		return

	root_node.free()
	_output_ok({
		"created": true,
		"path": relative_path,
		"root_type": root_type,
		"root_name": root_name
	})
	quit(0)


func _handle_add_node(op: Dictionary) -> void:
	var scene_path: String = str(op.get("scene_path", ""))
	var parent_path: String = str(op.get("parent_path", "."))
	var node_type: String = str(op.get("node_type", ""))
	var node_name: String = str(op.get("node_name", ""))
	var properties: Dictionary = op.get("properties", {})

	if scene_path.is_empty() or node_type.is_empty() or node_name.is_empty():
		_output_error("Missing required fields: scene_path, node_type, node_name")
		quit(1)
		return

	if not ClassDB.class_exists(node_type):
		_output_error("Unknown node type: %s" % node_type)
		quit(1)
		return

	var full_path: String = "res://%s" % scene_path
	if not FileAccess.file_exists(full_path):
		_output_error("Scene file not found: %s" % scene_path)
		quit(1)
		return

	var scene: PackedScene = load(full_path)
	var root: Node = scene.instantiate()

	var parent_node: Node = _find_node_by_path(root, parent_path)
	if parent_node == null:
		root.free()
		_output_error("Parent node not found: %s" % parent_path)
		quit(1)
		return

	var existing_child: Node = parent_node.get_node_or_null(node_name)
	if existing_child != null:
		if existing_child.get_class() == node_type:
			root.free()
			_output_ok({
				"modified": false,
				"already_exists": true,
				"scene_path": scene_path,
				"node_type": node_type,
				"node_name": node_name,
				"parent_path": parent_path
			})
			quit(0)
			return
		root.free()
		_output_error("Node name already exists with different type: %s" % node_name)
		quit(1)
		return

	var child_node: Node = ClassDB.instantiate(node_type)
	child_node.name = node_name

	for key: String in properties:
		child_node.set(key, properties[key])

	parent_node.add_child(child_node)
	child_node.owner = root

	var new_scene: PackedScene = PackedScene.new()
	var pack_err: Error = new_scene.pack(root)
	if pack_err != OK:
		root.free()
		_output_error("Failed to re-pack scene after adding node: error %d" % pack_err)
		quit(1)
		return

	var save_err: Error = ResourceSaver.save(new_scene, full_path)
	if save_err != OK:
		root.free()
		_output_error("Failed to save scene: error %d" % save_err)
		quit(1)
		return

	root.free()
	_output_ok({
		"modified": true,
		"scene_path": scene_path,
		"node_type": node_type,
		"node_name": node_name,
		"parent_path": parent_path
	})
	quit(0)


func _handle_attach_script(op: Dictionary) -> void:
	var scene_path: String = str(op.get("scene_path", ""))
	var node_path: String = str(op.get("node_path", ""))
	var script_path: String = str(op.get("script_path", ""))

	if scene_path.is_empty() or node_path.is_empty() or script_path.is_empty():
		_output_error("Missing required fields: scene_path, node_path, script_path")
		quit(1)
		return

	var full_scene_path: String = "res://%s" % scene_path
	if not FileAccess.file_exists(full_scene_path):
		_output_error("Scene file not found: %s" % scene_path)
		quit(1)
		return

	if not FileAccess.file_exists(script_path):
		_output_error("Script file not found: %s" % script_path)
		quit(1)
		return

	var script: Script = load(script_path)
	if script == null:
		_output_error("Failed to load script: %s" % script_path)
		quit(1)
		return

	var scene: PackedScene = load(full_scene_path)
	var root: Node = scene.instantiate()

	var target_node: Node = _find_node_by_path(root, node_path)
	if target_node == null:
		root.free()
		_output_error("Node not found: %s" % node_path)
		quit(1)
		return

	var current_script: Script = target_node.get_script()
	if current_script != null:
		if current_script.resource_path == script_path:
			root.free()
			_output_ok({
				"modified": false,
				"already_attached": true,
				"scene_path": scene_path,
				"node_path": node_path,
				"script_path": script_path
			})
			quit(0)
			return
		root.free()
		_output_error("Node already has a different script: %s" % current_script.resource_path)
		quit(1)
		return

	target_node.set_script(script)

	var new_scene: PackedScene = PackedScene.new()
	var pack_err: Error = new_scene.pack(root)
	if pack_err != OK:
		root.free()
		_output_error("Failed to re-pack scene after attaching script: error %d" % pack_err)
		quit(1)
		return

	var save_err: Error = ResourceSaver.save(new_scene, full_scene_path)
	if save_err != OK:
		root.free()
		_output_error("Failed to save scene: error %d" % save_err)
		quit(1)
		return

	root.free()
	_output_ok({
		"modified": true,
		"scene_path": scene_path,
		"node_path": node_path,
		"script_path": script_path
	})
	quit(0)


func _handle_connect_signal(op: Dictionary) -> void:
	var scene_path: String = str(op.get("scene_path", ""))
	var signal_name: String = str(op.get("signal", ""))
	var from_path: String = str(op.get("from", ""))
	var to_path: String = str(op.get("to", "."))
	var method_name: String = str(op.get("method", ""))

	if scene_path.is_empty() or signal_name.is_empty() or from_path.is_empty() or method_name.is_empty():
		_output_error("Missing required fields: scene_path, signal, from, method")
		quit(1)
		return

	var full_scene_path: String = "res://%s" % scene_path
	if not FileAccess.file_exists(full_scene_path):
		_output_error("Scene file not found: %s" % scene_path)
		quit(1)
		return

	var scene: PackedScene = load(full_scene_path)
	var root: Node = scene.instantiate()

	var from_node: Node = _find_node_by_path(root, from_path)
	if from_node == null:
		root.free()
		_output_error("Source node not found: %s" % from_path)
		quit(1)
		return

	var to_node: Node = _find_node_by_path(root, to_path)
	if to_node == null:
		root.free()
		_output_error("Target node not found: %s" % to_path)
		quit(1)
		return

	if not from_node.has_signal(signal_name):
		root.free()
		_output_error("Signal '%s' not found on node '%s'" % [signal_name, from_path])
		quit(1)
		return

	if not to_node.has_method(method_name):
		root.free()
		_output_error("Method '%s' not found on node '%s'" % [method_name, to_path])
		quit(1)
		return

	var callable: Callable = Callable(to_node, method_name)
	if from_node.is_connected(signal_name, callable):
		root.free()
		_output_ok({
			"modified": false,
			"already_connected": true,
			"scene_path": scene_path,
			"signal": signal_name,
			"from": from_path,
			"to": to_path,
			"method": method_name
		})
		quit(0)
		return

	var err: Error = from_node.connect(signal_name, callable)
	if err != OK:
		root.free()
		_output_error("Failed to connect signal: error %d" % err)
		quit(1)
		return

	var new_scene: PackedScene = PackedScene.new()
	var pack_err: Error = new_scene.pack(root)
	if pack_err != OK:
		root.free()
		_output_error("Failed to re-pack scene after connecting signal: error %d" % pack_err)
		quit(1)
		return

	var save_err: Error = ResourceSaver.save(new_scene, full_scene_path)
	if save_err != OK:
		root.free()
		_output_error("Failed to save scene: error %d" % save_err)
		quit(1)
		return

	root.free()
	_output_ok({
		"modified": true,
		"scene_path": scene_path,
		"signal": signal_name,
		"from": from_path,
		"to": to_path,
		"method": method_name
	})
	quit(0)


func _handle_inspect(op: Dictionary) -> void:
	var scene_path: String = str(op.get("scene_path", ""))

	if scene_path.is_empty():
		_output_error("Missing required field: scene_path")
		quit(1)
		return

	var full_scene_path: String = "res://%s" % scene_path
	if not FileAccess.file_exists(full_scene_path):
		_output_error("Scene file not found: %s" % scene_path)
		quit(1)
		return

	var scene: PackedScene = load(full_scene_path)
	var root: Node = scene.instantiate()

	var nodes: Array[Dictionary] = []
	_collect_nodes(root, "", nodes)

	var scene_state: SceneState = scene.get_state()
	var connections: Array[Dictionary] = []
	for i: int in range(scene_state.get_connection_count()):
		connections.append({
			"signal": scene_state.get_connection_signal(i),
			"from": scene_state.get_connection_source(i),
			"to": scene_state.get_connection_target(i),
			"method": scene_state.get_connection_method(i),
			"flags": scene_state.get_connection_flags(i),
			"binds": var_to_str(scene_state.get_connection_binds(i))
		})

	_output_ok({
		"scene_path": scene_path,
		"nodes": nodes,
		"connections": connections
	})
	quit(0)


func _find_node_by_path(scene_root: Node, path_str: String) -> Node:
	if path_str == "." or path_str.is_empty():
		return scene_root

	var cleaned: String = path_str.trim_prefix("./")
	var segments: PackedStringArray = cleaned.split("/", false)

	var current: Node = scene_root
	for segment: String in segments:
		var found: Node = current.get_node_or_null(segment)
		if found == null:
			return null
		current = found

	return current


func _collect_nodes(node: Node, parent_path: String, out_nodes: Array[Dictionary]) -> void:
	var node_path: String = node.name
	if not parent_path.is_empty():
		node_path = "%s/%s" % [parent_path, node.name]

	var info: Dictionary = {
		"name": node.name,
		"type": node.get_class(),
		"path": node_path,
		"parent": parent_path if not parent_path.is_empty() else "."
	}

	var script: Script = node.get_script()
	if script != null:
		info["script"] = script.resource_path

	out_nodes.append(info)

	for child: Node in node.get_children():
		_collect_nodes(child, node_path, out_nodes)


func _ensure_directory(res_path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(res_path)
	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err: Error = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			_output_error("Failed to create directory: %s (error %d)" % [dir_path, err])
			quit(1)


func _output_ok(data: Dictionary) -> void:
	data["ok"] = true
	print(JSON.stringify(data))


func _output_error(message: String) -> void:
	print(JSON.stringify({"ok": false, "error": message}))
