@tool
extends VBoxContainer

const BACKEND_URL: String = "ws://localhost:8080"
const USER_MESSAGE_ITEM_SCENE: PackedScene = preload("uid://c0qgg77075lmq")
const ASSISTANT_MARKDOWN_ITEM_SCENE: PackedScene = preload("uid://c3s4jlxtm21ci")
const TOOL_CALL_ITEM_SCENE: PackedScene = preload("uid://c2a5o7qi58fus")
const SESSION_ITEM_SCENE: PackedScene = preload("uid://bic1etsxo1epd")
const CONTEXT_ICON_DIR: String = "res://addons/godot_daedalus/assets/icons"
const CONNECTED_ICON: Texture2D = preload("uid://1eh7wxaewfje")
const CONNECT_FAILED_ICON: Texture2D = preload("uid://chihcwe7t0f2g")
const DISCONNECTED_ICON: Texture2D = preload("uid://cq15q550jtb21")
const STAUTS_WARNING: Texture2D = preload("uid://gytxgaev43it")
const SETTINGS_MENU_UID: String = "uid://dp3tsanvojx2k"
const MAX_CONNECT_ATTEMPTS: int = 5
const CONNECT_RETRY_SECONDS: float = 0.8

const MODEL_IDS: Array[String] = [
	"deepseek-v4-flash",
	"deepseek-v4-pro"
]

const MODEL_NAMES: Array[String] = [
	"V4 Flash",
	"V4 Pro"
]

const APPROVAL_MODE_NAMES: Array[String] = [
	"Manual",
	"Auto Safe",
	"Read Only"
]

@onready var workspace_filter_button: OptionButton = %WorkspaceFilterButton
@onready var search_session_line_edit: LineEdit = %SearchSessionLineEdit
@onready var session_option_button: OptionButton = %SessionOptionButton
@onready var create_new_session_button: Button = %CreateNewSessionButton
@onready var context_length_button: Button = %ContextLengthButton
@onready var session_list_viewer: VBoxContainer = %SessionListViewer
@onready var session_list: VBoxContainer = %SessionList
@onready var background_context_viewer: VBoxContainer = %BackgroundContextViewer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var background_context_container: VBoxContainer = %BackgroundContextContainer
@onready var approval_dialog: PanelContainer = %ApprovalDialog
@onready var send_button: Button = %SendButton
@onready var stop_button: Button = %StopButton
@onready var status_button: Button = %StatusButton
@onready var text_edit: TextEdit = $TextEdit
@onready var model_button: OptionButton = %ModelButton
@onready var effort_button: OptionButton = %EffortButton
@onready var approval_mode_button: OptionButton = %ApprovalModeButton
@onready var approval_title_label: MarkdownLabel = %ApprovalTitleLabel
@onready var approval_description_label: MarkdownLabel = %ApprovalDescriptionLabel
@onready var boot_splash: CenterContainer = %BootSplash
@onready var todo_list: FoldableContainer = %TodoList
@onready var todo_container: VBoxContainer = %TodoContainer

var socket: WebSocketPeer = WebSocketPeer.new()
var socket_ready: bool
var connection_attempts: int
var is_connecting: bool
var request_id: int
var active_stream_id: String
var active_session_id: String
var pending_chat_text: String
var pending_approval_id: String
var sessions_by_id: Dictionary[String, Dictionary]
var session_ids_in_order: Array[String]
var workspaces_by_id: Dictionary[String, Dictionary]
var selected_workspace_filter: String
var session_search_text: String
var tool_items_by_call_id: Dictionary[String, Node]
var active_assistant_item: Node
var active_thinking_item: Node
var active_assistant_text: String
var last_todo_signature: String
var provider_config_status: Dictionary


func _ready() -> void:
	session_list_viewer.hide()
	background_context_viewer.hide()
	text_edit.hide()
	boot_splash.show()
	_setup_options()
	_clear_template_items()
	_update_send_state()
	_set_context_length_icon(0.0, true)
	_start_backend_connection_attempts()


func _process(_delta: float) -> void:
	socket.poll()
	var state: WebSocketPeer.State = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not socket_ready:
			socket_ready = true
			_on_socket_opened()
		_receive_messages()
	elif state == WebSocketPeer.STATE_CLOSED and socket_ready:
		socket_ready = false
		status_button.icon = DISCONNECTED_ICON
		status_button.tooltip_text = "Disconnected"
		_update_send_state()
	elif state == WebSocketPeer.STATE_CLOSED and is_connecting:
		_retry_backend_connection()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if not text_edit.has_focus():
		return

	if event.keycode == KEY_ENTER:
		if event.shift_pressed:
			return
		_on_send_button_pressed()
		accept_event()


