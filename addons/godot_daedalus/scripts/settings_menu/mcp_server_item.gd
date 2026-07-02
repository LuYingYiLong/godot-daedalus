@tool
extends HBoxContainer

signal remove_requested(server_id: String)
signal enabled_changed(server_id: String, enabled: bool)

@onready var name_label: Label = %NameLabel
@onready var remove_button: Button = %RemoveButton
@onready var edit_button: Button = %EditButton
@onready var check_button: CheckButton = %CheckButton

var server_id: String
var suppress_enabled_signal: bool


func _ready() -> void:
	edit_button.disabled = true
	edit_button.tooltip_text = "Editing custom MCP servers is not available in this version."


func setup(metadata: Dictionary) -> void:
	server_id = str(metadata.get("id", ""))
	var server_name: String = str(metadata.get("name", "Custom MCP"))
	var transport: String = str(metadata.get("transport", "")).to_upper()
	var status: String = str(metadata.get("status", "disconnected"))
	var tool_count: int = int(metadata.get("toolCount", 0))
	var enabled: bool = bool(metadata.get("enabled", false))
	var is_pending: bool = bool(metadata.get("pending", false))

	name_label.text = server_name
	name_label.tooltip_text = _format_tooltip(metadata)
	remove_button.tooltip_text = "Remove this custom MCP server"
	check_button.tooltip_text = "Enable or disable this custom MCP server"
	remove_button.disabled = is_pending
	check_button.disabled = is_pending
	suppress_enabled_signal = true
	check_button.button_pressed = enabled
	suppress_enabled_signal = false


func _on_remove_button_pressed() -> void:
	if server_id.is_empty():
		return

	remove_requested.emit(server_id)


func _on_check_button_toggled(button_pressed: bool) -> void:
	if suppress_enabled_signal or server_id.is_empty():
		return

	enabled_changed.emit(server_id, button_pressed)


func _format_status(status: String) -> String:
	match status:
		"connected":
			return "Connected"
		"connecting":
			return "Connecting"
		"error":
			return "Error"
		"disabled":
			return "Disabled"
		_:
			return "Disconnected"


func _format_tooltip(metadata: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append(str(metadata.get("description", "")).strip_edges())
	lines.append("Status: %s" % _format_status(str(metadata.get("status", "disconnected"))))
	lines.append("Transport: %s" % str(metadata.get("transport", "")).to_upper())

	var command: String = str(metadata.get("command", "")).strip_edges()
	if not command.is_empty():
		lines.append("Command: %s" % command)

	var url: String = str(metadata.get("url", "")).strip_edges()
	if not url.is_empty():
		lines.append("URL: %s" % url)

	var env_names: Array = metadata.get("envNames", []) as Array
	if not env_names.is_empty():
		lines.append("Env: %s" % ", ".join(_string_array_from_array(env_names)))

	var header_names: Array = metadata.get("headerNames", []) as Array
	if not header_names.is_empty():
		lines.append("Headers: %s" % ", ".join(_string_array_from_array(header_names)))

	var error_text: String = str(metadata.get("error", "")).strip_edges()
	if not error_text.is_empty():
		lines.append("Error: %s" % error_text)

	var filtered_lines: PackedStringArray = []
	for line_text: String in lines:
		if line_text.strip_edges().is_empty():
			continue

		filtered_lines.append(line_text)

	return "\n".join(filtered_lines)


func _string_array_from_array(values: Array) -> PackedStringArray:
	var result: PackedStringArray = []
	for value: Variant in values:
		result.append(str(value))

	return result
