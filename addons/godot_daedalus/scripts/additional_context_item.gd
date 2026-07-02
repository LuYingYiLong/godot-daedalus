@tool
extends Button

signal pin_toggled(context_id: String, pinned: bool)
signal remove_requested(context_id: String)
signal activated(context_id: String)

const PIN_ICON: Texture2D = preload("uid://djumrslufw1q8")
const UNPIN_ICON: Texture2D = preload("uid://xd7ejyjkvr20")
const NODE_ICON: Texture2D = preload("uid://cg37rrr8iihlh")

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
	context_icon.texture = _get_kind_icon(str(context_data.get("kind", "")))
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


func _get_kind_icon(_context_kind: String) -> Texture2D:
	return NODE_ICON


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

	if interactive:
		lines.append("点击固定/取消固定。右键移除。")

	return "\n".join(lines)