func _setup_options() -> void:
	workspace_filter_button.clear()
	workspace_filter_button.add_item("All", 0)
	workspace_filter_button.set_item_metadata(0, "")

	model_button.clear()
	for index: int in range(MODEL_IDS.size()):
		model_button.add_item(MODEL_NAMES[index], index)
	model_button.select(0)

	effort_button.clear()
	effort_button.add_item("Normal", 0)

	approval_mode_button.clear()
	for index: int in range(APPROVAL_MODE_NAMES.size()):
		approval_mode_button.add_item(APPROVAL_MODE_NAMES[index], index)


func _clear_template_items() -> void:
	for child: Node in background_context_container.get_children():
		child.queue_free()


func _start_backend_connection_attempts() -> void:
	connection_attempts = 0
	is_connecting = true
	socket_ready = false
	boot_splash.show()
	boot_splash.call("show_connecting")
	session_list_viewer.hide()
	background_context_viewer.hide()
	text_edit.hide()
	_connect_to_backend()


func _connect_to_backend() -> void:
	connection_attempts += 1
	socket = WebSocketPeer.new()
	var connect_error: Error = socket.connect_to_url(BACKEND_URL)
	if connect_error != OK:
		status_button.icon = CONNECT_FAILED_ICON
		status_button.tooltip_text = "Connect failed: %d" % connect_error
		_retry_backend_connection()
		return
	
	status_button.icon = DISCONNECTED_ICON
	status_button.tooltip_text = "Connecting... (%d/%d)" % [connection_attempts, MAX_CONNECT_ATTEMPTS]


func _retry_backend_connection() -> void:
	if connection_attempts >= MAX_CONNECT_ATTEMPTS:
		is_connecting = false
		status_button.icon = CONNECT_FAILED_ICON
		status_button.tooltip_text = "Connect failed"
		boot_splash.call("show_error", "Cannot connect to Daedalus backend", "请确认后端已启动：npm run dev\n地址：%s" % BACKEND_URL)
		return

	is_connecting = false
	await get_tree().create_timer(CONNECT_RETRY_SECONDS).timeout
	if socket_ready:
		return

	is_connecting = true
	_connect_to_backend()


func _on_socket_opened() -> void:
	is_connecting = false
	status_button.icon = CONNECTED_ICON
	status_button.tooltip_text = "Connected"
	boot_splash.hide()
	_show_session_list_viewer()
	text_edit.show()
	_send_environment_config()
	_load_provider_config()


func _on_boot_splash_reconnect_requested() -> void:
	_start_backend_connection_attempts()


func _load_provider_config() -> void:
	_send_request("provider.config.get", {}, "provider-config-get")


func _send_environment_config() -> void:
	_send_request(
		"environment.configure",
		{
			"godotExecutablePath": OS.get_executable_path(),
			"godotProjectPath": ProjectSettings.globalize_path("res://")
		},
		"environment-configure"
	)


func _get_selected_model_id() -> String:
	var selected_index: int = model_button.selected
	if selected_index < 0 or selected_index >= MODEL_IDS.size():
		return MODEL_IDS[0]

	return MODEL_IDS[selected_index]


func _on_back_button_pressed() -> void:
	if background_context_viewer.visible:
		_show_session_list_viewer()
	else:
		_show_background_context_viewer()


func _show_session_list_viewer() -> void:
	session_list_viewer.show()
	background_context_viewer.hide()
	workspace_filter_button.show()
	search_session_line_edit.show()
	session_option_button.hide()
	context_length_button.hide()


func _show_background_context_viewer() -> void:
	session_list_viewer.hide()
	background_context_viewer.show()
	workspace_filter_button.hide()
	search_session_line_edit.hide()
	session_option_button.show()
	context_length_button.show()


func _on_create_new_session_button_pressed() -> void:
	_create_session("New session " + Time.get_datetime_string_from_system(false, true))


func _on_session_option_button_item_selected(index: int) -> void:
	if index < 0 or index >= session_option_button.get_item_count():
		return

	var session_id: String = str(session_option_button.get_item_metadata(index))
	if not session_id.is_empty():
		_open_session(session_id)


func _on_send_button_pressed() -> void:
	var message_text: String = text_edit.text.strip_edges()
	if message_text.is_empty():
		return

	if active_session_id.is_empty():
		pending_chat_text = message_text
		_create_session(_make_session_title(message_text))
		return

	_send_chat_text(message_text)


func _on_stop_button_pressed() -> void:
	active_stream_id = ""
	active_assistant_item = null
	active_assistant_text = ""
	_set_streaming_state(false)


func _on_approve_button_pressed() -> void:
	if pending_approval_id.is_empty():
		return

	active_stream_id = _send_request("approval.approve", { "approvalId": pending_approval_id }, "approval-approve")
	active_assistant_item = null
	active_assistant_text = ""
	_set_streaming_state(true)
	_scroll_to_bottom()
	approval_dialog.visible = false


func _on_reject_button_pressed() -> void:
	if pending_approval_id.is_empty():
		return

	_send_request("approval.reject", { "approvalId": pending_approval_id }, "approval-reject")
	approval_dialog.visible = false


