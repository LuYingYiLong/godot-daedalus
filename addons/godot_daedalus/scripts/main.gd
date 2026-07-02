@tool
extends VBoxContainer

const DEFAULT_BACKEND_URL: String = "ws://localhost:8080"
const USER_MESSAGE_ITEM_SCENE: PackedScene = preload("uid://c0qgg77075lmq")
const ASSISTANT_MARKDOWN_ITEM_SCENE: PackedScene = preload("uid://c3s4jlxtm21ci")
const TOOL_CALL_ITEM_SCENE: PackedScene = preload("uid://c2a5o7qi58fus")
const STATUS_ITEM_SCENE: PackedScene = preload("uid://cljnln76ye4o5")
const SESSION_ITEM_SCENE: PackedScene = preload("uid://bic1etsxo1epd")
const TODO_ITEM_SCENE: PackedScene = preload("uid://d3i7c6i2shbyl")
const CONTEXT_POPUP_MENU_UID: String = "uid://brjsrkaconcvu"
const CONTEXT_ICON_DIR: String = "res://addons/godot_daedalus/assets/icons"
const CONFIG_BACKEND_URL_SETTING: String = "godot_daedalus/backend_url"
const CONFIG_MODEL_ID_SETTING: String = "godot_daedalus/model_id"
const CONFIG_APPROVAL_MODE_SETTING: String = "godot_daedalus/approval_mode"
const CONFIG_CUSTOM_INSTRUCTIONS_SETTING: String = "godot_daedalus/custom_instructions"
const CONNECTED_ICON: Texture2D = preload("uid://1eh7wxaewfje")
const CONNECT_FAILED_ICON: Texture2D = preload("uid://chihcwe7t0f2g")
const DISCONNECTED_ICON: Texture2D = preload("uid://cq15q550jtb21")
const STAUTS_WARNING: Texture2D = preload("uid://gytxgaev43it")
const SETTINGS_MENU_UID: String = "uid://dp3tsanvojx2k"
const MAX_CONNECT_ATTEMPTS: int = 5
const CONNECT_RETRY_SECONDS: float = 0.8
const WEBSOCKET_BUFFER_SIZE: int = 4194304
const MAX_MESSAGES_PER_FRAME: int = 24
const MAX_MESSAGE_PROCESS_MSEC: int = 6
const TIMELINE_BUFFER_ITEMS: int = 10
const TIMELINE_PAGE_LOAD_THRESHOLD: int = 96
const TIMELINE_ESTIMATED_USER_HEIGHT: float = 88.0
const TIMELINE_ESTIMATED_ASSISTANT_HEIGHT: float = 140.0
const TIMELINE_ESTIMATED_TOOL_HEIGHT: float = 72.0
const TIMELINE_ESTIMATED_THINKING_HEIGHT: float = 72.0
const TIMELINE_ESTIMATED_STATUS_HEIGHT: float = 74.0
const TIMELINE_MIN_ITEM_HEIGHT: float = 32.0
const TIMELINE_BOTTOM_FOLLOW_THRESHOLD: float = 32.0
const SESSION_OPEN_MESSAGE_LIMIT: int = 80
const APPROVAL_ARGS_PREVIEW_LIMIT: int = 4000
const DELTA_FLUSH_INTERVAL_MSEC: int = 45
const TIMELINE_MEASURE_INTERVAL_MSEC: int = 240

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

