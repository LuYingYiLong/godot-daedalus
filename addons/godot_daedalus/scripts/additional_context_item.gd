@tool
extends Button

signal pin_toggled(context_id: String, pinned: bool)
signal remove_requested(context_id: String)
signal activated(context_id: String)

const PIN_ICON: Texture2D = preload("uid://djumrslufw1q8")
const UNPIN_ICON: Texture2D = preload("uid://xd7ejyjkvr20")
const NODE_ICON: Texture2D = preload("uid://cg37rrr8iihlh")
const FILE_ICON: Texture2D = preload("uid://bolghxe3kbp2r")
const SCRIPT_ICON: Texture2D = preload("uid://dqw3f23j6ipt8")
const SCRIPT_EXTENSIONS: Array[String] = ["gd", "cs", "shader", "gdshader", "glsl", "hlsl"]

@onready var context_icon: TextureRect = %Icon
@onready var title_label: Label = %Label

var context_id: String
var context_data: Dictionary
var pinned: bool
var interactive: bool = true


func setup(context: Dictionary) -> void:
	context_data = context.duplicate(true)
	context_id = str(context_data.get("id", ""))
	pinned = bool(context_data.get("pinned", false))

	title_label.text = str(context_data.get("title", "Context"))
	context_icon.texture = _get_context_icon()
	icon = PIN_ICON if pinned else UNPIN_ICON
	tooltip_text = _create_tooltip_text()


func set_interactive(enabled: bool) -> void:
	interactive = enabled
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW


func _pressed() -> void:
	if not interactive:
		activated.emit(context_id)
		return

	pinned = not pinned
	context_data["pinned"] = pinned
	icon = PIN_ICON if pinned else UNPIN_ICON
	tooltip_text = _create_tooltip_text()
	pin_toggled.emit(context_id, pinned)


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		remove_requested.emit(context_id)
		accept_event()


func _get_context_icon() -> Texture2D:
	var context_kind: String = str(context_data.get("kind", ""))
	if context_kind == "script" or context_kind == "script_selection":
		return SCRIPT_ICON
	if context_kind == "file":
		return SCRIPT_ICON if _is_script_resource_path(str(context_data.get("resourcePath", ""))) else FILE_ICON
	if context_kind == "filesystem_selection":
		return SCRIPT_ICON if _is_filesystem_selection_only_scripts() else FILE_ICON
	if context_kind == "folder":
		return FILE_ICON

	return NODE_ICON


func _is_filesystem_selection_only_scripts() -> bool:
	var data: Dictionary = _get_context_data()
	var selected_paths_value: Variant = data.get("selectedPaths", [])
	if typeof(selected_paths_value) != TYPE_ARRAY:
		return false

	var selected_paths: Array = selected_paths_value as Array
	var has_file: bool
	for selected_path_value: Variant in selected_paths:
		if typeof(selected_path_value) != TYPE_DICTIONARY:
			continue
		var selected_path: Dictionary = selected_path_value as Dictionary
		if str(selected_path.get("kind", "")) != "file":
			return false
		has_file = true
		if not _is_script_resource_path(str(selected_path.get("resourcePath", ""))):
			return false

	return has_file


func _is_script_resource_path(resource_path: String) -> bool:
	var extension: String = resource_path.get_extension().to_lower()
	return SCRIPT_EXTENSIONS.has(extension)


func _create_tooltip_text() -> String:
	var lines: Array[String] = []
	lines.append(str(context_data.get("title", "Context")))

	var subtitle: String = str(context_data.get("subtitle", "")).strip_edges()
	if not subtitle.is_empty():
		lines.append(subtitle)

	var resource_path: String = str(context_data.get("resourcePath", "")).strip_edges()
	if not resource_path.is_empty():
		lines.append(resource_path)

	var node_path: String = str(context_data.get("nodePath", "")).strip_edges()
	if not node_path.is_empty():
		lines.append(node_path)

	var context_kind: String = str(context_data.get("kind", ""))
	if context_kind == "script_selection":
		_append_script_selection_tooltip_lines(lines)
	elif context_kind == "filesystem_selection":
		_append_filesystem_selection_tooltip_lines(lines)

	if interactive:
		lines.append("Click to pin/unpin. Right-click to remove.")

	return "\n".join(lines)


func _append_script_selection_tooltip_lines(lines: Array[String]) -> void:
	var data: Dictionary = _get_context_data()
	var line_start: int = int(data.get("lineStart", 0))
	var column_start: int = int(data.get("columnStart", 0))
	var line_end: int = int(data.get("lineEnd", 0))
	var column_end: int = int(data.get("columnEnd", 0))
	if line_start > 0 and column_start > 0 and line_end > 0 and column_end > 0:
		lines.append("Range: %d:%d-%d:%d" % [line_start, column_start, line_end, column_end])

	var has_selection: bool = bool(data.get("hasSelection", false))
	if has_selection:
		lines.append("Selection preview included")
	else:
		lines.append("Current line preview included")


func _append_filesystem_selection_tooltip_lines(lines: Array[String]) -> void:
	var data: Dictionary = _get_context_data()
	var selected_paths_value: Variant = data.get("selectedPaths", [])
	if typeof(selected_paths_value) != TYPE_ARRAY:
		return

	var selected_paths: Array = selected_paths_value as Array
	for index: int in range(mini(selected_paths.size(), 5)):
		var selected_path_value: Variant = selected_paths[index]
		if typeof(selected_path_value) != TYPE_DICTIONARY:
			continue
		var selected_path: Dictionary = selected_path_value as Dictionary
		lines.append("%s: %s" % [str(selected_path.get("kind", "file")), str(selected_path.get("resourcePath", ""))])
	if selected_paths.size() > 5:
		lines.append("... %d more" % (selected_paths.size() - 5))


func _get_context_data() -> Dictionary:
	var data_value: Variant = context_data.get("data", {})
	if typeof(data_value) != TYPE_DICTIONARY:
		return {}
	return data_value as Dictionary