func _on_skip_approval_button_pressed() -> void:
	approval_dialog.visible = false


func _create_session(title_text: String) -> void:
	if not _is_socket_open():
		return

	var params: Dictionary = { "title": title_text }
	if not selected_workspace_filter.is_empty():
		params["workspaceId"] = selected_workspace_filter

	_send_request("session.create", params, "session-create")


func _open_session(session_id: String) -> void:
	if not _is_socket_open():
		return

	_send_request("session.open", { "sessionId": session_id }, "session-open")


func _send_chat_text(message_text: String) -> void:
	if not _is_socket_open():
		return

	_show_background_context_viewer()
	var user_item: Node = USER_MESSAGE_ITEM_SCENE.instantiate()
	background_context_container.add_child(user_item)
	user_item.call("setup", message_text)

	active_assistant_item = null
	active_assistant_text = ""
	_clear_todo_items()

	request_id += 1
	active_stream_id = "daedalus-chat-%d" % request_id
	var payload: Dictionary[String, Variant] = {
		"type": "request",
		"id": active_stream_id,
		"method": "ai.chat",
		"params": {
			"message": message_text,
			"promptId": "godot.assistant",
			"options": {
				"stream": true,
				"toolBudget": "project_edit"
			}
		}
	}

	var send_error: Error = socket.send_text(JSON.stringify(payload))
	if send_error != OK:
		active_stream_id = ""
		active_assistant_item = null
		_set_streaming_state(false)
		return

	_scroll_to_bottom()
	text_edit.clear()
	_set_streaming_state(true)


func _make_session_title(message_text: String) -> String:
	var one_line: String = message_text.replace("\n", " ").strip_edges()
	if one_line.length() > 24:
		return one_line.substr(0, 24)

	if one_line.is_empty():
		return "新会话"

	return one_line


func _send_request(method: String, params: Dictionary[String, Variant], id_prefix: String) -> String:
	if not _is_socket_open():
		return ""

	request_id += 1
	var next_request_id: String = "%s-%d" % [id_prefix, request_id]
	var payload: Dictionary[String, Variant] = {
		"type": "request",
		"id": next_request_id,
		"method": method,
		"params": params
	}
	socket.send_text(JSON.stringify(payload))
	return next_request_id


func _is_socket_open() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN


func _receive_messages() -> void:
	while socket.get_available_packet_count() > 0:
		var packet: PackedByteArray = socket.get_packet()
		if not socket.was_string_packet():
			continue

		var json: JSON = JSON.new()
		var parse_error: Error = json.parse(packet.get_string_from_utf8())
		if parse_error != OK:
			continue

		var data: Variant = json.data
		if typeof(data) == TYPE_DICTIONARY:
			_handle_message(data as Dictionary)


func _handle_message(message: Dictionary) -> void:
	var message_type: String = str(message.get("type", ""))
	if message_type == "response":
		_handle_response(message)
	elif message_type == "event":
		_handle_event(message)


func _handle_response(message: Dictionary) -> void:
	var ok: bool = bool(message.get("ok", false))
	if not ok:
		if str(message.get("id", "")) == active_stream_id:
			_show_response_error(message)
			active_stream_id = ""
			active_assistant_item = null
			active_assistant_text = ""
			_set_streaming_state(false)
		return

	var result: Variant = message.get("result", {})
	if typeof(result) != TYPE_DICTIONARY:
		return

	var result_dictionary: Dictionary = result as Dictionary
	if result_dictionary.has("workspaces"):
		_update_workspace_list(result_dictionary)
	elif result_dictionary.has("sessions"):
		_update_session_list(result_dictionary)
	elif result_dictionary.has("keyStorage") and result_dictionary.has("configured"):
		_apply_provider_config_status(result_dictionary)
	elif result_dictionary.has("id") and result_dictionary.has("title") and result_dictionary.has("createdAt"):
		_apply_session_metadata(result_dictionary)
		_clear_chat_items()
		_send_request("workspace.list", {}, "workspace-list")
		_send_request("session.list", {}, "session-list")

		if not pending_chat_text.is_empty():
			var next_message: String = pending_chat_text
			pending_chat_text = ""
			_send_chat_text(next_message)
	elif bool(result_dictionary.get("opened", false)):
		var metadata: Variant = result_dictionary.get("metadata", {})
		if typeof(metadata) == TYPE_DICTIONARY:
			_apply_session_metadata(metadata as Dictionary)
		_clear_chat_items()
		_show_background_context_viewer()
		_render_session_timeline(result_dictionary.get("messages", []), result_dictionary.get("events", []))
		_send_request("workspace.list", {}, "workspace-list")
		_send_request("session.info", {}, "session-info")
	elif bool(result_dictionary.get("configured", false)) and result_dictionary.has("provider"):
		_update_send_state()
	elif bool(result_dictionary.get("configured", false)) and result_dictionary.has("godotProjectPath"):
		_send_request("workspace.list", {}, "workspace-list")
		_send_request("session.list", {}, "session-list")
		_send_request("session.info", {}, "session-info")
	elif result_dictionary.has("contextWindowTokens"):
		_update_context_length(result_dictionary)
	elif bool(result_dictionary.get("saved", false)):
		_send_request("session.list", {}, "session-list")
	elif bool(result_dictionary.get("approved", false)) or bool(result_dictionary.get("rejected", false)):
		pending_approval_id = ""
		_send_request("session.info", {}, "session-info")