const APPROVAL_MODE_IDS: Array[String] = [
	"manual",
	"auto-safe",
	"read-only"
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
@onready var approval_title_label: Label = %ApprovalTitleLabel
@onready var approval_description_label: TextEdit = %ApprovalDescriptionLabel
@onready var boot_splash: CenterContainer = %BootSplash
@onready var todo_list: FoldableContainer = %TodoList
@onready var todo_container: VBoxContainer = %TodoContainer

var socket: WebSocketPeer = WebSocketPeer.new()
var socket_ready: bool
var has_connected_once: bool
var connection_attempts: int
var connection_attempt_generation: int
var is_connecting: bool
var backend_recovery_mode: bool
var restore_session_after_reconnect_id: String
var connection_status_entry_id: String
var pending_recovery_status_after_session_open: bool
var request_id: int
var active_stream_id: String
var active_session_id: String
var pending_chat_text: String
var pending_approval_id: String
var sessions_by_id: Dictionary[String, Dictionary]
var session_ids_in_order: Array[String]
var archived_sessions_by_id: Dictionary[String, Dictionary]
var archived_session_ids_in_order: Array[String]
var workspaces_by_id: Dictionary[String, Dictionary]
var selected_workspace_filter: String
var session_search_text: String
var tool_items_by_call_id: Dictionary[String, Node]
var active_assistant_item: Node
var active_thinking_item: Node
var active_assistant_text: String
var last_todo_signature: String
var provider_config_status: Dictionary
var timeline_entries: Array[Dictionary]
var timeline_heights: Array[float]
var timeline_prefix_heights: Array[float]
var timeline_entry_ids: Dictionary[String, bool]
var rendered_entry_nodes: Dictionary[String, Node]
var rendered_entry_indices: Dictionary[String, int]
var timeline_top_spacer: Control
var timeline_visible_container: VBoxContainer
var timeline_bottom_spacer: Control
var timeline_render_queued: bool
var timeline_measure_queued: bool
var timeline_follow_bottom: bool = true
var timeline_scroll_to_bottom_queued: bool
var timeline_deferred_scroll_queued: bool
var timeline_deferred_scroll_version: int
var timeline_heights_dirty: bool
var timeline_message_offset: int
var timeline_has_more_before: bool
var timeline_loading_before: bool
var active_assistant_entry_id: String
var active_thinking_entry_id: String
var active_tool_entry_ids_by_call_id: Dictionary[String, String]
var active_stream_request_id: String
var active_stream_started_at_utc: String
var active_workflow_id: String
var pending_assistant_delta_text: String
var pending_assistant_delta_queued: bool
var pending_assistant_delta_flush_at_msec: int
var pending_thinking_delta_text: String
var pending_thinking_delta_queued: bool
var pending_thinking_delta_flush_at_msec: int
var timeline_measure_after_msec: int
var workflow_todo_nodes_by_id: Dictionary[String, Node]
var workflow_phase_nodes_by_id: Dictionary[String, Node]
var latest_context_info: Dictionary
var context_popup_menu: PopupPanel
var context_popup_open_after_info: bool
var active_settings_menu: Node
var backend_url: String = DEFAULT_BACKEND_URL
var custom_instructions: String
var pending_provider_config_api_key: String
var pending_provider_config_save_after_connect: bool


func _ready() -> void:
	session_list_viewer.hide()
	background_context_viewer.hide()
	text_edit.hide()
	boot_splash.show()
	_setup_options()
	_load_frontend_config()
	_setup_timeline_containers()
	_connect_timeline_signals()
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
		_handle_socket_closed_after_ready()
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


func _load_frontend_config() -> void:
	var editor_settings: EditorSettings = _get_editor_settings()
	if editor_settings == null:
		return

	_ensure_frontend_setting(editor_settings, CONFIG_BACKEND_URL_SETTING, DEFAULT_BACKEND_URL)
	_ensure_frontend_setting(editor_settings, CONFIG_MODEL_ID_SETTING, MODEL_IDS[0])
	_ensure_frontend_setting(editor_settings, CONFIG_APPROVAL_MODE_SETTING, APPROVAL_MODE_IDS[0])
	_ensure_frontend_setting(editor_settings, CONFIG_CUSTOM_INSTRUCTIONS_SETTING, "")

	backend_url = _normalize_backend_url(str(editor_settings.get_setting(CONFIG_BACKEND_URL_SETTING)))
	custom_instructions = str(editor_settings.get_setting(CONFIG_CUSTOM_INSTRUCTIONS_SETTING)).strip_edges()
	if not _select_model_id(str(editor_settings.get_setting(CONFIG_MODEL_ID_SETTING))):
		_select_model_id(MODEL_IDS[0])
	if not _select_approval_mode(str(editor_settings.get_setting(CONFIG_APPROVAL_MODE_SETTING))):
		_select_approval_mode(APPROVAL_MODE_IDS[0])


func _ensure_frontend_setting(editor_settings: EditorSettings, setting_name: String, default_value: Variant) -> void:
	if not editor_settings.has_setting(setting_name):
		editor_settings.set_setting(setting_name, default_value)
	editor_settings.set_initial_value(setting_name, default_value, false)


func _save_frontend_setting(setting_name: String, value: Variant) -> void:
	var editor_settings: EditorSettings = _get_editor_settings()
	if editor_settings == null:
		return

	if not editor_settings.has_setting(setting_name):
		editor_settings.set_setting(setting_name, value)
		editor_settings.set_initial_value(setting_name, value, false)
	editor_settings.set_setting(setting_name, value)


func _get_editor_settings() -> EditorSettings:
	if not Engine.is_editor_hint():
		return null

	return EditorInterface.get_editor_settings()


func _normalize_backend_url(url: String) -> String:
	var normalized_url: String = url.strip_edges()
	if normalized_url.is_empty():
		return DEFAULT_BACKEND_URL

	return normalized_url


func _select_model_id(model_id: String) -> bool:
	for index: int in range(MODEL_IDS.size()):
		if MODEL_IDS[index] == model_id:
			model_button.select(index)
			return true

	return false


func _select_approval_mode(approval_mode: String) -> bool:
	for index: int in range(APPROVAL_MODE_IDS.size()):
		if APPROVAL_MODE_IDS[index] == approval_mode:
			approval_mode_button.select(index)
			return true

	return false


func _clear_template_items() -> void:
	_setup_timeline_containers()


func _setup_timeline_containers() -> void:
	if timeline_visible_container != null and is_instance_valid(timeline_visible_container):
		return

	for child: Node in background_context_container.get_children():
		child.queue_free()

	timeline_top_spacer = Control.new()
	timeline_top_spacer.name = "TopSpacer"
	timeline_top_spacer.custom_minimum_size = Vector2(0.0, 0.0)
	background_context_container.add_child(timeline_top_spacer)

	timeline_visible_container = VBoxContainer.new()
	timeline_visible_container.name = "VisibleItemsContainer"
	timeline_visible_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background_context_container.add_child(timeline_visible_container)

	timeline_bottom_spacer = Control.new()
	timeline_bottom_spacer.name = "BottomSpacer"
	timeline_bottom_spacer.custom_minimum_size = Vector2(0.0, 0.0)
	background_context_container.add_child(timeline_bottom_spacer)


func _connect_timeline_signals() -> void:
	var vertical_scroll_bar: VScrollBar = scroll_container.get_v_scroll_bar()
	if vertical_scroll_bar != null and not vertical_scroll_bar.value_changed.is_connected(_on_timeline_scroll_value_changed):
		vertical_scroll_bar.value_changed.connect(_on_timeline_scroll_value_changed)


func _on_timeline_scroll_value_changed(_value: float) -> void:
	timeline_follow_bottom = _is_timeline_near_bottom()
	if not timeline_follow_bottom:
		timeline_scroll_to_bottom_queued = false
		timeline_deferred_scroll_queued = false
		timeline_deferred_scroll_version += 1
	if scroll_container.scroll_vertical <= TIMELINE_PAGE_LOAD_THRESHOLD:
		_request_previous_timeline_page()
	_schedule_timeline_render(false)


func _start_backend_connection_attempts(show_boot_screen: bool = true, recovery_mode: bool = false) -> void:
	connection_attempts = 0
	connection_attempt_generation += 1
	is_connecting = true
	socket_ready = false
	backend_recovery_mode = recovery_mode
	if not recovery_mode:
		restore_session_after_reconnect_id = ""
		pending_recovery_status_after_session_open = false
		connection_status_entry_id = ""
	if show_boot_screen:
		boot_splash.show()
		boot_splash.call("show_connecting")
		session_list_viewer.hide()
		background_context_viewer.hide()
		text_edit.hide()
	_connect_to_backend()


func _connect_to_backend() -> void:
	connection_attempts += 1
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = WEBSOCKET_BUFFER_SIZE
	socket.outbound_buffer_size = WEBSOCKET_BUFFER_SIZE
	var connect_error: Error = socket.connect_to_url(backend_url)
	if connect_error != OK:
		status_button.icon = CONNECT_FAILED_ICON
		status_button.tooltip_text = "Connect failed: %d. Click to reconnect." % connect_error
		if backend_recovery_mode:
			_upsert_connection_status_entry(
				"error",
				"连接失败",
				"无法连接到 Daedalus 后端：%d\n地址：%s" % [connect_error, backend_url],
				"重试",
				"reconnect"
			)
		_retry_backend_connection()
		return
	
	status_button.icon = DISCONNECTED_ICON
	status_button.tooltip_text = "Connecting... (%d/%d)" % [connection_attempts, MAX_CONNECT_ATTEMPTS]
	if backend_recovery_mode:
		_upsert_connection_status_entry(
			"reconnecting",
			"正在重连",
			"正在重新连接 Daedalus 后端（%d/%d）\n地址：%s" % [connection_attempts, MAX_CONNECT_ATTEMPTS, backend_url]
		)


func _retry_backend_connection() -> void:
	if connection_attempts >= MAX_CONNECT_ATTEMPTS:
		is_connecting = false
		status_button.icon = CONNECT_FAILED_ICON
		status_button.tooltip_text = "Connect failed. Click to reconnect."
		if backend_recovery_mode:
			_upsert_connection_status_entry(
				"error",
				"重连失败",
				"已经尝试 %d 次，仍无法连接后端。\n请确认后端已启动：npm run dev\n地址：%s" % [MAX_CONNECT_ATTEMPTS, backend_url],
				"重试",
				"reconnect"
			)
		else:
			boot_splash.call("show_error", "Cannot connect to Daedalus backend", "请确认后端已启动：npm run dev\n地址：%s" % backend_url)
		return

	is_connecting = false
	var retry_generation: int = connection_attempt_generation
	await get_tree().create_timer(CONNECT_RETRY_SECONDS).timeout
	if retry_generation != connection_attempt_generation:
		return
	if socket_ready:
		return

	is_connecting = true
	_connect_to_backend()


func _on_socket_opened() -> void:
	var was_recovering: bool = backend_recovery_mode
	var session_id_to_restore: String = restore_session_after_reconnect_id
	is_connecting = false
	backend_recovery_mode = false
	has_connected_once = true
	status_button.icon = CONNECTED_ICON
	status_button.tooltip_text = "Connected"
	boot_splash.hide()
	if not was_recovering:
		_show_session_list_viewer()
	elif active_session_id.is_empty():
		_show_session_list_viewer()
	text_edit.show()
	_send_environment_config()
	if pending_provider_config_save_after_connect:
		var deferred_api_key: String = pending_provider_config_api_key
		pending_provider_config_api_key = ""
		pending_provider_config_save_after_connect = false
		_save_provider_config_to_backend(deferred_api_key)
	else:
		_load_provider_config()
	_apply_approval_mode_to_backend()
	_refresh_session_and_archive_lists()
	if was_recovering:
		_upsert_connection_status_entry(
			"success",
			"连接已恢复",
			"已重新连接后端，正在恢复当前会话。"
		)
		if not session_id_to_restore.is_empty():
			pending_recovery_status_after_session_open = true
			_send_request("session.open", { "sessionId": session_id_to_restore, "limit": SESSION_OPEN_MESSAGE_LIMIT }, "session-recover-open")
		else:
			_finalize_recovery_status(false)


func _on_boot_splash_reconnect_requested() -> void:
	_start_backend_connection_attempts()


func _on_status_button_pressed() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return

	_restart_backend_connection(has_connected_once)


func _handle_socket_closed_after_ready() -> void:
	var close_detail: String = _format_socket_close_tooltip("Disconnected")
	var session_id_to_restore: String = active_session_id
	var was_streaming: bool = not active_stream_id.is_empty()
	socket_ready = false
	status_button.icon = DISCONNECTED_ICON
	status_button.tooltip_text = "%s. Reconnecting..." % close_detail
	_update_send_state()
	_begin_backend_recovery(close_detail, session_id_to_restore, was_streaming)


func _begin_backend_recovery(close_detail: String, session_id_to_restore: String, was_streaming: bool) -> void:
	restore_session_after_reconnect_id = session_id_to_restore
	pending_recovery_status_after_session_open = false
	var details: String = "%s\n正在自动重连 Daedalus 后端。" % close_detail
	if was_streaming:
		_stop_active_stream_locally(true)
		details += "\n当前回复已在本地暂停；恢复后可以直接发送“继续”。"
	_upsert_connection_status_entry("warning", "连接中断", details)
	_start_backend_connection_attempts(false, true)


func _handle_recovered_session_open(result_dictionary: Dictionary) -> void:
	var metadata_value: Variant = result_dictionary.get("metadata", {})
	if typeof(metadata_value) == TYPE_DICTIONARY:
		_apply_session_metadata(metadata_value as Dictionary)
	_apply_latest_workflow_snapshot(result_dictionary)
	_send_request("session.info", {}, "session-info")
	_finalize_recovery_status(true)


func _finalize_recovery_status(session_restored: bool) -> void:
	pending_recovery_status_after_session_open = false
	restore_session_after_reconnect_id = ""
	var details: String = "已重新连接 Daedalus 后端。"
	if session_restored:
		details += "\n当前会话已恢复；如果上一条回复被中断，可以继续发送。"
	_upsert_connection_status_entry("success", "连接已恢复", details)
	connection_status_entry_id = ""


func _on_status_item_action_requested(action_id: String) -> void:
	if action_id == "reconnect":
		_restart_backend_connection(true)


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


func _get_selected_approval_mode() -> String:
	var selected_index: int = approval_mode_button.selected
	if selected_index < 0 or selected_index >= APPROVAL_MODE_IDS.size():
		return APPROVAL_MODE_IDS[0]

	return APPROVAL_MODE_IDS[selected_index]


func _apply_model_config_to_backend() -> void:
	if not _is_socket_open():
		return

	var params: Dictionary[String, Variant] = {
		"provider": "deepseek",
		"model": _get_selected_model_id()
	}
	_send_request("provider.config.set", params, "provider-config-set")


func _apply_approval_mode_to_backend() -> void:
	if not _is_socket_open():
		return

	_send_request("approval.mode.set", { "mode": _get_selected_approval_mode() }, "approval-mode-set")


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


func _on_model_button_item_selected(index: int) -> void:
	if index < 0 or index >= MODEL_IDS.size():
		return

	_save_frontend_setting(CONFIG_MODEL_ID_SETTING, MODEL_IDS[index])
	_apply_model_config_to_backend()


func _on_approval_mode_button_item_selected(index: int) -> void:
	if index < 0 or index >= APPROVAL_MODE_IDS.size():
		return

	_save_frontend_setting(CONFIG_APPROVAL_MODE_SETTING, APPROVAL_MODE_IDS[index])
	_apply_approval_mode_to_backend()


func _on_send_button_pressed() -> void:
	var message_text: String = text_edit.text.strip_edges()
	if message_text.is_empty():
		return

	if active_session_id.is_empty():
		pending_chat_text = message_text
		_create_session(_make_session_title(message_text))
		return

	_send_chat_text(message_text)


func _on_user_message_resend_requested(request_id_to_retry: String, message_text: String) -> void:
	if message_text.strip_edges().is_empty() or not active_stream_id.is_empty():
		return

	if active_session_id.is_empty():
		_send_chat_text(message_text)
		return

	_trim_timeline_from_request(request_id_to_retry)
	_send_chat_text(message_text, request_id_to_retry)


func _trim_timeline_from_request(request_id_to_retry: String) -> void:
	if request_id_to_retry.is_empty():
		return

	var first_index: int = -1
	for index: int in range(timeline_entries.size()):
		var entry: Dictionary = timeline_entries[index]
		if str(entry.get("request_id", "")) == request_id_to_retry:
			first_index = index
			break

	if first_index < 0:
		return

	while timeline_entries.size() > first_index:
		timeline_entries.remove_at(timeline_entries.size() - 1)

	for child: Node in timeline_visible_container.get_children():
		child.queue_free()
	rendered_entry_nodes.clear()
	rendered_entry_indices.clear()
	tool_items_by_call_id.clear()
	active_assistant_item = null
	active_thinking_item = null
	active_assistant_entry_id = ""
	active_thinking_entry_id = ""
	active_assistant_text = ""
	active_stream_started_at_utc = ""
	_rebuild_timeline_index_cache()
	_rebuild_timeline_height_cache()
	_clear_todo_items()
	_render_visible_timeline(true)


func _on_stop_button_pressed() -> void:
	if active_stream_id.is_empty():
		return

	var request_id_to_cancel: String = active_stream_id
	_send_request("ai.cancel", { "requestId": request_id_to_cancel }, "ai-cancel")
	_stop_active_stream_locally(true)


func _stop_active_stream_locally(prepare_continue: bool) -> void:
	_flush_pending_assistant_delta()
	_flush_pending_thinking_delta()
	if active_assistant_item != null:
		active_assistant_item.call("finish_message")
	if active_thinking_item != null:
		active_thinking_item.call("finish_thinking")

	active_stream_id = ""
	active_stream_request_id = ""
	active_stream_started_at_utc = ""
	active_assistant_item = null
	active_thinking_item = null
	active_assistant_entry_id = ""
	active_thinking_entry_id = ""
	active_assistant_text = ""
	_set_streaming_state(false)

	if prepare_continue and text_edit.text.strip_edges().is_empty():
		text_edit.text = "继续"
		text_edit.grab_focus()


func _on_approve_button_pressed() -> void:
	if pending_approval_id.is_empty():
		return

	var should_follow_bottom: bool = _should_follow_timeline_updates()
	active_stream_id = _send_request("approval.approve", { "approvalId": pending_approval_id }, "approval-approve")
	active_stream_request_id = active_stream_id
	active_stream_started_at_utc = _get_utc_timestamp()
	active_assistant_item = null
	active_assistant_entry_id = ""
	active_assistant_text = ""
	_set_streaming_state(true)
	_scroll_to_bottom_if_following(should_follow_bottom)
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

	_send_request("session.open", { "sessionId": session_id, "limit": SESSION_OPEN_MESSAGE_LIMIT }, "session-open")


func _send_chat_text(message_text: String, retry_from_request_id: String = "") -> void:
	if not _is_socket_open():
		return

	_show_background_context_viewer()

	active_assistant_item = null
	active_assistant_entry_id = ""
	active_thinking_entry_id = ""
	active_assistant_text = ""
	_clear_todo_items()

	request_id += 1
	active_stream_id = "daedalus-chat-%d" % request_id
	active_stream_request_id = active_stream_id
	active_stream_started_at_utc = _get_utc_timestamp()
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	_append_timeline_entry("user", active_stream_request_id, message_text, "", { "sent_at_utc": active_stream_started_at_utc })
	_schedule_timeline_render(should_follow_bottom)

	var chat_params: Dictionary[String, Variant] = {
		"message": message_text,
		"promptId": "godot.assistant",
		"options": {
			"stream": true,
			"toolBudget": "project_edit",
			"workflow": "llm_planned"
		}
	}
	if not custom_instructions.is_empty():
		chat_params["systemPrompt"] = custom_instructions
	if not retry_from_request_id.is_empty():
		chat_params["retryFromRequestId"] = retry_from_request_id

	var payload: Dictionary[String, Variant] = {
		"type": "request",
		"id": active_stream_id,
		"method": "ai.chat",
		"params": chat_params
	}

	var send_error: Error = socket.send_text(JSON.stringify(payload))
	if send_error != OK:
		active_stream_id = ""
		active_stream_started_at_utc = ""
		active_assistant_item = null
		_set_streaming_state(false)
		return

	_scroll_to_bottom_if_following(should_follow_bottom)
	text_edit.clear()
	_set_streaming_state(true)


func _make_session_title(message_text: String) -> String:
	var one_line: String = message_text.replace("\n", " ").strip_edges()
	if one_line.length() > 24:
		return one_line.substr(0, 24)

	if one_line.is_empty():
		return "新会话"

	return one_line


func _get_utc_timestamp() -> String:
	return "%sZ" % Time.get_datetime_string_from_system(true, false)


func _send_request(method: String, params: Dictionary, id_prefix: String) -> String:
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


func _format_socket_close_tooltip(prefix: String) -> String:
	var close_code: int = socket.get_close_code()
	var close_reason: String = socket.get_close_reason()
	if close_reason.is_empty():
		return "%s (%d)" % [prefix, close_code]

	return "%s (%d): %s" % [prefix, close_code, close_reason]


func _receive_messages() -> void:
	var processed_count: int = 0
	var started_at_msec: int = Time.get_ticks_msec()
	while socket.get_available_packet_count() > 0:
		if processed_count >= MAX_MESSAGES_PER_FRAME:
			return
		if Time.get_ticks_msec() - started_at_msec >= MAX_MESSAGE_PROCESS_MSEC:
			return

		var packet: PackedByteArray = socket.get_packet()
		processed_count += 1
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
		if str(message.get("id", "")).begins_with("context-popup-info"):
			context_popup_open_after_info = false
		if str(message.get("id", "")).begins_with("session-timeline"):
			timeline_loading_before = false
		if str(message.get("id", "")).begins_with("session-recover-open"):
			pending_recovery_status_after_session_open = false
			restore_session_after_reconnect_id = ""
			_upsert_connection_status_entry(
				"warning",
				"连接已恢复",
				"后端已重新连接，但当前会话恢复失败。可以手动从会话列表重新打开。"
			)
			connection_status_entry_id = ""
			return
		if str(message.get("id", "")) == active_stream_id:
			_show_response_error(message)
			active_stream_id = ""
			active_stream_started_at_utc = ""
			active_assistant_item = null
			active_assistant_text = ""
			_set_streaming_state(false)
		else:
			_show_background_context_viewer()
			_show_response_error(message)
		return

	var result: Variant = message.get("result", {})
	if typeof(result) != TYPE_DICTIONARY:
		return

	var result_dictionary: Dictionary = result as Dictionary
	if result_dictionary.has("archivedSessions"):
		_update_archived_session_list(result_dictionary)
	elif result_dictionary.has("workspaces"):
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
	elif bool(result_dictionary.get("opened", false)) and str(message.get("id", "")).begins_with("session-recover-open"):
		_handle_recovered_session_open(result_dictionary)
	elif bool(result_dictionary.get("opened", false)):
		var metadata: Variant = result_dictionary.get("metadata", {})
		if typeof(metadata) == TYPE_DICTIONARY:
			_apply_session_metadata(metadata as Dictionary)
		_clear_chat_items()
		_show_background_context_viewer()
		_render_session_timeline(result_dictionary.get("messages", []), result_dictionary.get("events", []), result_dictionary)
		_apply_latest_workflow_snapshot(result_dictionary)
		_send_request("workspace.list", {}, "workspace-list")
		_send_request("session.info", {}, "session-info")
	elif bool(result_dictionary.get("timeline", false)):
		_prepend_session_timeline(result_dictionary)
	elif bool(result_dictionary.get("paused", false)) and str(result_dictionary.get("approvalId", "")).length() > 0:
		active_stream_id = ""
		active_stream_request_id = ""
		active_stream_started_at_utc = ""
		active_assistant_item = null
		active_assistant_entry_id = ""
		active_assistant_text = ""
		_set_streaming_state(false)
		_show_approval_dialog(result_dictionary)
	elif bool(result_dictionary.get("configured", false)) and result_dictionary.has("provider"):
		_update_send_state()
	elif bool(result_dictionary.get("configured", false)) and result_dictionary.has("godotProjectPath"):
		_send_request("workspace.list", {}, "workspace-list")
		_send_request("session.list", {}, "session-list")
		_send_request("session.info", {}, "session-info")
	elif result_dictionary.has("contextWindowTokens"):
		_update_context_length(result_dictionary)
		if context_popup_open_after_info:
			context_popup_open_after_info = false
			_show_context_popup_menu()
		if int(result_dictionary.get("pendingApprovals", 0)) > 0 and not approval_dialog.visible:
			_send_request("approval.list", {}, "approval-list")
	elif result_dictionary.has("pending") and result_dictionary.has("mode"):
		_show_first_pending_approval(result_dictionary)
	elif bool(result_dictionary.get("saved", false)):
		_send_request("session.list", {}, "session-list")
	elif bool(result_dictionary.get("archived", false)):
		_apply_archived_session_response(result_dictionary)
	elif bool(result_dictionary.get("restored", false)):
		_refresh_session_and_archive_lists()
	elif bool(result_dictionary.get("deletedArchived", false)):
		_remove_archived_session(str(result_dictionary.get("sessionId", "")))
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
		var delta_text: String = str(data_dictionary.get("text", ""))
		active_assistant_text += delta_text
		pending_assistant_delta_text += delta_text
		if active_workflow_id.is_empty():
			_update_todo_list_from_text(active_assistant_text)
		_schedule_assistant_delta_flush()
	elif event_name == "ai.done":
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		var completed_at_utc: String = _get_utc_timestamp()
		_flush_pending_assistant_delta()
		if not active_assistant_entry_id.is_empty():
			_set_timeline_entry_times(active_assistant_entry_id, active_stream_started_at_utc, completed_at_utc)
		if active_assistant_item != null:
			active_assistant_item.call("finish_message", active_stream_started_at_utc, completed_at_utc)
		_schedule_timeline_render(should_follow_bottom)
		active_assistant_item = null
		active_assistant_entry_id = ""
		active_stream_id = ""
		active_stream_request_id = ""
		active_stream_started_at_utc = ""
		active_assistant_text = ""
		_set_streaming_state(false)
		_send_request("session.save", {}, "session-save")
		_send_request("session.info", {}, "session-info")
	elif event_name == "ai.paused":
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		_flush_pending_assistant_delta()
		if active_assistant_item != null:
			active_assistant_item.call("finish_message")
			_schedule_timeline_render(should_follow_bottom)
		active_assistant_item = null
		active_assistant_entry_id = ""
		active_stream_id = ""
		active_stream_request_id = ""
		active_stream_started_at_utc = ""
		active_assistant_text = ""
		_set_streaming_state(false)
		if str(data_dictionary.get("approvalId", "")).length() > 0:
			_show_approval_dialog(data_dictionary)
	elif event_name == "ai.cancelled":
		_stop_active_stream_locally(false)
	elif event_name == "ai.thinking.delta":
		_append_thinking_event(str(data_dictionary.get("text", "")))
	elif event_name == "ai.thinking.done":
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		_flush_pending_thinking_delta()
		_set_timeline_entry_collapsed(active_thinking_entry_id, true)
		if active_thinking_item != null:
			active_thinking_item.call("finish_thinking")
			_schedule_timeline_render(should_follow_bottom)
		active_thinking_item = null
		active_thinking_entry_id = ""
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
	elif event_name == "workflow.started":
		active_workflow_id = str(data_dictionary.get("workflowId", ""))
	elif event_name == "workflow.todo.updated":
		_apply_workflow_todo_snapshot(data_dictionary)


func _is_global_event(event_name: String) -> bool:
	return event_name == "tool.approved" or event_name == "tool.rejected" or event_name == "tool.approval_required" or event_name == "ai.paused" or event_name == "ai.cancelled" or event_name.begins_with("workflow.")


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


func _update_archived_session_list(result: Dictionary) -> void:
	archived_sessions_by_id.clear()
	archived_session_ids_in_order.clear()

	var sessions_value: Variant = result.get("archivedSessions", [])
	if typeof(sessions_value) != TYPE_ARRAY:
		_sync_settings_archived_sessions()
		return

	var sessions_array: Array = sessions_value as Array
	for item: Variant in sessions_array:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var metadata: Dictionary = item as Dictionary
		var session_id: String = str(metadata.get("id", ""))
		if session_id.is_empty():
			continue

		archived_sessions_by_id[session_id] = metadata
		archived_session_ids_in_order.append(session_id)

	_sync_settings_archived_sessions()


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
	_sync_settings_archived_sessions()


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
	label.theme_type_variation = &"HeaderSmall"
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
		session_item.connect("open_requested", Callable(self, "_on_dynamic_session_item_pressed"))
		session_item.connect("archive_requested", Callable(self, "_on_session_archive_requested"))


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


func _on_session_archive_requested(session_id: String) -> void:
	if not _is_socket_open() or session_id.is_empty():
		return

	_send_request("session.archive", { "sessionId": session_id }, "session-archive")


func _apply_archived_session_response(result_dictionary: Dictionary) -> void:
	var metadata_value: Variant = result_dictionary.get("metadata", {})
	if typeof(metadata_value) != TYPE_DICTIONARY:
		_refresh_session_and_archive_lists()
		return

	var metadata: Dictionary = metadata_value as Dictionary
	var session_id: String = str(metadata.get("id", ""))
	if not session_id.is_empty():
		sessions_by_id.erase(session_id)
		session_ids_in_order.erase(session_id)
		archived_sessions_by_id[session_id] = metadata
		if not archived_session_ids_in_order.has(session_id):
			archived_session_ids_in_order.insert(0, session_id)
		if active_session_id == session_id:
			active_session_id = ""

	_render_session_list()
	_sync_settings_archived_sessions()
	_refresh_session_and_archive_lists()


func _remove_archived_session(session_id: String) -> void:
	if session_id.is_empty():
		return

	archived_sessions_by_id.erase(session_id)
	archived_session_ids_in_order.erase(session_id)
	_sync_settings_archived_sessions()


func _refresh_session_and_archive_lists() -> void:
	_send_request("session.list", {}, "session-list")
	_send_request("session.archived.list", {}, "session-archived-list")


func _apply_session_metadata(metadata: Dictionary) -> void:
	active_session_id = str(metadata.get("id", ""))
	_select_active_session()


func _apply_provider_config_status(status: Dictionary) -> void:
	provider_config_status = status
	var configured: bool = bool(status.get("configured", false))
	var model_value: Variant = status.get("model", null)

	if configured:
		status_button.icon = CONNECTED_ICON
		status_button.tooltip_text = "Provider configured"
	else:
		status_button.icon = STAUTS_WARNING
		status_button.tooltip_text = "Open settings and save DeepSeek API key"

	if typeof(model_value) == TYPE_STRING and _select_model_id(str(model_value)):
		_save_frontend_setting(CONFIG_MODEL_ID_SETTING, str(model_value))
	else:
		_apply_model_config_to_backend()

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
	active_tool_entry_ids_by_call_id.clear()
	active_assistant_item = null
	active_thinking_item = null
	active_assistant_entry_id = ""
	active_thinking_entry_id = ""
	active_stream_request_id = ""
	active_stream_started_at_utc = ""
	connection_status_entry_id = ""
	active_assistant_text = ""
	pending_assistant_delta_text = ""
	pending_assistant_delta_queued = false
	pending_thinking_delta_text = ""
	pending_thinking_delta_queued = false
	pending_assistant_delta_flush_at_msec = 0
	pending_thinking_delta_flush_at_msec = 0
	timeline_measure_after_msec = 0
	timeline_entries.clear()
	timeline_heights.clear()
	timeline_prefix_heights.clear()
	timeline_entry_ids.clear()
	rendered_entry_nodes.clear()
	rendered_entry_indices.clear()
	timeline_heights_dirty = true
	timeline_message_offset = 0
	timeline_has_more_before = false
	timeline_loading_before = false
	_clear_todo_items()
	_setup_timeline_containers()
	for child: Node in timeline_visible_container.get_children():
		child.queue_free()
	timeline_top_spacer.custom_minimum_size = Vector2(0.0, 0.0)
	timeline_bottom_spacer.custom_minimum_size = Vector2(0.0, 0.0)
	_set_context_length_icon(0.0, true)


func _render_session_timeline(messages_value: Variant, events_value: Variant, page_info: Dictionary) -> void:
	timeline_message_offset = int(page_info.get("messagesOffset", 0))
	timeline_has_more_before = bool(page_info.get("hasMoreBefore", false))
	timeline_loading_before = false
	_append_session_records_to_timeline(messages_value, events_value)
	active_thinking_item = null
	_rebuild_timeline_index_cache()
	_rebuild_timeline_height_cache()
	_render_visible_timeline(true)


func _request_previous_timeline_page() -> void:
	if timeline_loading_before or not timeline_has_more_before:
		return
	if active_session_id.is_empty() or timeline_message_offset <= 0:
		return
	if not _is_socket_open():
		return

	timeline_loading_before = true
	var params: Dictionary[String, Variant] = {
		"sessionId": active_session_id,
		"beforeOffset": timeline_message_offset,
		"limit": SESSION_OPEN_MESSAGE_LIMIT
	}
	_send_request("session.timeline", params, "session-timeline")


func _prepend_session_timeline(page_info: Dictionary) -> void:
	timeline_loading_before = false

	var messages_value: Variant = page_info.get("messages", [])
	if typeof(messages_value) != TYPE_ARRAY:
		return

	var before_size: int = timeline_entries.size()
	_append_session_records_to_timeline(messages_value, page_info.get("events", []))
	var after_size: int = timeline_entries.size()
	if after_size <= before_size:
		timeline_message_offset = int(page_info.get("messagesOffset", timeline_message_offset))
		timeline_has_more_before = bool(page_info.get("hasMoreBefore", false))
		return

	var appended_entries: Array[Dictionary] = []
	for index: int in range(before_size, after_size):
		appended_entries.append(timeline_entries[index])

	var existing_entries: Array[Dictionary] = []
	for index: int in range(0, before_size):
		existing_entries.append(timeline_entries[index])

	var added_height: float = 0.0
	for entry: Dictionary in appended_entries:
		added_height += _get_entry_cached_height(entry)

	timeline_entries.clear()
	for entry: Dictionary in appended_entries:
		timeline_entries.append(entry)
	for entry: Dictionary in existing_entries:
		timeline_entries.append(entry)

	timeline_message_offset = int(page_info.get("messagesOffset", timeline_message_offset))
	timeline_has_more_before = bool(page_info.get("hasMoreBefore", false))
	_rebuild_timeline_index_cache()
	_rebuild_timeline_height_cache()
	for child: Node in timeline_visible_container.get_children():
		child.queue_free()
	rendered_entry_nodes.clear()
	rendered_entry_indices.clear()
	_render_visible_timeline(false)
	_restore_scroll_after_prepend(added_height)


func _restore_scroll_after_prepend(added_height: float) -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(float(scroll_container.scroll_vertical) + added_height)


func _apply_latest_workflow_snapshot(page_info: Dictionary) -> void:
	var snapshot_value: Variant = page_info.get("latestWorkflowSnapshot", null)
	if typeof(snapshot_value) != TYPE_DICTIONARY:
		return

	_apply_workflow_todo_snapshot(snapshot_value as Dictionary)


func _append_session_records_to_timeline(messages_value: Variant, events_value: Variant) -> void:
	var messages: Array = []
	if typeof(messages_value) == TYPE_ARRAY:
		messages = messages_value as Array

	var message_request_ids: Dictionary[String, bool] = _collect_message_request_ids(messages)
	var events_by_request_id: Dictionary[String, Array] = {}
	var orphan_events: Array[Dictionary] = []
	_collect_session_events(events_value, message_request_ids, events_by_request_id, orphan_events)

	var consumed_request_ids: Array[String] = []
	var rendered_orphan_events: bool = false
	var request_started_at_by_id: Dictionary[String, String] = {}

	for item: Variant in messages:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var message: Dictionary = item as Dictionary
		var role: String = str(message.get("role", ""))
		var content: String = str(message.get("content", ""))
		var request_id: String = str(message.get("requestId", ""))
		var created_at: String = str(message.get("createdAt", ""))

		if role == "user":
			_append_timeline_entry("user", request_id, content, _make_message_entry_id(message, role), { "sent_at_utc": created_at })
			if not request_id.is_empty() and not created_at.is_empty():
				request_started_at_by_id[request_id] = created_at
			if not request_id.is_empty():
				_append_events_for_request(request_id, events_by_request_id, consumed_request_ids)
		elif role == "assistant":
			if not request_id.is_empty():
				_append_events_for_request(request_id, events_by_request_id, consumed_request_ids)
			if not rendered_orphan_events and not orphan_events.is_empty():
				_append_event_records(orphan_events)
				rendered_orphan_events = true
			var started_at_utc: String = str(request_started_at_by_id.get(request_id, ""))
			_append_timeline_entry(
				"assistant",
				request_id,
				content,
				_make_message_entry_id(message, role),
				{
					"started_at_utc": started_at_utc,
					"completed_at_utc": created_at
				}
			)

	if not rendered_orphan_events:
		_append_event_records(orphan_events)

	for request_id: String in events_by_request_id.keys():
		if consumed_request_ids.has(request_id):
			continue

		_append_events_for_request(request_id, events_by_request_id, consumed_request_ids)


func _make_message_entry_id(message: Dictionary, role: String) -> String:
	var request_id: String = str(message.get("requestId", ""))
	var created_at: String = str(message.get("createdAt", ""))
	if request_id.is_empty() and created_at.is_empty():
		return ""

	return "message:%s:%s:%s" % [request_id, role, created_at]


func _collect_message_request_ids(messages: Array) -> Dictionary[String, bool]:
	var ids: Dictionary[String, bool] = {}
	for item: Variant in messages:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var message: Dictionary = item as Dictionary
		var request_id: String = str(message.get("requestId", ""))
		if not request_id.is_empty():
			ids[request_id] = true

	return ids


func _collect_session_events(
	events_value: Variant,
	message_request_ids: Dictionary[String, bool],
	events_by_request_id: Dictionary[String, Array],
	orphan_events: Array[Dictionary]
) -> void:
	if typeof(events_value) != TYPE_ARRAY:
		return

	var events: Array = events_value as Array
	for item: Variant in events:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var event_record: Dictionary = item as Dictionary
		var request_id: String = str(event_record.get("requestId", ""))
		if request_id.is_empty() or not message_request_ids.has(request_id):
			orphan_events.append(event_record)
			continue

		if not events_by_request_id.has(request_id):
			events_by_request_id[request_id] = []

		var request_events: Array = events_by_request_id[request_id]
		request_events.append(event_record)

	for request_id: String in events_by_request_id.keys():
		var records: Array = events_by_request_id.get(request_id, []) as Array
		records.sort_custom(_compare_event_records_by_created_at)

	orphan_events.sort_custom(_compare_event_records_by_created_at)


func _compare_event_records_by_created_at(left: Dictionary, right: Dictionary) -> bool:
	var left_created_at: String = str(left.get("createdAt", ""))
	var right_created_at: String = str(right.get("createdAt", ""))
	if left_created_at == right_created_at:
		return str(left.get("id", "")) < str(right.get("id", ""))

	return left_created_at < right_created_at


func _append_events_for_request(request_id: String, events_by_request_id: Dictionary[String, Array], consumed_request_ids: Array[String]) -> void:
	if consumed_request_ids.has(request_id):
		return

	consumed_request_ids.append(request_id)
	var records: Array = events_by_request_id.get(request_id, []) as Array
	_append_event_records(records)


func _append_event_records(records: Array) -> void:
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
		data["_eventRecordId"] = str(event_record.get("id", ""))

		_append_event_to_timeline(event_name, data, str(event_record.get("requestId", "")))


func _append_timeline_entry(entry_type: String, request_id: String, content: String, preferred_entry_id: String = "", metadata: Dictionary = {}) -> String:
	var entry_id: String = preferred_entry_id
	if entry_id.is_empty():
		entry_id = "timeline-%d-%d" % [Time.get_ticks_msec(), timeline_entries.size()]
	if timeline_entry_ids.has(entry_id):
		return entry_id

	var entry: Dictionary = {
		"id": entry_id,
		"type": entry_type,
		"request_id": request_id,
		"content": content,
		"events": [],
		"height_estimate": _estimate_timeline_entry_height(entry_type, content),
		"height_actual": 0.0,
		"collapsed": false,
		"tool_call_id": ""
	}
	for metadata_key: Variant in metadata.keys():
		entry[str(metadata_key)] = metadata[metadata_key]
	timeline_entries.append(entry)
	timeline_entry_ids[entry_id] = true
	timeline_heights.append(_get_entry_cached_height(entry))
	timeline_heights_dirty = true
	return entry_id


func _upsert_connection_status_entry(
	status_text: String,
	title_text: String,
	detail_text: String,
	action_label: String = "",
	action_id: String = ""
) -> void:
	var metadata: Dictionary = {
		"status": status_text,
		"title": title_text,
		"detail": detail_text,
		"action_label": action_label,
		"action_id": action_id
	}

	if connection_status_entry_id.is_empty() or _find_timeline_entry_index(connection_status_entry_id) < 0:
		connection_status_entry_id = _append_timeline_entry(
			"status",
			"",
			detail_text,
			"connection-status-%d" % Time.get_ticks_msec(),
			metadata
		)
	else:
		var index: int = _find_timeline_entry_index(connection_status_entry_id)
		if index >= 0:
			var entry: Dictionary = timeline_entries[index]
			for metadata_key: Variant in metadata.keys():
				entry[str(metadata_key)] = metadata[metadata_key]
			entry["content"] = detail_text
			entry["height_estimate"] = _estimate_timeline_entry_height("status", detail_text)
			entry["height_actual"] = 0.0
			timeline_entries[index] = entry
			_mark_timeline_height_dirty(index)

	var should_follow_bottom: bool = _should_follow_timeline_updates()
	_schedule_timeline_render(should_follow_bottom)


func _append_event_to_timeline(event_name: String, event_data: Dictionary, request_id: String) -> void:
	if event_name == "ai.thinking.delta":
		var delta_text: String = str(event_data.get("text", ""))
		if delta_text.is_empty():
			return

		if active_thinking_entry_id.is_empty():
			active_thinking_entry_id = _append_timeline_entry("thinking", request_id, "", "thinking:%s" % request_id)

		_update_timeline_entry_content(active_thinking_entry_id, _get_timeline_entry_content(active_thinking_entry_id) + delta_text)
	elif event_name == "ai.thinking.done":
		_set_timeline_entry_collapsed(active_thinking_entry_id, true)
		active_thinking_entry_id = ""
	elif event_name == "tool.call" or event_name == "tool.approval_required":
		_append_tool_event_to_timeline(event_data, request_id)
	elif event_name == "tool.result" or event_name == "tool.error" or event_name == "tool.approved" or event_name == "tool.rejected":
		_append_tool_event_to_timeline(event_data, request_id)


func _append_tool_event_to_timeline(event_data: Dictionary, request_id: String) -> String:
	var tool_call_id: String = _get_scoped_tool_call_key(event_data, request_id)
	var entry_id: String = active_tool_entry_ids_by_call_id.get(tool_call_id, "")

	if entry_id.is_empty():
		entry_id = _append_timeline_entry("tool", request_id, "", "tool:%s" % tool_call_id)
		active_tool_entry_ids_by_call_id[tool_call_id] = entry_id
		_set_timeline_entry_tool_call_id(entry_id, tool_call_id)

	var index: int = _find_timeline_entry_index(entry_id)
	if index >= 0:
		var entry: Dictionary = timeline_entries[index]
		var events: Array = entry.get("events", []) as Array
		var event_record_id: String = str(event_data.get("_eventRecordId", ""))
		if not event_record_id.is_empty():
			for existing_event_value: Variant in events:
				if typeof(existing_event_value) != TYPE_DICTIONARY:
					continue

				var existing_event: Dictionary = existing_event_value as Dictionary
				if str(existing_event.get("_eventRecordId", "")) == event_record_id:
					return entry_id

		events.append(event_data.duplicate(true))
		entry["events"] = events
		entry["height_estimate"] = _estimate_timeline_entry_height("tool", "")
		var event_type: String = str(event_data.get("type", ""))
		if event_type == "tool.result" or event_type == "tool.error":
			entry["collapsed"] = true
		timeline_entries[index] = entry
		_mark_timeline_height_dirty(index)

	return entry_id


func _set_timeline_entry_tool_call_id(entry_id: String, tool_call_id: String) -> void:
	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return

	var entry: Dictionary = timeline_entries[index]
	entry["tool_call_id"] = tool_call_id
	timeline_entries[index] = entry


func _set_timeline_entry_collapsed(entry_id: String, collapsed: bool) -> void:
	if entry_id.is_empty():
		return

	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return

	var entry: Dictionary = timeline_entries[index]
	entry["collapsed"] = collapsed
	timeline_entries[index] = entry
	_mark_timeline_height_dirty(index)


func _set_timeline_entry_times(entry_id: String, started_at_utc: String, completed_at_utc: String) -> void:
	if entry_id.is_empty():
		return

	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return

	var entry: Dictionary = timeline_entries[index]
	if not started_at_utc.strip_edges().is_empty():
		entry["started_at_utc"] = started_at_utc
	if not completed_at_utc.strip_edges().is_empty():
		entry["completed_at_utc"] = completed_at_utc
	timeline_entries[index] = entry
	_mark_timeline_height_dirty(index)


func _get_timeline_entry_content(entry_id: String) -> String:
	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return ""

	var entry: Dictionary = timeline_entries[index]
	return str(entry.get("content", ""))


func _update_timeline_entry_content(entry_id: String, content: String) -> void:
	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return

	var entry: Dictionary = timeline_entries[index]
	entry["content"] = content
	entry["height_estimate"] = _estimate_timeline_entry_height(str(entry.get("type", "")), content)
	entry["height_actual"] = 0.0
	timeline_entries[index] = entry
	_mark_timeline_height_dirty(index)


func _find_timeline_entry_index(entry_id: String) -> int:
	if entry_id.is_empty():
		return -1

	for index: int in range(timeline_entries.size()):
		var entry: Dictionary = timeline_entries[index]
		if str(entry.get("id", "")) == entry_id:
			return index

	return -1


func _rebuild_timeline_index_cache() -> void:
	timeline_entry_ids.clear()
	active_tool_entry_ids_by_call_id.clear()
	tool_items_by_call_id.clear()
	for index: int in range(timeline_entries.size()):
		var entry: Dictionary = timeline_entries[index]
		var entry_id: String = str(entry.get("id", ""))
		if not entry_id.is_empty():
			timeline_entry_ids[entry_id] = true

		var tool_call_id: String = str(entry.get("tool_call_id", ""))
		if not tool_call_id.is_empty():
			active_tool_entry_ids_by_call_id[tool_call_id] = entry_id


func _estimate_timeline_entry_height(entry_type: String, content: String) -> float:
	var line_count: int = max(1, content.count("\n") + 1)
	var text_rows: int = max(line_count, int(ceil(float(content.length()) / 72.0)))

	if entry_type == "user":
		return max(TIMELINE_ESTIMATED_USER_HEIGHT, 44.0 + float(text_rows * 20))
	if entry_type == "assistant":
		return max(TIMELINE_ESTIMATED_ASSISTANT_HEIGHT, 52.0 + float(text_rows * 22))
	if entry_type == "thinking":
		return TIMELINE_ESTIMATED_THINKING_HEIGHT
	if entry_type == "tool":
		return TIMELINE_ESTIMATED_TOOL_HEIGHT
	if entry_type == "status":
		return TIMELINE_ESTIMATED_STATUS_HEIGHT

	return 96.0


func _get_entry_cached_height(entry: Dictionary) -> float:
	var actual_height: float = float(entry.get("height_actual", 0.0))
	if actual_height > 0.0:
		return max(TIMELINE_MIN_ITEM_HEIGHT, actual_height)

	return max(TIMELINE_MIN_ITEM_HEIGHT, float(entry.get("height_estimate", TIMELINE_ESTIMATED_ASSISTANT_HEIGHT)))


func _mark_timeline_height_dirty(index: int = -1) -> void:
	if index >= 0 and index < timeline_entries.size() and index < timeline_heights.size():
		timeline_heights[index] = _get_entry_cached_height(timeline_entries[index])
	timeline_heights_dirty = true


func _rebuild_timeline_height_cache() -> void:
	timeline_heights.clear()
	timeline_prefix_heights.clear()

	var running_height: float = 0.0
	timeline_prefix_heights.append(0.0)
	for entry: Dictionary in timeline_entries:
		var entry_height: float = _get_entry_cached_height(entry)
		timeline_heights.append(entry_height)
		running_height += entry_height
		timeline_prefix_heights.append(running_height)

	timeline_heights_dirty = false


func _ensure_timeline_height_cache() -> void:
	if timeline_heights_dirty or timeline_heights.size() != timeline_entries.size() or timeline_prefix_heights.size() != timeline_entries.size() + 1:
		_rebuild_timeline_height_cache()


func _get_timeline_entry_height(index: int) -> float:
	if index < 0 or index >= timeline_entries.size():
		return 0.0

	_ensure_timeline_height_cache()
	return timeline_heights[index]


func _get_timeline_total_height() -> float:
	_ensure_timeline_height_cache()
	return timeline_prefix_heights[timeline_prefix_heights.size() - 1]


func _schedule_timeline_render(scroll_to_bottom: bool) -> void:
	timeline_scroll_to_bottom_queued = timeline_scroll_to_bottom_queued or scroll_to_bottom
	if timeline_render_queued:
		return

	timeline_render_queued = true
	_deferred_render_visible_timeline()


func _deferred_render_visible_timeline() -> void:
	await get_tree().process_frame
	var should_scroll_to_bottom: bool = timeline_scroll_to_bottom_queued
	timeline_render_queued = false
	timeline_scroll_to_bottom_queued = false
	_render_visible_timeline(should_scroll_to_bottom)


func _render_visible_timeline(scroll_to_bottom: bool) -> void:
	_setup_timeline_containers()

	if timeline_entries.is_empty():
		for child: Node in timeline_visible_container.get_children():
			child.queue_free()
		rendered_entry_nodes.clear()
		rendered_entry_indices.clear()
		timeline_top_spacer.custom_minimum_size = Vector2(0.0, 0.0)
		timeline_bottom_spacer.custom_minimum_size = Vector2(0.0, 0.0)
		return

	var viewport_height: float = max(1.0, scroll_container.size.y)
	var total_height: float = _get_timeline_total_height()
	var viewport_top: float = scroll_container.scroll_vertical
	if scroll_to_bottom:
		viewport_top = max(0.0, total_height - viewport_height)
		scroll_container.scroll_vertical = int(round(viewport_top))
		timeline_follow_bottom = true

	var viewport_bottom: float = viewport_top + viewport_height
	var first_index: int = _find_timeline_index_at_offset(viewport_top)
	var last_index: int = _find_timeline_index_at_offset(viewport_bottom)
	var start_index: int = maxi(0, first_index - TIMELINE_BUFFER_ITEMS)
	var end_index: int = mini(timeline_entries.size() - 1, last_index + TIMELINE_BUFFER_ITEMS)

	_sync_rendered_timeline_range(start_index, end_index)
	_update_timeline_spacers(start_index, end_index)
	_schedule_timeline_measure()

	if scroll_to_bottom:
		_scroll_timeline_to_bottom_deferred()


func _find_timeline_index_at_offset(offset: float) -> int:
	_ensure_timeline_height_cache()
	if timeline_entries.is_empty():
		return 0

	var low: int = 0
	var high: int = timeline_entries.size()
	while low < high:
		var mid: int = int((low + high) / 2)
		if timeline_prefix_heights[mid + 1] < offset:
			low = mid + 1
		else:
			high = mid

	return clampi(low, 0, timeline_entries.size() - 1)


func _sync_rendered_timeline_range(start_index: int, end_index: int) -> void:
	var wanted_ids: Dictionary[String, bool] = {}
	for index: int in range(start_index, end_index + 1):
		var entry: Dictionary = timeline_entries[index]
		var entry_id: String = str(entry.get("id", ""))
		wanted_ids[entry_id] = true
		if not rendered_entry_nodes.has(entry_id):
			var node: Node = _instantiate_timeline_entry_node(entry, index)
			rendered_entry_nodes[entry_id] = node
			rendered_entry_indices[entry_id] = index
			timeline_visible_container.add_child(node)
			_configure_timeline_entry_node(node, entry, index)
		else:
			rendered_entry_indices[entry_id] = index

	for entry_id: String in rendered_entry_nodes.keys():
		if wanted_ids.has(entry_id):
			continue

		var old_node: Node = rendered_entry_nodes.get(entry_id, null) as Node
		if old_node != null:
			old_node.queue_free()
		var old_index: int = int(rendered_entry_indices.get(entry_id, -1))
		if old_index >= 0 and old_index < timeline_entries.size():
			var old_entry: Dictionary = timeline_entries[old_index]
			var old_tool_call_id: String = str(old_entry.get("tool_call_id", ""))
			if not old_tool_call_id.is_empty() and tool_items_by_call_id.get(old_tool_call_id, null) == old_node:
				tool_items_by_call_id.erase(old_tool_call_id)
		if entry_id == active_assistant_entry_id:
			active_assistant_item = null
		if entry_id == active_thinking_entry_id:
			active_thinking_item = null
		rendered_entry_nodes.erase(entry_id)
		rendered_entry_indices.erase(entry_id)

	var child_order: int = 0
	for index: int in range(start_index, end_index + 1):
		var entry: Dictionary = timeline_entries[index]
		var entry_id: String = str(entry.get("id", ""))
		var node: Node = rendered_entry_nodes.get(entry_id, null) as Node
		if node != null:
			timeline_visible_container.move_child(node, child_order)
			child_order += 1


func _instantiate_timeline_entry_node(entry: Dictionary, index: int) -> Node:
	var entry_type: String = str(entry.get("type", ""))
	var node: Node

	if entry_type == "user":
		node = USER_MESSAGE_ITEM_SCENE.instantiate()
	elif entry_type == "assistant":
		node = ASSISTANT_MARKDOWN_ITEM_SCENE.instantiate()
	elif entry_type == "thinking":
		node = TOOL_CALL_ITEM_SCENE.instantiate()
	elif entry_type == "tool":
		node = TOOL_CALL_ITEM_SCENE.instantiate()
	elif entry_type == "status":
		node = STATUS_ITEM_SCENE.instantiate()
	else:
		node = ASSISTANT_MARKDOWN_ITEM_SCENE.instantiate()

	if node is Control:
		var control: Control = node as Control
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var entry_id: String = str(entry.get("id", ""))
	if entry_id == active_assistant_entry_id:
		active_assistant_item = node
	elif entry_id == active_thinking_entry_id:
		active_thinking_item = node

	rendered_entry_indices[entry_id] = index
	return node


func _configure_timeline_entry_node(node: Node, entry: Dictionary, _index: int) -> void:
	var entry_type: String = str(entry.get("type", ""))

	if entry_type == "user":
		node.call("setup", str(entry.get("content", "")), str(entry.get("request_id", "")), str(entry.get("sent_at_utc", "")))
		if node.has_signal("resend_requested"):
			node.connect("resend_requested", Callable(self, "_on_user_message_resend_requested"))
	elif entry_type == "assistant":
		node.call("setup", str(entry.get("content", "")), str(entry.get("started_at_utc", "")), str(entry.get("completed_at_utc", "")))
	elif entry_type == "thinking":
		node.call("setup_thinking")
		var content: String = str(entry.get("content", ""))
		if not content.is_empty():
			node.call("append_thinking_delta", content)
		if bool(entry.get("collapsed", true)):
			node.call("finish_thinking")
	elif entry_type == "tool":
		_setup_tool_node_from_entry(node, entry)
		var tool_call_id: String = str(entry.get("tool_call_id", ""))
		if not tool_call_id.is_empty():
			tool_items_by_call_id[tool_call_id] = node
	elif entry_type == "status":
		node.call(
			"setup",
			str(entry.get("status", "message")),
			str(entry.get("title", "")),
			str(entry.get("detail", "")),
			str(entry.get("action_label", "")),
			str(entry.get("action_id", ""))
		)
		if node.has_signal("action_requested") and not node.is_connected("action_requested", _on_status_item_action_requested):
			node.connect("action_requested", _on_status_item_action_requested)
	else:
		node.call("setup", str(entry.get("content", "")))

	var entry_id: String = str(entry.get("id", ""))
	if node.has_signal("content_height_changed") and not node.is_connected("content_height_changed", _on_timeline_node_content_height_changed):
		node.connect("content_height_changed", _on_timeline_node_content_height_changed.bind(entry_id))


func _setup_tool_node_from_entry(node: Node, entry: Dictionary) -> void:
	var events: Array = entry.get("events", []) as Array
	if events.is_empty():
		node.call("setup", "Tool", "")
		return

	for index: int in range(events.size()):
		var event_value: Variant = events[index]
		if typeof(event_value) != TYPE_DICTIONARY:
			continue

		var event_data: Dictionary = event_value as Dictionary
		if index == 0:
			node.call("setup_tool_event", event_data)
		else:
			node.call("append_tool_event", event_data)


func _on_timeline_node_content_height_changed(entry_id: String) -> void:
	var index: int = _find_timeline_entry_index(entry_id)
	if index >= 0:
		var entry: Dictionary = timeline_entries[index]
		entry["height_actual"] = 0.0
		timeline_entries[index] = entry
		_mark_timeline_height_dirty(index)
	_schedule_timeline_measure()


func _update_timeline_spacers(start_index: int, end_index: int) -> void:
	_ensure_timeline_height_cache()
	var top_height: float = timeline_prefix_heights[start_index]
	var bottom_height: float = timeline_prefix_heights[timeline_prefix_heights.size() - 1] - timeline_prefix_heights[end_index + 1]

	timeline_top_spacer.custom_minimum_size = Vector2(0.0, top_height)
	timeline_bottom_spacer.custom_minimum_size = Vector2(0.0, bottom_height)


func _schedule_timeline_measure() -> void:
	var now_msec: int = Time.get_ticks_msec()
	if timeline_measure_after_msec <= now_msec:
		timeline_measure_after_msec = now_msec + TIMELINE_MEASURE_INTERVAL_MSEC
	if timeline_measure_queued:
		return

	timeline_measure_queued = true
	_deferred_measure_timeline_items()


func _deferred_measure_timeline_items() -> void:
	await get_tree().process_frame
	var delay_msec: int = timeline_measure_after_msec - Time.get_ticks_msec()
	if delay_msec > 0:
		await get_tree().create_timer(float(delay_msec) / 1000.0).timeout
	timeline_measure_queued = false

	var changed: bool = false
	for entry_id: String in rendered_entry_nodes.keys():
		var node: Node = rendered_entry_nodes.get(entry_id, null) as Node
		if not (node is Control):
			continue

		var index: int = _find_timeline_entry_index(entry_id)
		if index < 0:
			continue

		var control: Control = node as Control
		var measured_height: float = max(TIMELINE_MIN_ITEM_HEIGHT, control.size.y)
		var entry: Dictionary = timeline_entries[index]
		var previous_height: float = float(entry.get("height_actual", 0.0))
		if abs(previous_height - measured_height) <= 1.0:
			continue

		entry["height_actual"] = measured_height
		timeline_entries[index] = entry
		_mark_timeline_height_dirty(index)
		changed = true

	if changed:
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		_rebuild_timeline_height_cache()
		_render_visible_timeline(should_follow_bottom)


func _scroll_timeline_to_bottom_deferred() -> void:
	if timeline_deferred_scroll_queued:
		return

	timeline_deferred_scroll_queued = true
	timeline_deferred_scroll_version += 1
	var scroll_version: int = timeline_deferred_scroll_version
	await get_tree().process_frame
	await get_tree().process_frame
	if scroll_version != timeline_deferred_scroll_version:
		return

	timeline_deferred_scroll_queued = false
	if not timeline_follow_bottom:
		return

	scroll_container.scroll_vertical = int(round(_get_timeline_bottom_scroll()))


func _is_timeline_near_bottom() -> bool:
	var bar: VScrollBar = scroll_container.get_v_scroll_bar()
	if bar == null:
		return true
	if not bar.is_visible_in_tree():
		return true

	return float(scroll_container.scroll_vertical) >= _get_timeline_bottom_scroll() - TIMELINE_BOTTOM_FOLLOW_THRESHOLD


func _get_timeline_bottom_scroll() -> float:
	var bar: VScrollBar = scroll_container.get_v_scroll_bar()
	if bar == null:
		return 0.0

	return max(0.0, bar.max_value - bar.page)


func _should_follow_timeline_updates() -> bool:
	return timeline_follow_bottom or _is_timeline_near_bottom()


func _scroll_to_bottom_if_following(should_follow_bottom: bool) -> void:
	if not should_follow_bottom:
		return

	timeline_follow_bottom = true
	_scroll_timeline_to_bottom_deferred()


func _add_user_message_item(message_text: String) -> void:
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var sent_at_utc: String = _get_utc_timestamp()
	if active_stream_started_at_utc.is_empty():
		active_stream_started_at_utc = sent_at_utc
	_append_timeline_entry("user", active_stream_request_id, message_text, "", { "sent_at_utc": sent_at_utc })
	_schedule_timeline_render(should_follow_bottom)


func _add_assistant_message_item(message_text: String) -> void:
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var completed_at_utc: String = _get_utc_timestamp()
	var metadata: Dictionary = { "completed_at_utc": completed_at_utc }
	if not active_stream_started_at_utc.is_empty():
		metadata["started_at_utc"] = active_stream_started_at_utc
	var entry_id: String = _append_timeline_entry("assistant", active_stream_request_id, message_text, "", metadata)
	active_assistant_entry_id = entry_id
	_schedule_timeline_render(should_follow_bottom)


func _ensure_active_assistant_item() -> void:
	if not active_assistant_entry_id.is_empty():
		active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node
		return

	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var metadata: Dictionary = {}
	if not active_stream_started_at_utc.is_empty():
		metadata["started_at_utc"] = active_stream_started_at_utc
	active_assistant_entry_id = _append_timeline_entry("assistant", active_stream_request_id, "", "", metadata)
	_schedule_timeline_render(should_follow_bottom)
	active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node


func _schedule_assistant_delta_flush() -> void:
	var now_msec: int = Time.get_ticks_msec()
	if pending_assistant_delta_flush_at_msec <= now_msec:
		pending_assistant_delta_flush_at_msec = now_msec + DELTA_FLUSH_INTERVAL_MSEC
	if pending_assistant_delta_queued:
		return

	pending_assistant_delta_queued = true
	_deferred_flush_pending_assistant_delta()


func _deferred_flush_pending_assistant_delta() -> void:
	var delay_msec: int = pending_assistant_delta_flush_at_msec - Time.get_ticks_msec()
	if delay_msec > 0:
		await get_tree().create_timer(float(delay_msec) / 1000.0).timeout
	pending_assistant_delta_queued = false
	pending_assistant_delta_flush_at_msec = 0
	_flush_pending_assistant_delta()


func _flush_pending_assistant_delta() -> void:
	if pending_assistant_delta_text.is_empty() or active_assistant_entry_id.is_empty():
		return

	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var delta_text: String = pending_assistant_delta_text
	pending_assistant_delta_text = ""
	var next_content: String = _get_timeline_entry_content(active_assistant_entry_id) + delta_text
	_update_timeline_entry_content(active_assistant_entry_id, next_content)

	active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node
	if active_assistant_item != null:
		active_assistant_item.call("append_delta", delta_text)

	_schedule_timeline_render(should_follow_bottom)


func _show_response_error(message: Dictionary) -> void:
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var error_value: Variant = message.get("error", {})
	var error_message: String = "Unknown backend error"
	if typeof(error_value) == TYPE_DICTIONARY:
		var error_dictionary: Dictionary = error_value as Dictionary
		error_message = str(error_dictionary.get("message", error_message))

	if active_assistant_item != null:
		active_assistant_item.call("append_delta", "\n\n后端返回错误：%s" % error_message)
		active_assistant_item.call("finish_message")
	elif not active_assistant_entry_id.is_empty():
		_update_timeline_entry_content(active_assistant_entry_id, _get_timeline_entry_content(active_assistant_entry_id) + "\n\n后端返回错误：%s" % error_message)
	else:
		_add_assistant_message_item("后端返回错误：%s" % error_message)

	_schedule_timeline_render(should_follow_bottom)
	_scroll_to_bottom_if_following(should_follow_bottom)


func _add_system_tool_item(title_text: String, detail_text: String) -> void:
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var entry_id: String = _append_timeline_entry("tool", active_stream_request_id, "")
	var index: int = _find_timeline_entry_index(entry_id)
	if index >= 0:
		var entry: Dictionary = timeline_entries[index]
		entry["events"] = [{
			"type": "tool.call",
			"title": title_text,
			"summary": detail_text,
			"toolCallId": entry_id,
			"toolName": title_text
		}]
		timeline_entries[index] = entry
	_schedule_timeline_render(should_follow_bottom)
	_scroll_to_bottom_if_following(should_follow_bottom)


func _add_tool_event(event_data: Dictionary) -> void:
	_show_background_context_viewer()
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	if active_assistant_item != null:
		active_assistant_item.call("finish_message")
		active_assistant_item = null
		active_assistant_entry_id = ""

	var tool_call_id: String = _get_scoped_tool_call_key(event_data, active_stream_request_id)
	var entry_id: String = _append_tool_event_to_timeline(event_data, active_stream_request_id)
	var item: Node = rendered_entry_nodes.get(entry_id, null) as Node
	if item != null:
		var entry_index: int = _find_timeline_entry_index(entry_id)
		if entry_index >= 0:
			_setup_tool_node_from_entry(item, timeline_entries[entry_index])
		tool_items_by_call_id[tool_call_id] = item

	_schedule_timeline_render(should_follow_bottom)
	_scroll_to_bottom_if_following(should_follow_bottom)


func _append_tool_event(event_data: Dictionary) -> void:
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var tool_call_id: String = _get_scoped_tool_call_key(event_data, active_stream_request_id)
	var entry_id: String = active_tool_entry_ids_by_call_id.get(tool_call_id, "")
	if entry_id.is_empty():
		_add_tool_event(event_data)
		return

	_append_tool_event_to_timeline(event_data, active_stream_request_id)
	var item: Node = rendered_entry_nodes.get(entry_id, null) as Node
	if item != null:
		item.call("append_tool_event", event_data)
		_scroll_to_bottom_if_following(should_follow_bottom)

	_schedule_timeline_render(should_follow_bottom)


func _append_thinking_event(delta_text: String) -> void:
	if delta_text.is_empty():
		return

	_show_background_context_viewer()
	if active_thinking_entry_id.is_empty():
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		active_thinking_entry_id = _append_timeline_entry("thinking", active_stream_request_id, "", "thinking:%s" % active_stream_request_id)
		_schedule_timeline_render(should_follow_bottom)

	pending_thinking_delta_text += delta_text
	_schedule_thinking_delta_flush()


func _schedule_thinking_delta_flush() -> void:
	var now_msec: int = Time.get_ticks_msec()
	if pending_thinking_delta_flush_at_msec <= now_msec:
		pending_thinking_delta_flush_at_msec = now_msec + DELTA_FLUSH_INTERVAL_MSEC
	if pending_thinking_delta_queued:
		return

	pending_thinking_delta_queued = true
	_deferred_flush_pending_thinking_delta()


func _deferred_flush_pending_thinking_delta() -> void:
	var delay_msec: int = pending_thinking_delta_flush_at_msec - Time.get_ticks_msec()
	if delay_msec > 0:
		await get_tree().create_timer(float(delay_msec) / 1000.0).timeout
	pending_thinking_delta_queued = false
	pending_thinking_delta_flush_at_msec = 0
	_flush_pending_thinking_delta()


func _flush_pending_thinking_delta() -> void:
	if pending_thinking_delta_text.is_empty() or active_thinking_entry_id.is_empty():
		return

	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var delta_text: String = pending_thinking_delta_text
	pending_thinking_delta_text = ""
	_update_timeline_entry_content(active_thinking_entry_id, _get_timeline_entry_content(active_thinking_entry_id) + delta_text)
	active_thinking_item = rendered_entry_nodes.get(active_thinking_entry_id, null) as Node
	if active_thinking_item != null:
		active_thinking_item.call("append_thinking_delta", delta_text)

	_schedule_timeline_measure()
	if should_follow_bottom:
		timeline_follow_bottom = true
		_scroll_timeline_to_bottom_deferred()


func _get_tool_call_key(event_data: Dictionary) -> String:
	var tool_call_id: String = str(event_data.get("toolCallId", ""))
	if not tool_call_id.is_empty():
		return tool_call_id

	var approval_id: String = str(event_data.get("approvalId", ""))
	if not approval_id.is_empty():
		return approval_id

	return "%s-%s" % [str(event_data.get("toolName", "tool")), str(event_data.get("step", 0))]


func _get_scoped_tool_call_key(event_data: Dictionary, request_id: String) -> String:
	var base_key: String = _get_tool_call_key(event_data)
	if request_id.is_empty():
		return base_key

	return "%s:%s" % [request_id, base_key]


func _show_approval_dialog(event_data: Dictionary) -> void:
	_show_background_context_viewer()
	var next_approval_id: String = str(event_data.get("approvalId", ""))
	if approval_dialog.visible and next_approval_id == pending_approval_id and not event_data.has("args"):
		return

	pending_approval_id = next_approval_id
	var tool_name: String = str(event_data.get("toolName", event_data.get("llmToolName", "")))
	approval_title_label.text = "需要审批：%s" % _localize_tool_name_for_display(tool_name)
	approval_description_label.text = "\n".join([
		"审批 ID：`%s`" % pending_approval_id,
		"原因：%s" % str(event_data.get("reason", "")),
		"参数：",
		_format_approval_args_preview(event_data.get("args", {}))
	])
	approval_dialog.visible = true


func _show_first_pending_approval(result_dictionary: Dictionary) -> void:
	var pending_value: Variant = result_dictionary.get("pending", [])
	if typeof(pending_value) != TYPE_ARRAY:
		return

	var pending_items: Array = pending_value as Array
	if pending_items.is_empty():
		if not pending_approval_id.is_empty():
			pending_approval_id = ""
			approval_dialog.visible = false
		return

	var first_pending_value: Variant = pending_items[0]
	if typeof(first_pending_value) != TYPE_DICTIONARY:
		return

	var pending_data: Dictionary = (first_pending_value as Dictionary).duplicate(true)
	if not pending_data.has("toolName"):
		pending_data["toolName"] = str(pending_data.get("llmToolName", ""))
	_show_approval_dialog(pending_data)


func _format_approval_args_preview(args_value: Variant) -> String:
	var args_text: String = JSON.stringify(args_value, "\t")
	if args_text.length() <= APPROVAL_ARGS_PREVIEW_LIMIT:
		return args_text

	return "%s\n\n... 已截断显示，完整参数保存在后端审批队列中，批准时仍会执行完整内容。" % args_text.substr(0, APPROVAL_ARGS_PREVIEW_LIMIT)


func _localize_tool_name_for_display(raw_tool_name: String) -> String:
	match raw_tool_name:
		"mcp_godot_read_text_file", "read_text_file":
			return "读取文件"
		"mcp_godot_search_text", "search_text":
			return "搜索文本"
		"mcp_godot_create_text_file", "mcp_godot_propose_create_text_file", "create_text_file":
			return "创建文件"
		"mcp_godot_overwrite_text_file", "mcp_godot_propose_overwrite_text_file", "overwrite_text_file":
			return "覆盖文件"
		"mcp_godot_replace_text_in_file", "mcp_godot_propose_replace_text_in_file", "replace_text_in_file":
			return "替换文件内容"
		"mcp_godot_delete_file", "delete_file":
			return "删除文件"
		"mcp_godot_inspect_scene_tree", "inspect_scene_tree":
			return "查看场景树"
		"mcp_godot_create_scene", "mcp_godot_propose_create_scene", "create_scene":
			return "创建场景"
		"mcp_godot_add_node_to_scene", "mcp_godot_propose_add_node_to_scene", "add_node_to_scene":
			return "添加场景节点"
		"mcp_godot_attach_script_to_node", "mcp_godot_propose_attach_script_to_node", "attach_script_to_node":
			return "挂载脚本"
		"mcp_godot_connect_signal_in_scene", "mcp_godot_propose_connect_signal_in_scene", "connect_signal_in_scene":
			return "连接信号"
		"mcp_godot_apply_scene_patch", "mcp_godot_propose_apply_scene_patch", "apply_scene_patch":
			return "批量编辑场景"
		"mcp_terminal_run_safe_preset", "run_safe_preset":
			return "运行验证命令"
		"mcp_terminal_run_write_preset", "run_write_preset":
			return "运行写入命令"
		"mcp_terminal_run_godot_scene_script", "run_godot_scene_script":
			return "执行场景脚本"

	if raw_tool_name.begins_with("mcp_"):
		return "内部工具"

	return raw_tool_name


func _update_context_length(info: Dictionary) -> void:
	latest_context_info = info.duplicate(true)
	var context_window_tokens: int = int(info.get("contextWindowTokens", 0))
	var history_tokens_stored: int = int(info.get("historyTokensStored", 0))

	if context_window_tokens <= 0:
		_set_context_length_icon(0.0, true)
		return

	var ratio: float = float(history_tokens_stored) / float(context_window_tokens)
	_set_context_length_icon(ratio, history_tokens_stored <= 0, history_tokens_stored, context_window_tokens)

	if context_popup_menu != null and is_instance_valid(context_popup_menu) and context_popup_menu.visible:
		context_popup_menu.call("setup", latest_context_info)


func _set_context_length_icon(ratio: float, is_empty: bool, history_tokens_stored: int = 0, context_window_tokens: int = 0) -> void:
	var icon_path: String = "%s/empty_context_length.svg" % CONTEXT_ICON_DIR

	if not is_empty:
		var level: int = int(ceil(ratio / 0.12))
		level = clampi(level, 1, 8)
		icon_path = "%s/context_length%d.svg" % [CONTEXT_ICON_DIR, level]

	var texture: Texture2D = load(icon_path) as Texture2D
	if texture != null:
		context_length_button.icon = texture

	if ratio >= 0.96:
		context_length_button.tooltip_text = "Context usage: %s (%s / %s). The context might be too long, it's suggested to condense the conversation." % [
			_format_context_usage_percent(ratio),
			_format_compact_token_count(history_tokens_stored),
			_format_compact_token_count(context_window_tokens)
		]
	elif is_empty:
		if context_window_tokens > 0:
			context_length_button.tooltip_text = "Context usage: 0%% (%s / %s)" % [
				_format_compact_token_count(history_tokens_stored),
				_format_compact_token_count(context_window_tokens)
			]
		else:
			context_length_button.tooltip_text = "Context usage: 0%"
	else:
		context_length_button.tooltip_text = "Context usage: %s (%s / %s)" % [
			_format_context_usage_percent(ratio),
			_format_compact_token_count(history_tokens_stored),
			_format_compact_token_count(context_window_tokens)
		]


func _format_context_usage_percent(ratio: float) -> String:
	var percent: float = ratio * 100.0
	if percent > 0.0 and percent < 0.01:
		return "<0.01%"
	if percent < 1.0:
		return "%.2f%%" % percent
	if percent < 10.0:
		return "%.1f%%" % percent

	return "%d%%" % int(round(percent))


func _format_compact_token_count(token_count: int) -> String:
	var absolute_count: int = absi(token_count)
	if absolute_count >= 1000000:
		return "%.1fM" % (float(token_count) / 1000000.0)
	if absolute_count >= 1000:
		return "%.1fk" % (float(token_count) / 1000.0)

	return str(token_count)


func _on_context_length_button_pressed() -> void:
	context_popup_open_after_info = false
	if not latest_context_info.is_empty():
		_show_context_popup_menu()

	if _is_socket_open() and not active_session_id.is_empty():
		context_popup_open_after_info = true
		var context_info_request_id: String = _send_request("session.info", {}, "context-popup-info")
		if context_info_request_id.is_empty():
			context_popup_open_after_info = false


func _show_context_popup_menu() -> void:
	var popup_menu: PopupPanel = _get_context_popup_menu()
	if popup_menu == null:
		return

	popup_menu.call("setup", latest_context_info)
	var popup_size: Vector2i = Vector2i(380, 390)
	var button_rect: Rect2 = context_length_button.get_global_rect()
	var viewport_size: Vector2 = get_viewport_rect().size
	var popup_x_max: int = max(4, int(viewport_size.x) - popup_size.x - 4)
	var popup_y_max: int = max(4, int(viewport_size.y) - popup_size.y - 4)
	var popup_x: int = int(round(button_rect.position.x + button_rect.size.x - float(popup_size.x)))
	var popup_y: int = int(round(button_rect.position.y - float(popup_size.y) - 8.0))

	if popup_y < 4:
		popup_y = int(round(button_rect.position.y + button_rect.size.y + 8.0))

	popup_x = clampi(popup_x, 4, popup_x_max)
	popup_y = clampi(popup_y, 4, popup_y_max)
	popup_menu.popup(Rect2i(Vector2i(popup_x, popup_y), popup_size))


func _get_context_popup_menu() -> PopupPanel:
	if context_popup_menu != null and is_instance_valid(context_popup_menu):
		return context_popup_menu

	var packed_scene: PackedScene = load(CONTEXT_POPUP_MENU_UID) as PackedScene
	if packed_scene == null:
		return null

	var next_context_popup_menu: PopupPanel = packed_scene.instantiate() as PopupPanel
	if next_context_popup_menu == null:
		return null

	context_popup_menu = next_context_popup_menu
	add_child(context_popup_menu)
	return context_popup_menu


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
	active_workflow_id = ""
	workflow_todo_nodes_by_id.clear()
	workflow_phase_nodes_by_id.clear()
	todo_list.hide()
	for child: Node in todo_container.get_children():
		child.queue_free()


func _apply_workflow_todo_snapshot(snapshot: Dictionary) -> void:
	var workflow_id: String = str(snapshot.get("workflowId", ""))
	if not workflow_id.is_empty():
		active_workflow_id = workflow_id

	var phases_value: Variant = snapshot.get("phases", [])
	if typeof(phases_value) != TYPE_ARRAY:
		return

	var signature: String = JSON.stringify(phases_value)
	if signature == last_todo_signature:
		return

	last_todo_signature = signature
	var wanted_node_ids: Dictionary[String, bool] = {}
	var phases: Array = phases_value as Array
	for phase_value: Variant in phases:
		if typeof(phase_value) != TYPE_DICTIONARY:
			continue

		var phase: Dictionary = phase_value as Dictionary
		var phase_id: String = str(phase.get("id", ""))
		var phase_node_id: String = "phase:%s" % phase_id
		var phase_status: String = str(phase.get("status", "pending"))
		var phase_item: Node = workflow_phase_nodes_by_id.get(phase_id, null) as Node
		if phase_item == null:
			phase_item = TODO_ITEM_SCENE.instantiate()
			workflow_phase_nodes_by_id[phase_id] = phase_item
			todo_container.add_child(phase_item)

		phase_item.call("setup_status", str(phase.get("title", phase_id)), phase_status)
		wanted_node_ids[phase_node_id] = true

	for phase_id: String in workflow_phase_nodes_by_id.keys():
		if wanted_node_ids.has("phase:%s" % phase_id):
			continue

		var old_phase_item: Node = workflow_phase_nodes_by_id.get(phase_id, null) as Node
		if old_phase_item != null:
			old_phase_item.queue_free()
		workflow_phase_nodes_by_id.erase(phase_id)

	for todo_id: String in workflow_todo_nodes_by_id.keys():
		var old_todo_item: Node = workflow_todo_nodes_by_id.get(todo_id, null) as Node
		if old_todo_item != null:
			old_todo_item.queue_free()
		workflow_todo_nodes_by_id.erase(todo_id)

	todo_list.show()


func _workflow_status_prefix(status: String) -> String:
	if status == "done":
		return "[x]"
	if status == "running":
		return "[~]"
	if status == "failed":
		return "[!]"
	if status == "paused":
		return "[pause]"

	return "[ ]"


func _workflow_status_color(status: String) -> Color:
	if status == "running":
		return Color(0.7, 0.86, 1.0, 1.0)
	if status == "done":
		return Color(0.72, 1.0, 0.76, 1.0)
	if status == "failed":
		return Color(1.0, 0.55, 0.55, 1.0)
	if status == "paused":
		return Color(1.0, 0.88, 0.48, 1.0)

	return Color(0.86, 0.86, 0.86, 1.0)


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
		var todo_item: Node = TODO_ITEM_SCENE.instantiate()
		var todo_status: String = "done" if bool(todo.get("checked", false)) else "pending"
		todo_container.add_child(todo_item)
		todo_item.call("setup_status", str(todo.get("text", "")), todo_status)

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
	active_settings_menu = settings_menu
	add_child(settings_menu)
	settings_menu.call("setup_provider_config", provider_config_status, _get_frontend_config_snapshot())
	settings_menu.call("setup_archived_sessions", _get_archived_sessions_snapshot(), _get_workspace_snapshot())
	settings_menu.connect("provider_config_save_requested", Callable(self, "_on_settings_provider_config_save_requested"))
	settings_menu.connect("provider_config_clear_requested", Callable(self, "_on_settings_provider_config_clear_requested"))
	settings_menu.connect("frontend_config_save_requested", Callable(self, "_on_settings_frontend_config_save_requested"))
	settings_menu.connect("archived_session_restore_requested", Callable(self, "_on_settings_archived_session_restore_requested"))
	settings_menu.connect("archived_session_delete_requested", Callable(self, "_on_settings_archived_session_delete_requested"))
	settings_menu.tree_exited.connect(_on_settings_menu_tree_exited.bind(settings_menu))
	_send_request("session.archived.list", {}, "session-archived-list")


func _get_frontend_config_snapshot() -> Dictionary:
	return {
		"backendUrl": backend_url,
		"model": _get_selected_model_id(),
		"approvalMode": _get_selected_approval_mode(),
		"customInstructions": custom_instructions
	}


func _get_archived_sessions_snapshot() -> Array[Dictionary]:
	var archived_sessions: Array[Dictionary] = []
	for session_id: String in archived_session_ids_in_order:
		var metadata: Dictionary = archived_sessions_by_id.get(session_id, {}) as Dictionary
		if metadata.is_empty():
			continue

		archived_sessions.append(metadata.duplicate(true))

	return archived_sessions


func _get_workspace_snapshot() -> Array[Dictionary]:
	var workspaces: Array[Dictionary] = []
	for workspace_id: String in workspaces_by_id.keys():
		var workspace: Dictionary = workspaces_by_id.get(workspace_id, {}) as Dictionary
		if workspace.is_empty():
			continue

		workspaces.append(workspace.duplicate(true))

	return workspaces


func _sync_settings_archived_sessions() -> void:
	if active_settings_menu == null or not is_instance_valid(active_settings_menu):
		return

	active_settings_menu.call(
		"setup_archived_sessions",
		_get_archived_sessions_snapshot(),
		_get_workspace_snapshot()
	)


func _on_settings_menu_tree_exited(settings_menu: Node) -> void:
	if active_settings_menu == settings_menu:
		active_settings_menu = null


func _on_settings_archived_session_restore_requested(session_id: String) -> void:
	if not _is_socket_open() or session_id.is_empty():
		return

	_send_request("session.archived.restore", { "sessionId": session_id }, "session-archived-restore")


func _on_settings_archived_session_delete_requested(session_id: String) -> void:
	if not _is_socket_open() or session_id.is_empty():
		return

	_send_request("session.archived.delete", { "sessionId": session_id }, "session-archived-delete")


func _on_settings_provider_config_save_requested(api_key: String) -> void:
	if not _is_socket_open():
		pending_provider_config_api_key = api_key
		pending_provider_config_save_after_connect = true
		return

	_save_provider_config_to_backend(api_key)


func _save_provider_config_to_backend(api_key: String) -> void:
	var params: Dictionary[String, Variant] = {
		"provider": "deepseek",
		"model": _get_selected_model_id()
	}

	if not api_key.strip_edges().is_empty():
		params["apiKey"] = api_key.strip_edges()

	_send_request("provider.config.set", params, "provider-config-set")


func _on_settings_provider_config_clear_requested() -> void:
	_send_request("provider.config.clear", {}, "provider-config-clear")


func _on_settings_frontend_config_save_requested(
	next_backend_url: String,
	next_custom_instructions: String
) -> void:
	var normalized_backend_url: String = _normalize_backend_url(next_backend_url)
	var backend_url_changed: bool = normalized_backend_url != backend_url
	backend_url = normalized_backend_url
	custom_instructions = next_custom_instructions.strip_edges()
	_save_frontend_setting(CONFIG_BACKEND_URL_SETTING, backend_url)
	_save_frontend_setting(CONFIG_CUSTOM_INSTRUCTIONS_SETTING, custom_instructions)

	if backend_url_changed:
		_restart_backend_connection()


func _restart_backend_connection(recovery_mode: bool = false) -> void:
	context_popup_open_after_info = false
	socket_ready = false
	is_connecting = false
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close()
	_start_backend_connection_attempts(not recovery_mode, recovery_mode)


func _exit_tree() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close()
