@tool
extends ConfirmationDialog

signal server_config_submitted(config: Dictionary)

@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var description_text_edit: TextEdit = %DescriptionTextEdit
@onready var type_option_button: OptionButton = %TypeOptionButton
@onready var stdio_container: GridContainer = %StdioContainer
@onready var common_line_edit: LineEdit = %CommonLineEdit
@onready var args_text_edit: TextEdit = %ArgsTextEdit
@onready var env_text_edit: TextEdit = %EnvTextEdit
@onready var http_container: GridContainer = %HttpContainer
@onready var url_line_edit: LineEdit = %URLLineEdit
@onready var http_header_text_edit: TextEdit = %HttpHeaderTextEdit
@onready var error_label: Label = %ErrorLabel

const TRANSPORT_STDIO: String = "stdio"
const TRANSPORT_HTTP: String = "http"
const TYPE_INDEX_STDIO: int = 0
const TYPE_INDEX_HTTP: int = 1

var submit_emitted: bool


func _ready() -> void:
	var ok_button: Button = get_ok_button()
	if ok_button != null and not ok_button.pressed.is_connected(_on_ok_button_pressed):
		ok_button.pressed.connect(_on_ok_button_pressed)

	_update_transport_fields()
	_validate_form()


func _on_type_option_button_item_selected(_index: int) -> void:
	_update_transport_fields()
	_validate_form()


func _on_line_edit_text_changed(_new_text: String) -> void:
	_validate_form()


func _on_text_edit_text_changed() -> void:
	_validate_form()


func _on_confirmed() -> void:
	_submit_server_config()


func _on_ok_button_pressed() -> void:
	_submit_server_config()


func _submit_server_config() -> void:
	if submit_emitted:
		return

	var validation_result: Dictionary = _validate_form()
	if not bool(validation_result.get("ok", false)):
		return

	submit_emitted = true
	server_config_submitted.emit(_create_config())


func _update_transport_fields() -> void:
	var is_http: bool = type_option_button.selected == TYPE_INDEX_HTTP
	stdio_container.visible = not is_http
	http_container.visible = is_http


func _validate_form() -> Dictionary:
	var validation_result: Dictionary = _get_validation_result()
	var ok_button: Button = get_ok_button()
	if ok_button != null:
		ok_button.disabled = not bool(validation_result.get("ok", false))

	var error_text: String = str(validation_result.get("error", ""))
	error_label.visible = not error_text.is_empty()
	error_label.text = error_text
	return validation_result


func _get_validation_result() -> Dictionary:
	var server_name: String = name_line_edit.text.strip_edges()
	if server_name.is_empty():
		return { "ok": false, "error": "Name is required." }

	if type_option_button.selected == TYPE_INDEX_HTTP:
		var url_text: String = url_line_edit.text.strip_edges()
		if url_text.is_empty():
			return { "ok": false, "error": "HTTP URL is required." }
		if not (url_text.begins_with("http://") or url_text.begins_with("https://")):
			return { "ok": false, "error": "HTTP URL must start with http:// or https://." }

		var header_result: Dictionary = _parse_key_value_lines(http_header_text_edit.text, ":", "HTTP header")
		if not bool(header_result.get("ok", false)):
			return header_result

		return { "ok": true, "error": "" }

	var command_text: String = common_line_edit.text.strip_edges()
	if command_text.is_empty():
		return { "ok": false, "error": "Command is required." }

	var env_result: Dictionary = _parse_key_value_lines(env_text_edit.text, "=", "Env")
	if not bool(env_result.get("ok", false)):
		return env_result

	return { "ok": true, "error": "" }


func _create_config() -> Dictionary:
	var config: Dictionary[String, Variant] = {
		"name": name_line_edit.text.strip_edges(),
		"description": description_text_edit.text.strip_edges(),
		"enabled": true
	}

	if type_option_button.selected == TYPE_INDEX_HTTP:
		config["transport"] = TRANSPORT_HTTP
		config["url"] = url_line_edit.text.strip_edges()
		var headers: Dictionary = _parse_key_value_lines(http_header_text_edit.text, ":", "HTTP header").get("values", {})
		if not headers.is_empty():
			config["headers"] = headers
		return config

	config["transport"] = TRANSPORT_STDIO
	var command_text: String = common_line_edit.text.strip_edges()
	config["command"] = command_text
	var args: Array[String] = _normalize_stdio_args(command_text, _parse_args(args_text_edit.text))
	if not args.is_empty():
		config["args"] = args
	var env: Dictionary = _parse_key_value_lines(env_text_edit.text, "=", "Env").get("values", {})
	if not env.is_empty():
		config["env"] = env
	return config


func _parse_args(text: String) -> Array[String]:
	var args: Array[String] = []
	for raw_line: String in text.split("\n", false):
		var line_text: String = raw_line.strip_edges()
		if line_text.is_empty():
			continue

		args.append(line_text)

	return args


func _normalize_stdio_args(command_text: String, args: Array[String]) -> Array[String]:
	var normalized_args: Array[String] = []
	for arg_text: String in args:
		normalized_args.append(arg_text)

	if not _is_cmd_command(command_text) or normalized_args.is_empty():
		return normalized_args

	var first_arg: String = normalized_args[0].to_lower()
	if first_arg == "/c" or first_arg == "/k":
		return normalized_args

	normalized_args.insert(0, "/c")
	return normalized_args


func _is_cmd_command(command_text: String) -> bool:
	var normalized_command: String = command_text.replace("\\", "/").to_lower()
	var file_name: String = normalized_command.get_file()
	return file_name == "cmd" or file_name == "cmd.exe"


func _parse_key_value_lines(text: String, separator: String, label_text: String) -> Dictionary:
	var values: Dictionary[String, String] = {}
	var line_number: int = 0
	for raw_line: String in text.split("\n", false):
		line_number += 1
		var line_text: String = raw_line.strip_edges()
		if line_text.is_empty():
			continue

		var separator_index: int = line_text.find(separator)
		if separator_index <= 0:
			return {
				"ok": false,
				"error": "%s line %d must use %s." % [label_text, line_number, separator]
			}

		var key_text: String = line_text.substr(0, separator_index).strip_edges()
		var value_text: String = line_text.substr(separator_index + separator.length()).strip_edges()
		if key_text.is_empty():
			return {
				"ok": false,
				"error": "%s line %d has an empty name." % [label_text, line_number]
			}

		values[key_text] = value_text

	return {
		"ok": true,
		"error": "",
		"values": values
	}