func _handle_event(message: Dictionary) -> void:
	var event_name: String = str(message.get("event", ""))
	var event_id: String = str(message.get("id", ""))
	if event_id != active_stream_id and not _is_global_event(event_name):
		return

	var data: Variant = message.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return

	var data_dictionary: Dictionary = data as Dictionary
	if event_name == "ai.delta":
		_ensure_active_assistant_item()
		if active_assistant_item != null:
			var delta_text: String = str(data_dictionary.get("text", ""))
			active_assistant_text += delta_text
			active_assistant_item.call("append_delta", delta_text)
			_update_todo_list_from_text(active_assistant_text)
			_scroll_to_bottom()
	elif event_name == "ai.done":
		if active_assistant_item != null:
			active_assistant_item.call("finish_message")
			_scroll_to_bottom()
		active_assistant_item = null
		active_stream_id = ""
		active_assistant_text = ""
		_set_streaming_state(false)
		_send_request("session.save", {}, "session-save")
		_send_request("session.info", {}, "session-info")
	elif event_name == "ai.paused":
		if active_assistant_item != null:
			active_assistant_item.call("finish_message")
			_scroll_to_bottom()
		active_assistant_item = null
		active_stream_id = ""
		active_assistant_text = ""
		_set_streaming_state(false)
	elif event_name == "ai.thinking.delta":
		_append_thinking_event(str(data_dictionary.get("text", "")))
	elif event_name == "ai.thinking.done":
		if active_thinking_item != null:
			active_thinking_item.call("finish_thinking")
			_scroll_to_bottom()
		active_thinking_item = null
	elif event_name == "tool.call":
		_add_tool_event(data_dictionary)
	elif event_name == "tool.result":
		_append_tool_event(data_dictionary)
	elif event_name == "tool.error":
		_append_tool_event(data_dictionary)
	elif event_name == "tool.approval_required":
		_add_tool_event(data_dictionary)
		_show_approval_dialog(data_dictionary)
	elif event_name == "tool.approved" or event_name == "tool.rejected":
		pending_approval_id = ""
		approval_dialog.visible = false


func _is_global_event(event_name: String) -> bool:
	return event_name == "tool.approved" or event_name == "tool.rejected"


func _update_session_list(result: Dictionary) -> void:
	sessions_by_id.clear()
	session_ids_in_order.clear()

	var sessions_value: Variant = result.get("sessions", [])
	if typeof(sessions_value) != TYPE_ARRAY:
		_render_session_list()
		return

	var sessions_array: Array = sessions_value as Array
	for item: Variant in sessions_array:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var metadata: Dictionary = item as Dictionary
		var session_id: String = str(metadata.get("id", ""))
		if session_id.is_empty():
			continue

		sessions_by_id[session_id] = metadata
		session_ids_in_order.append(session_id)

	_render_session_list()


func _update_workspace_list(result: Dictionary) -> void:
	workspaces_by_id.clear()
	workspace_filter_button.clear()
	workspace_filter_button.add_item("All", 0)
	workspace_filter_button.set_item_metadata(0, "")

	var workspaces_value: Variant = result.get("workspaces", [])
	var active_value: String = str(result.get("active", ""))
	if typeof(workspaces_value) == TYPE_ARRAY:
		var workspaces_array: Array = workspaces_value as Array
		for item: Variant in workspaces_array:
			if typeof(item) != TYPE_DICTIONARY:
				continue

			var workspace: Dictionary = item as Dictionary
			var workspace_id: String = str(workspace.get("id", ""))
			if workspace_id.is_empty():
				continue

			workspaces_by_id[workspace_id] = workspace
			var filter_text: String = workspace.get("name", "Workspace")
			if workspace_id == active_value:
				filter_text = "%s" % filter_text
			workspace_filter_button.add_item(filter_text)
			workspace_filter_button.set_item_metadata(workspace_filter_button.get_item_count() - 1, workspace_id)

	_render_session_list()


func _render_session_list() -> void:
	session_option_button.clear()
	_clear_session_buttons()

	if session_ids_in_order.is_empty():
		_select_active_session()
		return

	if not selected_workspace_filter.is_empty():
		_render_workspace_group(selected_workspace_filter)
	else:
		var rendered_workspace_ids: Array[String] = []
		for session_id: String in session_ids_in_order:
			var metadata: Dictionary = sessions_by_id.get(session_id, {}) as Dictionary
			var workspace_id: String = str(metadata.get("workspaceId", ""))
			if rendered_workspace_ids.has(workspace_id):
				continue

			rendered_workspace_ids.append(workspace_id)
			_render_workspace_group(workspace_id)

	_select_active_session()


func _render_workspace_group(workspace_id: String) -> void:
	var matching_session_ids: Array[String] = []
	for session_id: String in session_ids_in_order:
		var metadata: Dictionary = sessions_by_id.get(session_id, {}) as Dictionary
		if str(metadata.get("workspaceId", "")) != workspace_id:
			continue
		if not _does_session_match_filters(metadata):
			continue

		matching_session_ids.append(session_id)

	if matching_session_ids.is_empty():
		return

	var label: Label = Label.new()
	label.text = "%s  (%d)" % [_format_workspace_group_text(workspace_id), matching_session_ids.size()]
	session_list.add_child(label)

	for session_id: String in matching_session_ids:
		var metadata: Dictionary = sessions_by_id.get(session_id, {}) as Dictionary
		var title_text: String = str(metadata.get("title", "Untitled"))
		var updated_at: String = str(metadata.get("updatedAt", ""))

		session_option_button.add_item(title_text)
		session_option_button.set_item_metadata(session_option_button.get_item_count() - 1, session_id)

		var session_item: Button = SESSION_ITEM_SCENE.instantiate() as Button
		session_list.add_child(session_item)
		session_item.call("setup", session_id, title_text, _format_relative_time(updated_at))
		session_item.pressed.connect(_on_dynamic_session_item_pressed.bind(session_id))


func _does_session_match_filters(metadata: Dictionary) -> bool:
	if not selected_workspace_filter.is_empty() and str(metadata.get("workspaceId", "")) != selected_workspace_filter:
		return false

	if session_search_text.is_empty():
		return true

	var query: String = session_search_text.to_lower()
	var title_text: String = str(metadata.get("title", "")).to_lower()
	var workspace_id: String = str(metadata.get("workspaceId", ""))
	var workspace_text: String = _format_workspace_search_text(workspace_id).to_lower()

	return title_text.contains(query) or workspace_id.to_lower().contains(query) or workspace_text.contains(query)


func _format_workspace_group_text(workspace_id: String) -> String:
	if workspace_id.is_empty():
		return "No workspace"

	var workspace: Dictionary = workspaces_by_id.get(workspace_id, {}) as Dictionary
	if workspace.is_empty():
		return "Unknown workspace: %s" % workspace_id

	return workspace.get("name", "Workspace")


func _format_workspace_search_text(workspace_id: String) -> String:
	if workspace_id.is_empty():
		return ""

	var workspace: Dictionary = workspaces_by_id.get(workspace_id, {}) as Dictionary
	if workspace.is_empty():
		return workspace_id

	return "%s %s" % [str(workspace.get("name", "")), str(workspace.get("rootPath", ""))]


func _select_workspace_filter(workspace_id: String) -> void:
	selected_workspace_filter = workspace_id
	for index: int in range(workspace_filter_button.get_item_count()):
		if str(workspace_filter_button.get_item_metadata(index)) == workspace_id:
			workspace_filter_button.select(index)
			return


func _on_workspace_filter_button_item_selected(index: int) -> void:
	if index < 0 or index >= workspace_filter_button.get_item_count():
		return

	selected_workspace_filter = str(workspace_filter_button.get_item_metadata(index))
	_render_session_list()


func _on_search_session_line_edit_text_changed(new_text: String) -> void:
	session_search_text = new_text.strip_edges()
	_render_session_list()


func _clear_session_buttons() -> void:
	for child: Node in session_list.get_children():
		child.queue_free()


func _on_dynamic_session_item_pressed(session_id: String) -> void:
	_open_session(session_id)


func _apply_session_metadata(metadata: Dictionary) -> void:
	active_session_id = str(metadata.get("id", ""))
	_select_active_session()


func _apply_provider_config_status(status: Dictionary) -> void:
	provider_config_status = status
	var configured: bool = bool(status.get("configured", false))

	if configured:
		status_button.icon = CONNECTED_ICON
		status_button.tooltip_text = "Provider configured"
	else:
		status_button.icon = STAUTS_WARNING
		status_button.tooltip_text = "Open settings and save DeepSeek API key"

	_update_send_state()


func _select_active_session() -> void:
	if active_session_id.is_empty():
		return

	for index: int in range(session_option_button.get_item_count()):
		if str(session_option_button.get_item_metadata(index)) == active_session_id:
			session_option_button.select(index)
			return


func _clear_chat_items() -> void:
	tool_items_by_call_id.clear()
	active_assistant_item = null
	active_thinking_item = null
	active_assistant_text = ""
	_clear_todo_items()
	for child: Node in background_context_container.get_children():
		child.queue_free()
	_set_context_length_icon(0.0, true)


func _render_session_messages(messages_value: Variant) -> void:
	if typeof(messages_value) != TYPE_ARRAY:
		return

	var messages: Array = messages_value as Array
	for item: Variant in messages:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var message: Dictionary = item as Dictionary
		var role: String = str(message.get("role", ""))
		var content: String = str(message.get("content", ""))

		if role == "user":
			_add_user_message_item(content)
		elif role == "assistant":
			_add_assistant_message_item(content)

	_scroll_to_bottom()


func _render_session_timeline(messages_value: Variant, events_value: Variant) -> void:
	var messages: Array = []
	if typeof(messages_value) == TYPE_ARRAY:
		messages = messages_value as Array

	var events_by_request_id: Dictionary[String, Array] = {}
	var unmatched_events: Array[Dictionary] = []
	_collect_session_events(events_value, events_by_request_id, unmatched_events)

	var rendered_request_ids: Array[String] = []
	var rendered_unmatched_events: bool = false

	for item: Variant in messages:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var message: Dictionary = item as Dictionary
		var role: String = str(message.get("role", ""))
		var content: String = str(message.get("content", ""))
		var request_id: String = str(message.get("requestId", ""))

		if role == "user":
			_add_user_message_item(content)
			if not request_id.is_empty():
				_render_events_for_request(request_id, events_by_request_id, rendered_request_ids)
		elif role == "assistant":
			if not request_id.is_empty():
				_render_events_for_request(request_id, events_by_request_id, rendered_request_ids)
			elif not rendered_unmatched_events:
				_render_event_records(unmatched_events)
				rendered_unmatched_events = true
			_add_assistant_message_item(content)

	if not rendered_unmatched_events:
		_render_event_records(unmatched_events)

	for request_id: String in events_by_request_id.keys():
		if rendered_request_ids.has(request_id):
			continue

		_render_events_for_request(request_id, events_by_request_id, rendered_request_ids)

	active_thinking_item = null
	_scroll_to_bottom()


func _collect_session_events(events_value: Variant, events_by_request_id: Dictionary[String, Array], unmatched_events: Array[Dictionary]) -> void:
	if typeof(events_value) != TYPE_ARRAY:
		return

	var events: Array = events_value as Array
	for item: Variant in events:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var event_record: Dictionary = item as Dictionary
		var request_id: String = str(event_record.get("requestId", ""))
		if request_id.is_empty():
			unmatched_events.append(event_record)
			continue

		if not events_by_request_id.has(request_id):
			events_by_request_id[request_id] = []

		var request_events: Array = events_by_request_id[request_id]
		request_events.append(event_record)


func _render_events_for_request(request_id: String, events_by_request_id: Dictionary[String, Array], rendered_request_ids: Array[String]) -> void:
	if rendered_request_ids.has(request_id):
		return

	rendered_request_ids.append(request_id)
	var records: Array = events_by_request_id.get(request_id, []) as Array
	_render_event_records(records)


func _render_event_records(records: Array) -> void:
	for item: Variant in records:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var event_record: Dictionary = item as Dictionary
		var event_name: String = str(event_record.get("event", ""))
		var data_value: Variant = event_record.get("data", {})
		if typeof(data_value) != TYPE_DICTIONARY:
			continue

		var data: Dictionary = data_value as Dictionary
		if not data.has("type"):
			data["type"] = event_name

		_replay_session_event(event_name, data)


func _render_session_events(events_value: Variant) -> void:
	if typeof(events_value) != TYPE_ARRAY:
		return

	var events: Array = events_value as Array
	for item: Variant in events:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var event_record: Dictionary = item as Dictionary
		var event_name: String = str(event_record.get("event", ""))
		var data_value: Variant = event_record.get("data", {})
		if typeof(data_value) != TYPE_DICTIONARY:
			continue

		var data: Dictionary = data_value as Dictionary
		if not data.has("type"):
			data["type"] = event_name

		_replay_session_event(event_name, data)

	active_thinking_item = null
	_scroll_to_bottom()


func _replay_session_event(event_name: String, event_data: Dictionary) -> void:
	if event_name == "ai.thinking.delta":
		_append_thinking_event(str(event_data.get("text", "")))
	elif event_name == "ai.thinking.done":
		if active_thinking_item != null:
			active_thinking_item.call("finish_thinking")
		active_thinking_item = null
	elif event_name == "tool.call" or event_name == "tool.approval_required":
		_add_tool_event(event_data)
	elif event_name == "tool.result" or event_name == "tool.error":
		_append_tool_event(event_data)


func _add_user_message_item(message_text: String) -> void:
	var user_item: Node = USER_MESSAGE_ITEM_SCENE.instantiate()
	background_context_container.add_child(user_item)
	user_item.call("setup", message_text)


func _add_assistant_message_item(message_text: String) -> void:
	var assistant_item: Node = ASSISTANT_MARKDOWN_ITEM_SCENE.instantiate()
	background_context_container.add_child(assistant_item)
	assistant_item.call("setup", message_text)


func _ensure_active_assistant_item() -> void:
	if active_assistant_item != null:
		return

	active_assistant_item = ASSISTANT_MARKDOWN_ITEM_SCENE.instantiate()
	background_context_container.add_child(active_assistant_item)
	active_assistant_item.call("clear_message")


func _show_response_error(message: Dictionary) -> void:
	var error_value: Variant = message.get("error", {})
	var error_message: String = "Unknown backend error"
	if typeof(error_value) == TYPE_DICTIONARY:
		var error_dictionary: Dictionary = error_value as Dictionary
		error_message = str(error_dictionary.get("message", error_message))

	if active_assistant_item != null:
		active_assistant_item.call("append_delta", "\n\n后端返回错误：%s" % error_message)
		active_assistant_item.call("finish_message")
	else:
		_add_assistant_message_item("后端返回错误：%s" % error_message)

	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	if not is_inside_tree():
		return

	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value


func _add_system_tool_item(title_text: String, detail_text: String) -> void:
	var item: Node = TOOL_CALL_ITEM_SCENE.instantiate()
	background_context_container.add_child(item)
	item.call("setup", title_text, detail_text)
	_scroll_to_bottom()


func _add_tool_event(event_data: Dictionary) -> void:
	_show_background_context_viewer()
	if active_assistant_item != null:
		active_assistant_item.call("finish_message")
		active_assistant_item = null

	var tool_call_id: String = _get_tool_call_key(event_data)
	if tool_items_by_call_id.has(tool_call_id):
		var existing_item: Node = tool_items_by_call_id.get(tool_call_id, null) as Node
		if existing_item != null:
			existing_item.call("append_tool_event", event_data)
			_scroll_to_bottom()
		return

	var item: Node = TOOL_CALL_ITEM_SCENE.instantiate()
	background_context_container.add_child(item)
	item.call("setup_tool_event", event_data)
	tool_items_by_call_id[tool_call_id] = item
	_scroll_to_bottom()


func _append_tool_event(event_data: Dictionary) -> void:
	var tool_call_id: String = _get_tool_call_key(event_data)
	var item: Node = tool_items_by_call_id.get(tool_call_id, null) as Node
	if item == null:
		_add_tool_event(event_data)
		item = tool_items_by_call_id.get(tool_call_id, null) as Node

	if item != null:
		item.call("append_tool_event", event_data)
		_scroll_to_bottom()


func _append_thinking_event(delta_text: String) -> void:
	if delta_text.is_empty():
		return

	_show_background_context_viewer()
	if active_thinking_item == null:
		active_thinking_item = TOOL_CALL_ITEM_SCENE.instantiate()
		background_context_container.add_child(active_thinking_item)
		active_thinking_item.call("setup_thinking")

	active_thinking_item.call("append_thinking_delta", delta_text)
	_scroll_to_bottom()


func _get_tool_call_key(event_data: Dictionary) -> String:
	var tool_call_id: String = str(event_data.get("toolCallId", ""))
	if not tool_call_id.is_empty():
		return tool_call_id

	var approval_id: String = str(event_data.get("approvalId", ""))
	if not approval_id.is_empty():
		return approval_id

	return "%s-%s" % [str(event_data.get("toolName", "tool")), str(event_data.get("step", 0))]


func _show_approval_dialog(event_data: Dictionary) -> void:
	_show_background_context_viewer()
	pending_approval_id = str(event_data.get("approvalId", ""))
	var tool_name: String = str(event_data.get("toolName", ""))
	approval_title_label.text = "Needs approval: %s" % tool_name
	approval_description_label.text = "\n".join([
		"Approval ID: `%s`" % pending_approval_id,
		"Reason: %s" % str(event_data.get("reason", "")),
		"Args:",
		"```json",
		JSON.stringify(event_data.get("args", {}), "\t"),
		"```"
	])
	approval_dialog.visible = true
	_scroll_to_bottom()


func _update_context_length(info: Dictionary) -> void:
	var context_window_tokens: int = int(info.get("contextWindowTokens", 0))
	var history_tokens_stored: int = int(info.get("historyTokensStored", 0))

	if context_window_tokens <= 0 or history_tokens_stored <= 0:
		_set_context_length_icon(0.0, true)
		return

	var ratio: float = float(history_tokens_stored) / float(context_window_tokens)
	_set_context_length_icon(ratio, false)


func _set_context_length_icon(ratio: float, is_empty: bool) -> void:
	var icon_path: String = "%s/empty_context_length.svg" % CONTEXT_ICON_DIR

	if not is_empty:
		var level: int = int(ceil(ratio / 0.12))
		level = clampi(level, 1, 8)
		icon_path = "%s/context_length%d.svg" % [CONTEXT_ICON_DIR, level]

	var texture: Texture2D = load(icon_path) as Texture2D
	if texture != null:
		context_length_button.icon = texture

	if ratio >= 0.96:
		context_length_button.tooltip_text = "The context might be too long, it's suggested to condense the conversation."
	elif is_empty:
		context_length_button.tooltip_text = "Context usage: 0%"
	else:
		context_length_button.tooltip_text = "Context usage: %d%%" % int(round(ratio * 100.0))


func _format_relative_time(timestamp: String) -> String:
	if timestamp.is_empty():
		return ""

	return timestamp.replace("T", " ").replace("Z", "")


func _set_streaming_state(is_streaming: bool) -> void:
	send_button.visible = not is_streaming
	stop_button.visible = is_streaming
	_update_send_state()


func _update_send_state() -> void:
	var is_streaming: bool = not active_stream_id.is_empty()
	send_button.disabled = not socket_ready or is_streaming
	stop_button.disabled = not socket_ready or not is_streaming
	create_new_session_button.visible = socket_ready


func _clear_todo_items() -> void:
	last_todo_signature = ""
	todo_list.hide()
	for child: Node in todo_container.get_children():
		child.queue_free()


func _update_todo_list_from_text(text: String) -> void:
	var todos: Array[Dictionary] = _extract_todo_items(text)
	if todos.is_empty():
		return

	var signature_parts: PackedStringArray = PackedStringArray()
	for todo: Dictionary in todos:
		signature_parts.append("%s:%s" % [str(todo.get("checked", false)), str(todo.get("text", ""))])

	var signature: String = "|".join(signature_parts)
	if signature == last_todo_signature:
		return

	last_todo_signature = signature
	for child: Node in todo_container.get_children():
		child.queue_free()

	for todo: Dictionary in todos:
		var checkbox: CheckBox = CheckBox.new()
		checkbox.text = str(todo.get("text", ""))
		checkbox.button_pressed = bool(todo.get("checked", false))
		checkbox.disabled = true
		checkbox.focus_mode = Control.FOCUS_NONE
		todo_container.add_child(checkbox)

	todo_list.show()


func _extract_todo_items(text: String) -> Array[Dictionary]:
	var todos: Array[Dictionary] = []
	var lines: PackedStringArray = text.split("\n")
	var has_task_marker: bool = false
	var current_task_block: Array[Dictionary] = []

	for raw_line: String in lines:
		var line: String = raw_line.strip_edges()
		if line.begins_with("- [ ] ") or line.begins_with("* [ ] "):
			has_task_marker = true
			current_task_block.append({ "text": line.substr(6).strip_edges(), "checked": false })
		elif line.begins_with("- [x] ") or line.begins_with("- [X] ") or line.begins_with("* [x] ") or line.begins_with("* [X] "):
			has_task_marker = true
			current_task_block.append({ "text": line.substr(6).strip_edges(), "checked": true })
		elif not line.is_empty() and not current_task_block.is_empty():
			todos = current_task_block.duplicate()
			current_task_block.clear()

	if has_task_marker:
		if not current_task_block.is_empty():
			todos = current_task_block.duplicate()
		return todos

	var in_todo_block: bool = false
	for raw_line: String in lines:
		var line: String = raw_line.strip_edges()
		var lower_line: String = line.to_lower()
		if lower_line == "todo" or lower_line == "todo:" or lower_line.contains("待办"):
			in_todo_block = true
			continue

		if not in_todo_block:
			continue

		if line.is_empty():
			if not todos.is_empty():
				break
			continue

		var dot_index: int = line.find(". ")
		if dot_index > 0 and line.substr(0, dot_index).is_valid_int():
			todos.append({ "text": line.substr(dot_index + 2).strip_edges(), "checked": false })
		elif line.begins_with("- ") or line.begins_with("* "):
			todos.append({ "text": line.substr(2).strip_edges(), "checked": false })
		elif not todos.is_empty():
			break

	return todos


func _on_settings_button_pressed() -> void:
	var packed_scene: PackedScene = load(SETTINGS_MENU_UID)
	if packed_scene == null:
		return
	
	var settings_menu: AcceptDialog = packed_scene.instantiate()
	add_child(settings_menu)
	settings_menu.call("setup_provider_config", provider_config_status)
	settings_menu.connect("provider_config_save_requested", Callable(self, "_on_settings_provider_config_save_requested"))
	settings_menu.connect("provider_config_clear_requested", Callable(self, "_on_settings_provider_config_clear_requested"))


func _on_settings_provider_config_save_requested(api_key: String) -> void:
	var params: Dictionary[String, Variant] = {
		"provider": "deepseek",
		"model": _get_selected_model_id()
	}

	if not api_key.strip_edges().is_empty():
		params["apiKey"] = api_key.strip_edges()

	_send_request("provider.config.set", params, "provider-config-set")


func _on_settings_provider_config_clear_requested() -> void:
	_send_request("provider.config.clear", {}, "provider-config-clear")


func _exit_tree() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close()
