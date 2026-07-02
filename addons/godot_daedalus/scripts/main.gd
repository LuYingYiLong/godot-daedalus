@tool
extends VBoxContainer

const DEFAULT_BACKEND_URL: String = "ws://localhost:8080"
const USER_MESSAGE_ITEM_SCENE: PackedScene = preload("uid://c0qgg77075lmq")
const ASSISTANT_MARKDOWN_ITEM_SCENE: PackedScene = preload("uid://c3s4jlxtm21ci")
const TOOL_CALL_ITEM_SCENE: PackedScene = preload("uid://c2a5o7qi58fus")
const STATUS_ITEM_SCENE: PackedScene = preload("uid://cljnln76ye4o5")
const SESSION_ITEM_SCENE: PackedScene = preload("uid://bic1etsxo1epd")
const TODO_ITEM_SCENE: PackedScene = preload("uid://d3i7c6i2shbyl")
const ADDITIONAL_CONTEXT_ITEM_SCENE: PackedScene = preload("uid://rfwvgjocqqva")
const CONTEXT_POPUP_MENU_UID: String = "uid://brjsrkaconcvu"
const CONTEXT_ICON_DIR: String = "res://addons/godot_daedalus/assets/icons"
const CONFIG_BACKEND_URL_SETTING: String = "godot_daedalus/backend_url"
const CONFIG_MODEL_ID_SETTING: String = "godot_daedalus/model_id"
const CONFIG_APPROVAL_MODE_SETTING: String = "godot_daedalus/approval_mode"
const CONFIG_CUSTOM_INSTRUCTIONS_SETTING: String = "godot_daedalus/custom_instructions"
const CONFIG_NEXT_STEP_HINTS_SETTING: String = "godot_daedalus/next_step_hints_enabled"
const CONNECTED_ICON: Texture2D = preload("uid://1eh7wxaewfje")
const CONNECT_FAILED_ICON: Texture2D = preload("uid://chihcwe7t0f2g")
const DISCONNECTED_ICON: Texture2D = preload("uid://cq15q550jtb21")
const STAUTS_WARNING: Texture2D = preload("uid://gytxgaev43it")
const GUIDE_NOW_ICON: Texture2D = preload("uid://3dsfgra6pd2m")
const EDIT_ICON: Texture2D = preload("uid://pj7m0o4eos6a")
const DELETE_ICON: Texture2D = preload("uid://qpmvpq6q2q60")
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
const MAX_QUEUED_MESSAGES: int = 12
const MESSAGE_QUEUE_STATUS_PENDING: StringName = &"pending"
const MESSAGE_QUEUE_STATUS_SENDING: StringName = &"sending"
const MESSAGE_QUEUE_STATUS_APPROVAL: StringName = &"approval"
const MESSAGE_QUEUE_STATUS_FAILED: StringName = &"failed"
const MESSAGE_QUEUE_STATUS_CANCELLED: StringName = &"cancelled"
const MESSAGE_QUEUE_STATUS_REJECTED: StringName = &"rejected"
const GUIDE_STATUS_DRAFT: StringName = &"draft"
const GUIDE_STATUS_SUBMITTING: StringName = &"submitting"
const GUIDE_STATUS_PENDING: StringName = &"pending"
const GUIDE_STATUS_DELETING: StringName = &"deleting"
const GUIDE_STATUS_APPLIED: StringName = &"applied"
const GUIDE_STATUS_FAILED: StringName = &"failed"
const MESSAGE_TREE_STATUS_COLUMN: int = 0
const MESSAGE_TREE_MESSAGE_COLUMN: int = 1
const MESSAGE_TREE_ACTIONS_COLUMN: int = 2
const MESSAGE_TREE_BUTTON_GUIDE_NOW: int = 1
const MESSAGE_TREE_BUTTON_EDIT: int = 2
const MESSAGE_TREE_BUTTON_DELETE: int = 3
const NEXT_STEP_HINT_ACTION_PREFIX: String = "next-step-hint:"
const ADD_CONTEXT_SELECTED_NODES_ID: int = 1
const ADD_CONTEXT_ACTIVE_SCENE_ID: int = 2
const ADD_CONTEXT_FILE_ID: int = 3
const ADD_CONTEXT_FOLDER_ID: int = 4
const ADD_CONTEXT_SCRIPT_SELECTION_ID: int = 5
const ADD_CONTEXT_FILESYSTEM_SELECTION_ID: int = 6
const ADD_CONTEXT_CLEAR_UNPINNED_ID: int = 7
const LIVE_EDITOR_SELECTION_CONTEXT_ID: String = "editor-selection-live"
const LIVE_SCRIPT_SELECTION_CONTEXT_ID: String = "script-selection-live"
const LIVE_FILESYSTEM_SELECTION_CONTEXT_ID: String = "filesystem-selection-live"
const SCRIPT_SELECTION_PREVIEW_LIMIT: int = 2000
const SCRIPT_LINE_PREVIEW_LIMIT: int = 500
const FILESYSTEM_CONTEXT_MAX_PATHS: int = 40
const EDITOR_CONTEXT_POLL_INTERVAL_MSEC: int = 500

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
@onready var message_queue_panel: PanelContainer = %MessageQueue
@onready var message_tree: Tree = %MessageTree
@onready var additional_context_viewer: ScrollContainer = %AdditionalContextViewer
@onready var additional_context_container: HBoxContainer = %AdditionalContextContainer
@onready var add_context_button: MenuButton = %AddContextButton

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
var pending_chat_additional_context: Array[Dictionary] = []
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
var next_step_hints_enabled: bool
var pending_provider_config_api_key: String
var pending_provider_config_save_after_connect: bool
var queued_messages: Array[Dictionary] = []
var message_queue_next_id: int
var active_queue_message_id: int
var manual_guides: Array[Dictionary] = []
var manual_guide_next_id: int
var editing_guide_local_id: String
var next_step_hint_request_id: String
var next_step_hint_anchor_request_id: String
var next_step_hint_entry_ids: Array[String] = []
var next_step_hints_by_action_id: Dictionary[String, String] = {}
var editor_plugin: EditorPlugin
var editor_interface: EditorInterface
var editor_selection: EditorSelection
var editor_undo_redo: EditorUndoRedoManager
var editor_script_editor: Object
var editor_context_update_queued: bool
var editor_context_next_poll_msec: int
var additional_context_items: Array[Dictionary] = []
var additional_context_next_id: int
var dismissed_live_context_signatures: Dictionary[String, String] = {}


func _ready() -> void:
	session_list_viewer.hide()
	background_context_viewer.hide()
	text_edit.hide()
	boot_splash.show()
	_setup_options()
	_load_frontend_config()
	_setup_timeline_containers()
	_connect_timeline_signals()
	_setup_message_tree()
	_setup_add_context_menu()
	_render_message_panel()
	_clear_template_items()
	_render_additional_context_items()
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
	_poll_live_editor_context()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if not text_edit.has_focus():
		return

	if event.keycode == KEY_ENTER:
		if event.shift_pressed:
			return
		if event.ctrl_pressed:
			_create_or_update_manual_guide_from_text_edit()
			accept_event()
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
	_ensure_frontend_setting(editor_settings, CONFIG_NEXT_STEP_HINTS_SETTING, false)

	backend_url = _normalize_backend_url(str(editor_settings.get_setting(CONFIG_BACKEND_URL_SETTING)))
	custom_instructions = str(editor_settings.get_setting(CONFIG_CUSTOM_INSTRUCTIONS_SETTING)).strip_edges()
	next_step_hints_enabled = bool(editor_settings.get_setting(CONFIG_NEXT_STEP_HINTS_SETTING))
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
	if additional_context_container == null:
		return

	for child: Node in additional_context_container.get_children():
		child.queue_free()


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


func _setup_message_tree() -> void:
	message_tree.columns = 3
	message_tree.column_titles_visible = true
	message_tree.hide_root = true
	message_tree.set_column_title(MESSAGE_TREE_STATUS_COLUMN, "Status")
	message_tree.set_column_title(MESSAGE_TREE_MESSAGE_COLUMN, "Message")
	message_tree.set_column_title(MESSAGE_TREE_ACTIONS_COLUMN, "Actions")
	message_tree.set_column_expand(MESSAGE_TREE_STATUS_COLUMN, false)
	message_tree.set_column_expand(MESSAGE_TREE_MESSAGE_COLUMN, true)
	message_tree.set_column_expand(MESSAGE_TREE_ACTIONS_COLUMN, false)
	message_tree.set_column_custom_minimum_width(MESSAGE_TREE_STATUS_COLUMN, 82)
	message_tree.set_column_custom_minimum_width(MESSAGE_TREE_ACTIONS_COLUMN, 72)
	if not message_tree.button_clicked.is_connected(_on_message_tree_button_clicked):
		message_tree.button_clicked.connect(_on_message_tree_button_clicked)


func _setup_add_context_menu() -> void:
	if add_context_button == null:
		return

	add_context_button.tooltip_text = "添加当前编辑器或项目上下文到下一条消息"
	var popup_menu: PopupMenu = add_context_button.get_popup()
	popup_menu.clear()
	popup_menu.add_item("添加选中节点", ADD_CONTEXT_SELECTED_NODES_ID)
	popup_menu.add_item("添加当前场景", ADD_CONTEXT_ACTIVE_SCENE_ID)
	popup_menu.add_item("添加当前脚本选区", ADD_CONTEXT_SCRIPT_SELECTION_ID)
	popup_menu.add_item("添加文件系统选中项", ADD_CONTEXT_FILESYSTEM_SELECTION_ID)
	popup_menu.add_separator()
	popup_menu.add_item("添加文件", ADD_CONTEXT_FILE_ID)
	popup_menu.add_item("添加文件夹", ADD_CONTEXT_FOLDER_ID)
	popup_menu.add_separator()
	popup_menu.add_item("清除未固定上下文", ADD_CONTEXT_CLEAR_UNPINNED_ID)
	if not popup_menu.id_pressed.is_connected(_on_add_context_menu_id_pressed):
		popup_menu.id_pressed.connect(_on_add_context_menu_id_pressed)


func _on_add_context_menu_id_pressed(menu_id: int) -> void:
	if menu_id == ADD_CONTEXT_SELECTED_NODES_ID:
		_add_selected_nodes_context()
	elif menu_id == ADD_CONTEXT_ACTIVE_SCENE_ID:
		_add_active_scene_context()
	elif menu_id == ADD_CONTEXT_SCRIPT_SELECTION_ID:
		_add_current_script_selection_context()
	elif menu_id == ADD_CONTEXT_FILESYSTEM_SELECTION_ID:
		_add_filesystem_selection_context()
	elif menu_id == ADD_CONTEXT_FILE_ID:
		_show_add_context_resource_dialog(EditorFileDialog.FILE_MODE_OPEN_FILE, "file")
	elif menu_id == ADD_CONTEXT_FOLDER_ID:
		_show_add_context_resource_dialog(EditorFileDialog.FILE_MODE_OPEN_DIR, "folder")
	elif menu_id == ADD_CONTEXT_CLEAR_UNPINNED_ID:
		_clear_unpinned_additional_context_items()


func _show_add_context_resource_dialog(file_mode: int, context_kind: String) -> void:
	var resource_dialog: EditorFileDialog = EditorFileDialog.new()
	resource_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	resource_dialog.file_mode = file_mode
	resource_dialog.title = "添加上下文"
	resource_dialog.size = Vector2i(720, 480)
	add_child(resource_dialog)

	if context_kind == "folder":
		resource_dialog.dir_selected.connect(_on_add_context_resource_selected.bind(context_kind, resource_dialog))
	else:
		resource_dialog.file_selected.connect(_on_add_context_resource_selected.bind(context_kind, resource_dialog))
	resource_dialog.canceled.connect(resource_dialog.queue_free)
	resource_dialog.popup_centered_ratio(0.7)


func _on_add_context_resource_selected(resource_path: String, context_kind: String, resource_dialog: EditorFileDialog) -> void:
	if resource_dialog != null and is_instance_valid(resource_dialog):
		resource_dialog.queue_free()

	var normalized_path: String = resource_path.strip_edges()
	if normalized_path.is_empty():
		return

	var context: Dictionary = {
		"id": _make_additional_context_id(context_kind, normalized_path, ""),
		"kind": context_kind,
		"title": normalized_path.get_file() if context_kind != "folder" else normalized_path.trim_suffix("/").get_file(),
		"subtitle": normalized_path,
		"pinned": false,
		"source": "manual",
		"resourcePath": normalized_path,
		"summary": "用户为本轮消息附加了项目 %s 引用；仅在需要时通过 MCP 读取内容。" % context_kind
	}
	_add_or_replace_additional_context(context)


func _add_selected_nodes_context() -> void:
	if editor_selection == null:
		_upsert_connection_status_entry("warning", "编辑器上下文不可用", "当前 Dock 没有获得 Godot EditorSelection。")
		return

	var edited_root: Node = _get_edited_scene_root()
	if edited_root == null:
		_upsert_connection_status_entry("warning", "没有打开场景", "请先在编辑器中打开一个场景。")
		return

	var selected_nodes: Array[Node] = editor_selection.get_selected_nodes()
	if selected_nodes.is_empty():
		_upsert_connection_status_entry("warning", "没有选中节点", "请先在场景树中选择一个或多个节点。")
		return

	for selected_node: Node in selected_nodes:
		if selected_node == null:
			continue
		_add_or_replace_additional_context(_create_node_additional_context(selected_node, edited_root))


func _add_active_scene_context() -> void:
	var edited_root: Node = _get_edited_scene_root()
	if edited_root == null:
		_upsert_connection_status_entry("warning", "没有打开场景", "请先在编辑器中打开一个场景。")
		return

	var scene_path: String = _get_scene_resource_path(edited_root)
	var scene_title: String = scene_path.get_file() if not scene_path.is_empty() else edited_root.name
	var context: Dictionary = {
		"id": _make_additional_context_id("scene", scene_path, "."),
		"kind": "scene",
		"title": scene_title,
		"subtitle": "Active scene",
		"pinned": false,
		"source": "editor",
		"resourcePath": scene_path,
		"nodePath": ".",
		"nodeType": edited_root.get_class(),
		"summary": "Current open Godot editor scene.",
		"data": _serialize_editor_node_summary(edited_root, edited_root)
	}
	_add_or_replace_additional_context(context)


func _add_current_script_selection_context() -> void:
	var context: Dictionary = _collect_script_selection_context()
	if context.is_empty():
		_upsert_connection_status_entry("warning", "没有脚本选区", "请先在 Godot 脚本编辑器中打开脚本，或把光标放到目标行。")
		return

	context["id"] = _make_additional_context_id(
		"script_selection",
		str(context.get("resourcePath", "")),
		_make_script_selection_context_key(context)
	)
	context["pinned"] = false
	_add_or_replace_additional_context(context)


func _add_filesystem_selection_context() -> void:
	var context: Dictionary = _collect_filesystem_selection_context()
	if context.is_empty():
		_upsert_connection_status_entry("warning", "没有文件系统选择", "请先在 FileSystem Dock 中选择一个或多个文件/文件夹。")
		return

	context["id"] = _make_additional_context_id("filesystem_selection", "", _make_filesystem_selection_context_key(context))
	context["pinned"] = false
	_add_or_replace_additional_context(context)


func _create_node_additional_context(target_node: Node, edited_root: Node) -> Dictionary:
	var scene_path: String = _get_scene_resource_path(edited_root)
	var node_path: String = _get_relative_node_path(edited_root, target_node)
	var script_path: String = _get_node_script_path(target_node)
	var node_type: String = target_node.get_class()
	var context: Dictionary = {
		"id": _make_additional_context_id("node", scene_path, node_path),
		"kind": "node",
		"title": target_node.name,
		"subtitle": "%s in %s" % [node_type, scene_path.get_file() if not scene_path.is_empty() else edited_root.name],
		"pinned": false,
		"source": "editor",
		"resourcePath": scene_path,
		"nodePath": node_path,
		"nodeType": node_type,
		"summary": _summarize_editor_node(target_node),
		"data": _serialize_editor_node_summary(target_node, edited_root)
	}
	if not script_path.is_empty():
		context["scriptPath"] = script_path
	return context


func _add_or_replace_additional_context(context: Dictionary) -> void:
	var context_id: String = str(context.get("id", ""))
	if context_id.is_empty():
		context["id"] = _make_additional_context_id(str(context.get("kind", "context")), str(context.get("resourcePath", "")), str(context.get("nodePath", "")))

	var context_key: String = _make_additional_context_key(context)
	for index: int in range(additional_context_items.size()):
		var existing_context: Dictionary = additional_context_items[index]
		if _make_additional_context_key(existing_context) == context_key:
			context["pinned"] = bool(existing_context.get("pinned", false))
			additional_context_items[index] = context.duplicate(true)
			_render_additional_context_items()
			return

	additional_context_items.append(context.duplicate(true))
	_render_additional_context_items()


func _render_additional_context_items() -> void:
	if additional_context_container == null:
		return

	for child: Node in additional_context_container.get_children():
		child.queue_free()

	additional_context_viewer.visible = not additional_context_items.is_empty()
	if additional_context_items.is_empty():
		return

	for context: Dictionary in additional_context_items:
		var context_item: Node = ADDITIONAL_CONTEXT_ITEM_SCENE.instantiate()
		additional_context_container.add_child(context_item)
		context_item.call("setup", context)
		if context_item.has_signal("pin_toggled"):
			context_item.connect("pin_toggled", Callable(self, "_on_additional_context_pin_toggled"))
		if context_item.has_signal("remove_requested"):
			context_item.connect("remove_requested", Callable(self, "_on_additional_context_remove_requested"))


func _on_additional_context_pin_toggled(context_id: String, pinned: bool) -> void:
	for index: int in range(additional_context_items.size()):
		var context: Dictionary = additional_context_items[index]
		if str(context.get("id", "")) == context_id:
			context["pinned"] = pinned
			additional_context_items[index] = context
			break


func _on_additional_context_remove_requested(context_id: String) -> void:
	for index: int in range(additional_context_items.size() - 1, -1, -1):
		var context: Dictionary = additional_context_items[index]
		if str(context.get("id", "")) == context_id:
			_dismiss_live_additional_context_if_needed(context_id, context)
			additional_context_items.remove_at(index)
			break
	_render_additional_context_items()


func _get_additional_context_snapshot() -> Array[Dictionary]:
	return _clone_additional_context_array(additional_context_items)


func _clone_additional_context_array(source_contexts: Array) -> Array[Dictionary]:
	var cloned_contexts: Array[Dictionary] = []
	for context_value: Variant in source_contexts:
		if typeof(context_value) != TYPE_DICTIONARY:
			continue
		var context_dictionary: Dictionary = context_value as Dictionary
		cloned_contexts.append(context_dictionary.duplicate(true))
	return cloned_contexts


func _clear_unpinned_additional_context_items() -> void:
	var retained_contexts: Array[Dictionary] = []
	for context: Dictionary in additional_context_items:
		if bool(context.get("pinned", false)):
			retained_contexts.append(context)
		else:
			_dismiss_live_additional_context_if_needed(str(context.get("id", "")), context)
	additional_context_items = retained_contexts
	_render_additional_context_items()


func _make_additional_context_id(context_kind: String, resource_path: String, node_path: String) -> String:
	additional_context_next_id += 1
	var key_text: String = "%s:%s:%s:%d" % [context_kind, resource_path, node_path, additional_context_next_id]
	return "ctx-%d-%d" % [Time.get_ticks_msec(), abs(hash(key_text))]


func _make_additional_context_key(context: Dictionary) -> String:
	var context_kind: String = str(context.get("kind", ""))
	if context_kind == "script_selection":
		return "%s\n%s\n%s" % [
			context_kind,
			str(context.get("resourcePath", "")),
			_make_script_selection_context_key(context)
		]
	if context_kind == "filesystem_selection":
		return "%s\n%s" % [
			context_kind,
			_make_filesystem_selection_context_key(context)
		]

	return "%s\n%s\n%s" % [
		context_kind,
		str(context.get("resourcePath", "")),
		str(context.get("nodePath", ""))
	]


func _get_additional_context_data(context: Dictionary) -> Dictionary:
	var data_value: Variant = context.get("data", {})
	if typeof(data_value) != TYPE_DICTIONARY:
		return {}

	return data_value as Dictionary


func _make_script_selection_context_key(context: Dictionary) -> String:
	var data: Dictionary = _get_additional_context_data(context)
	return "%d:%d-%d:%d" % [
		int(data.get("lineStart", 0)),
		int(data.get("columnStart", 0)),
		int(data.get("lineEnd", 0)),
		int(data.get("columnEnd", 0))
	]


func _make_filesystem_selection_context_key(context: Dictionary) -> String:
	var data: Dictionary = _get_additional_context_data(context)
	var selected_paths_value: Variant = data.get("selectedPaths", [])
	if typeof(selected_paths_value) != TYPE_ARRAY:
		return str(context.get("resourcePath", ""))

	var selected_paths: Array = selected_paths_value as Array
	var path_parts: Array[String] = []
	for selected_path_value: Variant in selected_paths:
		if typeof(selected_path_value) != TYPE_DICTIONARY:
			continue
		var selected_path: Dictionary = selected_path_value as Dictionary
		path_parts.append(str(selected_path.get("resourcePath", "")))
	return "\n".join(path_parts)


func _render_message_panel() -> void:
	if message_queue_panel == null or message_tree == null:
		return

	var should_show_panel: bool = background_context_viewer.visible and (not queued_messages.is_empty() or not manual_guides.is_empty())
	message_queue_panel.visible = should_show_panel
	if not should_show_panel:
		message_tree.clear()
		return

	message_tree.clear()
	var root_item: TreeItem = message_tree.create_item()

	for queued_message: Dictionary in queued_messages:
		var queue_item: TreeItem = message_tree.create_item(root_item)
		var metadata: Dictionary = {
			"kind": "queue",
			"id": int(queued_message.get("id", 0)),
			"status": str(queued_message.get("status", MESSAGE_QUEUE_STATUS_PENDING)),
			"message": str(queued_message.get("text", ""))
		}
		var queue_status: String = str(queued_message.get("status", MESSAGE_QUEUE_STATUS_PENDING))
		queue_item.set_text(MESSAGE_TREE_STATUS_COLUMN, _format_queue_status(queue_status))
		queue_item.set_text(MESSAGE_TREE_MESSAGE_COLUMN, _format_message_preview(str(queued_message.get("text", ""))))
		queue_item.set_tooltip_text(MESSAGE_TREE_MESSAGE_COLUMN, str(queued_message.get("text", "")))
		queue_item.set_metadata(MESSAGE_TREE_STATUS_COLUMN, metadata)
		queue_item.set_metadata(MESSAGE_TREE_MESSAGE_COLUMN, metadata)
		queue_item.set_metadata(MESSAGE_TREE_ACTIONS_COLUMN, metadata)
		queue_item.add_button(MESSAGE_TREE_ACTIONS_COLUMN, EDIT_ICON, MESSAGE_TREE_BUTTON_EDIT, not _can_edit_queue_message(queue_status), "Edit")
		queue_item.add_button(MESSAGE_TREE_ACTIONS_COLUMN, DELETE_ICON, MESSAGE_TREE_BUTTON_DELETE, not _can_delete_queue_message(queue_status), "Delete")

	for manual_guide: Dictionary in manual_guides:
		var guide_item: TreeItem = message_tree.create_item(root_item)
		var guide_status: String = str(manual_guide.get("status", GUIDE_STATUS_DRAFT))
		var guide_metadata: Dictionary = {
			"kind": "guide",
			"local_id": str(manual_guide.get("local_id", "")),
			"guide_id": str(manual_guide.get("guide_id", "")),
			"client_guide_id": str(manual_guide.get("client_guide_id", "")),
			"status": guide_status,
			"message": str(manual_guide.get("text", ""))
		}
		guide_item.set_text(MESSAGE_TREE_STATUS_COLUMN, _format_guide_status(guide_status))
		guide_item.set_text(MESSAGE_TREE_MESSAGE_COLUMN, _format_message_preview(str(manual_guide.get("text", ""))))
		guide_item.set_tooltip_text(MESSAGE_TREE_MESSAGE_COLUMN, str(manual_guide.get("text", "")))
		guide_item.set_metadata(MESSAGE_TREE_STATUS_COLUMN, guide_metadata)
		guide_item.set_metadata(MESSAGE_TREE_MESSAGE_COLUMN, guide_metadata)
		guide_item.set_metadata(MESSAGE_TREE_ACTIONS_COLUMN, guide_metadata)
		guide_item.add_button(MESSAGE_TREE_ACTIONS_COLUMN, GUIDE_NOW_ICON, MESSAGE_TREE_BUTTON_GUIDE_NOW, not _can_submit_manual_guide(guide_status), "Guide now")
		guide_item.add_button(MESSAGE_TREE_ACTIONS_COLUMN, EDIT_ICON, MESSAGE_TREE_BUTTON_EDIT, not _can_edit_manual_guide(guide_status), "Edit")
		guide_item.add_button(MESSAGE_TREE_ACTIONS_COLUMN, DELETE_ICON, MESSAGE_TREE_BUTTON_DELETE, not _can_delete_manual_guide(guide_status), "Delete")


func _format_queue_status(status: String) -> String:
	if status == str(MESSAGE_QUEUE_STATUS_PENDING):
		return "Queued"
	if status == str(MESSAGE_QUEUE_STATUS_SENDING):
		return "Sending"
	if status == str(MESSAGE_QUEUE_STATUS_APPROVAL):
		return "Approval"
	if status == str(MESSAGE_QUEUE_STATUS_CANCELLED):
		return "Stopped"
	if status == str(MESSAGE_QUEUE_STATUS_REJECTED):
		return "Rejected"
	if status == str(MESSAGE_QUEUE_STATUS_FAILED):
		return "Failed"

	return status.capitalize()


func _can_edit_queue_message(status: String) -> bool:
	return status == str(MESSAGE_QUEUE_STATUS_PENDING) or status == str(MESSAGE_QUEUE_STATUS_FAILED) or status == str(MESSAGE_QUEUE_STATUS_CANCELLED) or status == str(MESSAGE_QUEUE_STATUS_REJECTED)


func _can_delete_queue_message(status: String) -> bool:
	return status == str(MESSAGE_QUEUE_STATUS_PENDING) or status == str(MESSAGE_QUEUE_STATUS_FAILED) or status == str(MESSAGE_QUEUE_STATUS_CANCELLED) or status == str(MESSAGE_QUEUE_STATUS_REJECTED)


func _format_guide_status(status: String) -> String:
	if status == str(GUIDE_STATUS_DRAFT):
		return "Guide"
	if status == str(GUIDE_STATUS_SUBMITTING):
		return "Sending"
	if status == str(GUIDE_STATUS_PENDING):
		return "Pending"
	if status == str(GUIDE_STATUS_DELETING):
		return "Deleting"
	if status == str(GUIDE_STATUS_APPLIED):
		return "Applied"
	if status == str(GUIDE_STATUS_FAILED):
		return "Failed"

	return status.capitalize()


func _can_submit_manual_guide(status: String) -> bool:
	return status == str(GUIDE_STATUS_DRAFT) or status == str(GUIDE_STATUS_FAILED)


func _can_edit_manual_guide(status: String) -> bool:
	return status == str(GUIDE_STATUS_DRAFT) or status == str(GUIDE_STATUS_PENDING) or status == str(GUIDE_STATUS_FAILED) or status == str(GUIDE_STATUS_APPLIED)


func _can_delete_manual_guide(status: String) -> bool:
	return status != str(GUIDE_STATUS_SUBMITTING) and status != str(GUIDE_STATUS_DELETING)


func _format_message_preview(message_text: String) -> String:
	var preview_text: String = message_text.replace("\n", " ").strip_edges()
	if preview_text.length() > 96:
		return preview_text.substr(0, 96) + "..."

	return preview_text


func _string_or_empty(value: Variant) -> String:
	if value == null:
		return ""

	return str(value)


func _on_message_tree_item_activated() -> void:
	var selected_item: TreeItem = message_tree.get_selected()
	if selected_item == null:
		return

	var metadata_value: Variant = selected_item.get_metadata(0)
	if typeof(metadata_value) != TYPE_DICTIONARY:
		return

	var metadata: Dictionary = metadata_value as Dictionary
	var item_kind: String = str(metadata.get("kind", ""))
	if item_kind == "guide":
		var guide_message_text: String = str(metadata.get("message", ""))
		if not guide_message_text.is_empty():
			text_edit.text = guide_message_text
			text_edit.grab_focus()
		return
	if item_kind != "queue":
		return

	var queue_status: String = str(metadata.get("status", ""))
	if queue_status == str(MESSAGE_QUEUE_STATUS_PENDING) and active_stream_id.is_empty():
		_process_message_queue()
		return

	var queued_message_text: String = str(metadata.get("message", ""))
	if not queued_message_text.is_empty():
		text_edit.text = queued_message_text
		text_edit.grab_focus()


func _on_message_tree_button_clicked(item: TreeItem, _column: int, button_id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	var metadata_value: Variant = item.get_metadata(MESSAGE_TREE_STATUS_COLUMN)
	if typeof(metadata_value) != TYPE_DICTIONARY:
		return

	var metadata: Dictionary = metadata_value as Dictionary
	var item_kind: String = str(metadata.get("kind", ""))
	if item_kind == "queue":
		_handle_queue_tree_action(button_id, metadata)
	elif item_kind == "guide":
		_handle_guide_tree_action(button_id, metadata)


func _on_text_edit_text_changed() -> void:
	_update_send_state()


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
	if not was_recovering or session_id_to_restore.is_empty():
		_process_message_queue()
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
		if active_queue_message_id > 0:
			_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_FAILED)
		_stop_active_stream_locally(true)
		details += "\n当前回复已在本地暂停；恢复后可以直接发送“继续”。"
	_upsert_connection_status_entry("warning", "连接中断", details)
	_start_backend_connection_attempts(false, true)


func _handle_recovered_session_open(result_dictionary: Dictionary) -> void:
	var metadata_value: Variant = result_dictionary.get("metadata", {})
	if typeof(metadata_value) == TYPE_DICTIONARY:
		_apply_session_metadata(metadata_value as Dictionary)
	_sync_pending_guides_from_result(result_dictionary)
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
	_process_message_queue()


func _on_status_item_action_requested(action_id: String) -> void:
	if action_id == "reconnect":
		_restart_backend_connection(true)
	elif action_id.begins_with(NEXT_STEP_HINT_ACTION_PREFIX):
		var hint_message: String = next_step_hints_by_action_id.get(action_id, "")
		if not hint_message.is_empty():
			text_edit.text = hint_message
			text_edit.grab_focus()
			_update_send_state()


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
	_queue_editor_context_update()


func setup_editor_bridge(plugin: EditorPlugin) -> void:
	editor_plugin = plugin
	if editor_plugin == null:
		return

	editor_interface = editor_plugin.get_editor_interface()
	editor_selection = editor_interface.get_selection()
	editor_undo_redo = editor_plugin.get_undo_redo()
	editor_script_editor = editor_interface.get_script_editor()
	if editor_selection != null and not editor_selection.selection_changed.is_connected(_on_editor_selection_changed):
		editor_selection.selection_changed.connect(_on_editor_selection_changed)
	var script_changed_callable: Callable = Callable(self, "_on_editor_script_changed")
	if editor_script_editor != null and editor_script_editor.has_signal("editor_script_changed") and not editor_script_editor.is_connected("editor_script_changed", script_changed_callable):
		editor_script_editor.connect("editor_script_changed", script_changed_callable)
	_queue_editor_context_update()


func _on_editor_selection_changed() -> void:
	_queue_editor_context_update()


func _on_editor_script_changed(_script: Resource) -> void:
	_queue_editor_context_update()


func _poll_live_editor_context() -> void:
	if editor_interface == null:
		return

	var now_msec: int = Time.get_ticks_msec()
	if now_msec < editor_context_next_poll_msec:
		return

	editor_context_next_poll_msec = now_msec + EDITOR_CONTEXT_POLL_INTERVAL_MSEC
	_queue_editor_context_update()


func _queue_editor_context_update() -> void:
	if editor_context_update_queued:
		return

	editor_context_update_queued = true
	call_deferred("_send_editor_context_update")


func _send_editor_context_update() -> void:
	editor_context_update_queued = false
	if editor_interface == null:
		return

	var edited_root: Node = _get_edited_scene_root()
	var selected_nodes: Array[Dictionary] = []
	if editor_selection != null and edited_root != null:
		var raw_selected_nodes: Array[Node] = editor_selection.get_selected_nodes()
		for selected_node: Node in raw_selected_nodes:
			if selected_node == null:
				continue
			selected_nodes.append(_serialize_editor_node_summary(selected_node, edited_root))

	var script_context: Dictionary = _collect_script_selection_context()
	var filesystem_selection_context: Dictionary = _collect_filesystem_selection_context()
	_sync_live_editor_selection_context(edited_root, selected_nodes)
	_sync_live_script_selection_context(script_context)
	_sync_live_filesystem_selection_context(filesystem_selection_context)
	if not _is_socket_open():
		return

	var params: Dictionary[String, Variant] = {
		"hasEditor": true,
		"workspaceId": ProjectSettings.globalize_path("res://"),
		"activeScenePath": _get_scene_resource_path(edited_root) if edited_root != null else "",
		"selectedNodeCount": selected_nodes.size(),
		"selectedNodes": selected_nodes,
		"scriptContext": script_context if not script_context.is_empty() else null,
		"filesystemSelection": filesystem_selection_context if not filesystem_selection_context.is_empty() else null,
		"updatedAt": _get_utc_timestamp()
	}
	if edited_root != null:
		params["editedSceneRoot"] = _serialize_editor_node_summary(edited_root, edited_root)

	_send_request("editor.context.update", params, "editor-context")


func _sync_live_editor_selection_context(edited_root: Node, selected_nodes: Array[Dictionary]) -> void:
	if edited_root == null or selected_nodes.is_empty():
		_upsert_live_additional_context(LIVE_EDITOR_SELECTION_CONTEXT_ID, {})
		return

	var scene_path: String = _get_scene_resource_path(edited_root)
	var title_text: String = "选中节点 (%d)" % selected_nodes.size()
	var selected_names: Array[String] = []
	for selected_node_info: Dictionary in selected_nodes:
		selected_names.append(str(selected_node_info.get("name", "")))

	var context: Dictionary = {
		"id": LIVE_EDITOR_SELECTION_CONTEXT_ID,
		"kind": "editor_selection",
		"title": title_text,
		"subtitle": scene_path,
		"pinned": false,
		"source": "editor",
		"resourcePath": scene_path,
		"summary": "当前编辑器选中节点：%s" % ", ".join(selected_names),
		"data": {
			"selectedNodes": selected_nodes
		}
	}
	_upsert_live_additional_context(LIVE_EDITOR_SELECTION_CONTEXT_ID, context)


func _sync_live_script_selection_context(context: Dictionary) -> void:
	_upsert_live_additional_context(LIVE_SCRIPT_SELECTION_CONTEXT_ID, context)


func _sync_live_filesystem_selection_context(context: Dictionary) -> void:
	_upsert_live_additional_context(LIVE_FILESYSTEM_SELECTION_CONTEXT_ID, context)


func _upsert_live_additional_context(context_id: String, context: Dictionary) -> void:
	_ensure_dismissed_live_context_signatures()
	var existing_index: int = _find_additional_context_index(context_id)
	if existing_index >= 0:
		var existing_context: Dictionary = additional_context_items[existing_index]
		if bool(existing_context.get("pinned", false)):
			return

	if context.is_empty():
		dismissed_live_context_signatures.erase(context_id)
		if existing_index >= 0:
			additional_context_items.remove_at(existing_index)
			_render_additional_context_items()
		return

	var live_context: Dictionary = context.duplicate(true)
	live_context["id"] = context_id
	live_context["pinned"] = false
	var next_signature: String = _make_live_additional_context_signature(context_id, live_context)
	if str(dismissed_live_context_signatures.get(context_id, "")) == next_signature:
		return
	if existing_index >= 0:
		var current_signature: String = _make_live_additional_context_signature(context_id, additional_context_items[existing_index])
		if current_signature == next_signature:
			return
		additional_context_items[existing_index] = live_context
	else:
		additional_context_items.append(live_context)
	_render_additional_context_items()


func _dismiss_live_additional_context_if_needed(context_id: String, context: Dictionary) -> void:
	if not _is_live_additional_context_id(context_id):
		return

	_ensure_dismissed_live_context_signatures()
	dismissed_live_context_signatures[context_id] = _make_live_additional_context_signature(context_id, context)


func _ensure_dismissed_live_context_signatures() -> void:
	if typeof(dismissed_live_context_signatures) != TYPE_DICTIONARY:
		dismissed_live_context_signatures = {}


func _is_live_additional_context_id(context_id: String) -> bool:
	return (
		context_id == LIVE_EDITOR_SELECTION_CONTEXT_ID
		or context_id == LIVE_SCRIPT_SELECTION_CONTEXT_ID
		or context_id == LIVE_FILESYSTEM_SELECTION_CONTEXT_ID
	)


func _make_live_additional_context_signature(context_id: String, context: Dictionary) -> String:
	var signature_context: Dictionary = context.duplicate(true)
	signature_context["id"] = context_id
	signature_context["pinned"] = false
	return JSON.stringify(signature_context)


func _find_additional_context_index(context_id: String) -> int:
	for index: int in range(additional_context_items.size()):
		var context: Dictionary = additional_context_items[index]
		if str(context.get("id", "")) == context_id:
			return index
	return -1


func _collect_script_selection_context() -> Dictionary:
	if editor_script_editor == null:
		return {}
	if not editor_script_editor.has_method("get_current_editor"):
		return {}

	var current_editor_value: Variant = editor_script_editor.call("get_current_editor")
	if not (current_editor_value is Object):
		return {}
	var current_editor_object: Object = current_editor_value as Object
	if current_editor_object == null or not current_editor_object.has_method("get_base_editor"):
		return {}

	var base_editor_value: Variant = current_editor_object.call("get_base_editor")
	if not (base_editor_value is TextEdit):
		return {}
	var base_text_edit: TextEdit = base_editor_value as TextEdit
	var line_count: int = base_text_edit.get_line_count()
	if line_count <= 0:
		return {}

	var resource_path: String = _get_current_script_resource_path(current_editor_object)
	var caret_line_zero: int = clampi(base_text_edit.get_caret_line(0), 0, maxi(line_count - 1, 0))
	var caret_column_zero: int = maxi(base_text_edit.get_caret_column(0), 0)
	var has_script_selection: bool = base_text_edit.has_selection(0)
	var line_start: int = caret_line_zero + 1
	var column_start: int = caret_column_zero + 1
	var line_end: int = line_start
	var column_end: int = column_start
	var data: Dictionary = {
		"caretLine": line_start,
		"caretColumn": column_start,
		"hasSelection": has_script_selection
	}

	if has_script_selection:
		line_start = base_text_edit.get_selection_from_line(0) + 1
		column_start = base_text_edit.get_selection_from_column(0) + 1
		line_end = base_text_edit.get_selection_to_line(0) + 1
		column_end = base_text_edit.get_selection_to_column(0) + 1
		var selected_text: String = base_text_edit.get_selected_text(0)
		data["selectedTextPreview"] = _clip_context_text(selected_text, SCRIPT_SELECTION_PREVIEW_LIMIT)
		data["selectedTextTruncated"] = selected_text.length() > SCRIPT_SELECTION_PREVIEW_LIMIT
	else:
		var current_line_text: String = base_text_edit.get_line(caret_line_zero)
		data["lineTextPreview"] = _clip_context_text(current_line_text, SCRIPT_LINE_PREVIEW_LIMIT)
		data["lineTextTruncated"] = current_line_text.length() > SCRIPT_LINE_PREVIEW_LIMIT

	data["lineStart"] = line_start
	data["columnStart"] = column_start
	data["lineEnd"] = line_end
	data["columnEnd"] = column_end

	var script_name: String = resource_path.get_file()
	if script_name.is_empty():
		script_name = "未保存脚本"
	var range_text: String = _format_script_selection_range(line_start, line_end)
	var selection_label: String = "选区" if has_script_selection else "光标行"
	var context: Dictionary = {
		"id": LIVE_SCRIPT_SELECTION_CONTEXT_ID,
		"kind": "script_selection",
		"title": "%s:%s" % [script_name, range_text],
		"subtitle": "%s · %d:%d-%d:%d" % [selection_label, line_start, column_start, line_end, column_end],
		"pinned": false,
		"source": "editor",
		"summary": "Godot 脚本编辑器当前%s，行列使用 1-based：%d:%d-%d:%d。" % [selection_label, line_start, column_start, line_end, column_end],
		"data": data
	}
	if not resource_path.is_empty():
		context["resourcePath"] = resource_path
		context["scriptPath"] = resource_path
	return context


func _get_current_script_resource_path(current_editor_object: Object) -> String:
	var script_resource: Resource
	if editor_script_editor != null and editor_script_editor.has_method("get_current_script"):
		var script_value: Variant = editor_script_editor.call("get_current_script")
		if script_value is Resource:
			script_resource = script_value as Resource

	if script_resource == null and current_editor_object.has_method("get_edited_resource"):
		var edited_resource_value: Variant = current_editor_object.call("get_edited_resource")
		if edited_resource_value is Resource:
			script_resource = edited_resource_value as Resource

	if script_resource == null:
		return ""

	return script_resource.resource_path


func _collect_filesystem_selection_context() -> Dictionary:
	if editor_interface == null:
		return {}

	var selected_paths: PackedStringArray = editor_interface.get_selected_paths()
	if selected_paths.is_empty():
		return {}

	var selected_path_items: Array[Dictionary] = []
	var selected_names: Array[String] = []
	var truncated: bool = false
	for index: int in range(selected_paths.size()):
		if selected_path_items.size() >= FILESYSTEM_CONTEXT_MAX_PATHS:
			truncated = true
			break

		var selected_path: String = selected_paths[index].strip_edges()
		if selected_path.is_empty():
			continue

		var normalized_path: String = selected_path.trim_suffix("/")
		var selected_kind: String = "folder" if DirAccess.dir_exists_absolute(selected_path) else "file"
		var selected_name: String = normalized_path.get_file()
		if selected_name.is_empty():
			selected_name = selected_path
		var selected_item: Dictionary = {
			"resourcePath": selected_path,
			"kind": selected_kind,
			"name": selected_name
		}
		if selected_kind == "file":
			selected_item["extension"] = selected_path.get_extension()
		selected_path_items.append(selected_item)
		selected_names.append(selected_name)

	if selected_path_items.is_empty():
		return {}

	var first_item: Dictionary = selected_path_items[0]
	var first_path: String = str(first_item.get("resourcePath", ""))
	var title_text: String = "文件系统选中项 (%d)" % selected_path_items.size()
	if selected_path_items.size() == 1:
		title_text = str(first_item.get("name", title_text))

	var subtitle_text: String = first_path
	if selected_path_items.size() > 1:
		subtitle_text = "%s 等 %d 项" % [first_path, selected_path_items.size()]

	return {
		"id": LIVE_FILESYSTEM_SELECTION_CONTEXT_ID,
		"kind": "filesystem_selection",
		"title": title_text,
		"subtitle": subtitle_text,
		"pinned": false,
		"source": "editor",
		"resourcePath": first_path,
		"summary": "FileSystem Dock 当前选中：%s%s" % [", ".join(selected_names.slice(0, 6)), " ..." if truncated or selected_names.size() > 6 else ""],
		"data": {
			"selectedPaths": selected_path_items,
			"truncated": truncated
		}
	}


func _format_script_selection_range(line_start: int, line_end: int) -> String:
	if line_start == line_end:
		return "%d" % line_start
	return "%d-%d" % [line_start, line_end]


func _clip_context_text(source_text: String, max_chars: int) -> String:
	if source_text.length() <= max_chars:
		return source_text
	return source_text.substr(0, max_chars)


func _get_edited_scene_root() -> Node:
	if editor_interface == null:
		return null

	return editor_interface.get_edited_scene_root()


func _get_scene_resource_path(scene_root: Node) -> String:
	if scene_root == null:
		return ""
	return scene_root.scene_file_path


func _get_relative_node_path(scene_root: Node, target_node: Node) -> String:
	if scene_root == null or target_node == null:
		return ""
	if scene_root == target_node:
		return "."
	return str(scene_root.get_path_to(target_node))


func _find_editor_node(scene_path: String, node_path: String) -> Node:
	var edited_root: Node = _get_edited_scene_root()
	if edited_root == null:
		return null

	var requested_scene_path: String = scene_path.strip_edges()
	if not requested_scene_path.is_empty() and requested_scene_path != _get_scene_resource_path(edited_root):
		return null

	var requested_node_path: String = node_path.strip_edges()
	if requested_node_path.is_empty() or requested_node_path == ".":
		return edited_root
	if not edited_root.has_node(NodePath(requested_node_path)):
		return null

	return edited_root.get_node(NodePath(requested_node_path))


func _serialize_editor_node_summary(target_node: Node, scene_root: Node) -> Dictionary:
	var script_path: String = _get_node_script_path(target_node)
	var summary: Dictionary = {
		"name": target_node.name,
		"path": _get_relative_node_path(scene_root, target_node),
		"type": target_node.get_class(),
		"ownerPath": _get_relative_node_path(scene_root, target_node.owner) if target_node.owner != null else "",
		"childCount": target_node.get_child_count(),
		"properties": _get_node_key_properties(target_node)
	}
	if not script_path.is_empty():
		summary["scriptPath"] = script_path
	return summary


func _serialize_editor_node_deep(target_node: Node, scene_root: Node, depth: int = 0) -> Dictionary:
	var summary: Dictionary = _serialize_editor_node_summary(target_node, scene_root)
	if depth >= 2:
		return summary

	var children: Array[Dictionary] = []
	for child_node: Node in target_node.get_children():
		children.append(_serialize_editor_node_deep(child_node, scene_root, depth + 1))
	summary["children"] = children
	return summary


func _get_node_script_path(target_node: Node) -> String:
	var script_value: Variant = target_node.get_script()
	if script_value is Script:
		var script_resource: Script = script_value as Script
		return script_resource.resource_path
	return ""


func _get_node_key_properties(target_node: Node) -> Dictionary:
	var properties: Dictionary = {}
	for property_name: String in ["text", "tooltip_text", "visible", "disabled", "placeholder_text", "position", "size", "custom_minimum_size"]:
		if _node_has_property(target_node, property_name):
			var property_value: Variant = target_node.get(property_name)
			properties[property_name] = _compact_variant_for_json(property_value)
	return properties


func _node_has_property(target_node: Node, property_name: String) -> bool:
	for property_info: Dictionary in target_node.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _compact_variant_for_json(value: Variant) -> Variant:
	if value is Vector2:
		var vector_value: Vector2 = value as Vector2
		return { "x": vector_value.x, "y": vector_value.y }
	if value is Vector2i:
		var vector_i_value: Vector2i = value as Vector2i
		return { "x": vector_i_value.x, "y": vector_i_value.y }
	if value is Color:
		var color_value: Color = value as Color
		return color_value.to_html(true)
	if value is Resource:
		var resource_value: Resource = value as Resource
		return resource_value.resource_path
	if typeof(value) == TYPE_ARRAY:
		var source_array: Array = value as Array
		var compact_array: Array = []
		for item: Variant in source_array:
			compact_array.append(_compact_variant_for_json(item))
		return compact_array
	if typeof(value) == TYPE_DICTIONARY:
		var source_dictionary: Dictionary = value as Dictionary
		var compact_dictionary: Dictionary = {}
		for key_value: Variant in source_dictionary.keys():
			compact_dictionary[str(key_value)] = _compact_variant_for_json(source_dictionary[key_value])
		return compact_dictionary
	return value


func _summarize_editor_node(target_node: Node) -> String:
	var node_path: String = ""
	var edited_root: Node = _get_edited_scene_root()
	if edited_root != null:
		node_path = _get_relative_node_path(edited_root, target_node)
	return "%s `%s` (%d children)" % [target_node.get_class(), node_path, target_node.get_child_count()]


func _handle_editor_tool_requested(data: Dictionary) -> void:
	var call_id: String = str(data.get("callId", ""))
	var tool_name: String = str(data.get("toolName", ""))
	var args_value: Variant = data.get("args", {})
	var args: Dictionary = args_value as Dictionary if typeof(args_value) == TYPE_DICTIONARY else {}
	var ok: bool = true
	var result: Variant = {}
	var error_message: String = ""

	if call_id.is_empty():
		return

	if tool_name == "inspect_node":
		result = _execute_editor_inspect_node(args)
	elif tool_name == "apply_scene_patch":
		result = _execute_editor_apply_scene_patch(args)
	else:
		ok = false
		error_message = "Unknown editor tool: %s" % tool_name

	if typeof(result) == TYPE_DICTIONARY and bool((result as Dictionary).get("ok", true)) == false:
		ok = false
		error_message = str((result as Dictionary).get("error", "Editor tool failed"))

	_send_request(
		"editor.tool.result",
		{
			"callId": call_id,
			"ok": ok,
			"result": result if ok else null,
			"error": error_message if not ok else ""
		},
		"editor-tool-result"
	)


func _execute_editor_inspect_node(args: Dictionary) -> Dictionary:
	var scene_path: String = str(args.get("scenePath", ""))
	var node_path: String = str(args.get("nodePath", "."))
	var target_node: Node = _find_editor_node(scene_path, node_path)
	var edited_root: Node = _get_edited_scene_root()
	if target_node == null or edited_root == null:
		return { "ok": false, "error": "editor_node_not_found" }

	return {
		"ok": true,
		"node": _serialize_editor_node_deep(target_node, edited_root)
	}


func _execute_editor_apply_scene_patch(args: Dictionary) -> Dictionary:
	if editor_undo_redo == null:
		return { "ok": false, "error": "editor_undo_redo_unavailable" }

	var edited_root: Node = _get_edited_scene_root()
	if edited_root == null:
		return { "ok": false, "error": "editor_scene_unavailable" }

	var scene_path: String = str(args.get("scenePath", ""))
	if not scene_path.strip_edges().is_empty() and scene_path != _get_scene_resource_path(edited_root):
		return { "ok": false, "error": "editor_scene_mismatch" }

	var operations_value: Variant = args.get("operations", [])
	if typeof(operations_value) != TYPE_ARRAY:
		return { "ok": false, "error": "invalid_operations" }

	var operations: Array = operations_value as Array
	if operations.is_empty():
		return { "ok": false, "error": "empty_operations" }

	var action_title: String = str(args.get("title", "Scene patch")).strip_edges()
	if action_title.is_empty():
		action_title = "Scene patch"
	if not action_title.begins_with("Daedalus:"):
		action_title = "Daedalus: %s" % action_title

	var created_nodes: Array[Node] = []
	for operation_value: Variant in operations:
		if typeof(operation_value) != TYPE_DICTIONARY:
			return { "ok": false, "error": "invalid_operation" }

		var operation: Dictionary = operation_value as Dictionary
		var operation_error: String = _validate_editor_patch_operation(operation)
		if not operation_error.is_empty():
			return { "ok": false, "error": operation_error }

	editor_undo_redo.create_action(action_title)
	for operation_value: Variant in operations:
		var operation: Dictionary = operation_value as Dictionary
		var operation_error: String = _add_editor_patch_operation(operation, edited_root, created_nodes)
		if not operation_error.is_empty():
			return { "ok": false, "error": operation_error }

	editor_undo_redo.commit_action()

	var should_save: bool = bool(args.get("saveAfter", true))
	var save_error: Error = OK
	if should_save:
		save_error = _save_current_editor_scene()

	return {
		"ok": save_error == OK,
		"operations": operations.size(),
		"createdNodes": created_nodes.size(),
		"saved": should_save and save_error == OK,
		"error": "" if save_error == OK else "editor_save_failed:%d" % int(save_error)
	}


func _add_editor_patch_operation(operation: Dictionary, edited_root: Node, created_nodes: Array[Node]) -> String:
	var operation_type: String = str(operation.get("type", ""))
	if operation_type == "set_property":
		return _add_editor_set_property_operation(operation, edited_root)
	if operation_type == "add_node":
		return _add_editor_add_node_operation(operation, edited_root, created_nodes)
	if operation_type == "rename_node":
		return _add_editor_rename_node_operation(operation, edited_root)
	if operation_type == "attach_script":
		return _add_editor_attach_script_operation(operation, edited_root)
	if operation_type == "connect_signal":
		return _add_editor_connect_signal_operation(operation, edited_root)
	return "unsupported_operation:%s" % operation_type


func _validate_editor_patch_operation(operation: Dictionary) -> String:
	var operation_type: String = str(operation.get("type", ""))
	if operation_type == "set_property":
		var target_node: Node = _find_editor_node("", str(operation.get("nodePath", ".")))
		var property_name: String = str(operation.get("property", ""))
		if target_node == null:
			return "node_not_found"
		if property_name.is_empty() or not _node_has_property(target_node, property_name):
			return "property_not_found:%s" % property_name
		return ""
	if operation_type == "add_node":
		var parent_node: Node = _find_editor_node("", str(operation.get("parentPath", ".")))
		var node_type: String = str(operation.get("nodeType", "Node"))
		if parent_node == null:
			return "parent_not_found"
		if not ClassDB.class_exists(node_type):
			return "class_not_found:%s" % node_type
		var created_node_value: Variant = ClassDB.instantiate(node_type)
		if not (created_node_value is Node):
			return "class_is_not_node:%s" % node_type
		var validation_node: Node = created_node_value as Node
		validation_node.free()
		return ""
	if operation_type == "rename_node":
		var rename_node: Node = _find_editor_node("", str(operation.get("nodePath", ".")))
		var node_name: String = str(operation.get("name", "")).strip_edges()
		if rename_node == null:
			return "node_not_found"
		if node_name.is_empty():
			return "empty_node_name"
		return ""
	if operation_type == "attach_script":
		var script_node: Node = _find_editor_node("", str(operation.get("nodePath", ".")))
		var script_path: String = str(operation.get("scriptPath", "")).strip_edges()
		if script_node == null:
			return "node_not_found"
		if script_path.is_empty():
			return "empty_script_path"
		var script_resource: Resource = load(script_path)
		if not (script_resource is Script):
			return "script_not_found:%s" % script_path
		return ""
	if operation_type == "connect_signal":
		var source_node: Node = _find_editor_node("", str(operation.get("fromNode", ".")))
		var target_node: Node = _find_editor_node("", str(operation.get("toNode", ".")))
		var signal_name: String = str(operation.get("signal", "")).strip_edges()
		var method_name: String = str(operation.get("method", "")).strip_edges()
		if source_node == null or target_node == null:
			return "signal_node_not_found"
		if signal_name.is_empty() or method_name.is_empty():
			return "invalid_signal_or_method"
		return ""
	return "unsupported_operation:%s" % operation_type


func _add_editor_set_property_operation(operation: Dictionary, edited_root: Node) -> String:
	var target_node: Node = _find_editor_node("", str(operation.get("nodePath", ".")))
	var property_name: String = str(operation.get("property", ""))
	if target_node == null:
		return "node_not_found"
	if property_name.is_empty() or not _node_has_property(target_node, property_name):
		return "property_not_found:%s" % property_name

	var old_value: Variant = target_node.get(property_name)
	var new_value: Variant = _coerce_property_value(operation.get("value", null), old_value)
	editor_undo_redo.add_do_property(target_node, property_name, new_value)
	editor_undo_redo.add_undo_property(target_node, property_name, old_value)
	return ""


func _add_editor_add_node_operation(operation: Dictionary, edited_root: Node, created_nodes: Array[Node]) -> String:
	var parent_node: Node = _find_editor_node("", str(operation.get("parentPath", ".")))
	var node_type: String = str(operation.get("nodeType", "Node"))
	var node_name: String = str(operation.get("nodeName", node_type))
	if parent_node == null:
		return "parent_not_found"
	if not ClassDB.class_exists(node_type):
		return "class_not_found:%s" % node_type

	var created_node_value: Variant = ClassDB.instantiate(node_type)
	if not (created_node_value is Node):
		return "class_is_not_node:%s" % node_type

	var created_node: Node = created_node_value as Node
	created_node.name = node_name
	var properties_value: Variant = operation.get("properties", {})
	if typeof(properties_value) == TYPE_DICTIONARY:
		var properties: Dictionary = properties_value as Dictionary
		for property_key: Variant in properties.keys():
			var property_name: String = str(property_key)
			if _node_has_property(created_node, property_name):
				var old_value: Variant = created_node.get(property_name)
				created_node.set(property_name, _coerce_property_value(properties[property_key], old_value))

	editor_undo_redo.add_do_method(parent_node, "add_child", created_node)
	editor_undo_redo.add_do_property(created_node, "owner", edited_root)
	editor_undo_redo.add_undo_method(parent_node, "remove_child", created_node)
	editor_undo_redo.add_do_reference(created_node)
	created_nodes.append(created_node)
	return ""


func _add_editor_rename_node_operation(operation: Dictionary, _edited_root: Node) -> String:
	var target_node: Node = _find_editor_node("", str(operation.get("nodePath", ".")))
	var node_name: String = str(operation.get("name", "")).strip_edges()
	if target_node == null:
		return "node_not_found"
	if node_name.is_empty():
		return "empty_node_name"

	var old_name: String = target_node.name
	editor_undo_redo.add_do_property(target_node, "name", node_name)
	editor_undo_redo.add_undo_property(target_node, "name", old_name)
	return ""


func _add_editor_attach_script_operation(operation: Dictionary, _edited_root: Node) -> String:
	var target_node: Node = _find_editor_node("", str(operation.get("nodePath", ".")))
	var script_path: String = str(operation.get("scriptPath", "")).strip_edges()
	if target_node == null:
		return "node_not_found"
	if script_path.is_empty():
		return "empty_script_path"

	var script_resource: Resource = load(script_path)
	if not (script_resource is Script):
		return "script_not_found:%s" % script_path

	var old_script: Variant = target_node.get_script()
	editor_undo_redo.add_do_method(target_node, "set_script", script_resource)
	editor_undo_redo.add_undo_method(target_node, "set_script", old_script)
	return ""


func _add_editor_connect_signal_operation(operation: Dictionary, _edited_root: Node) -> String:
	var source_node: Node = _find_editor_node("", str(operation.get("fromNode", ".")))
	var target_node: Node = _find_editor_node("", str(operation.get("toNode", ".")))
	var signal_name: String = str(operation.get("signal", "")).strip_edges()
	var method_name: String = str(operation.get("method", "")).strip_edges()
	if source_node == null or target_node == null:
		return "signal_node_not_found"
	if signal_name.is_empty() or method_name.is_empty():
		return "invalid_signal_or_method"

	var callable: Callable = Callable(target_node, method_name)
	if source_node.is_connected(signal_name, callable):
		return ""

	editor_undo_redo.add_do_method(source_node, "connect", signal_name, callable)
	editor_undo_redo.add_undo_method(source_node, "disconnect", signal_name, callable)
	return ""


func _coerce_property_value(value: Variant, old_value: Variant) -> Variant:
	if old_value is Vector2 and typeof(value) == TYPE_DICTIONARY:
		var vector_dictionary: Dictionary = value as Dictionary
		return Vector2(float(vector_dictionary.get("x", 0.0)), float(vector_dictionary.get("y", 0.0)))
	if old_value is Vector2i and typeof(value) == TYPE_DICTIONARY:
		var vector_i_dictionary: Dictionary = value as Dictionary
		return Vector2i(int(vector_i_dictionary.get("x", 0)), int(vector_i_dictionary.get("y", 0)))
	if old_value is Color and typeof(value) == TYPE_STRING:
		return Color(str(value))
	return value


func _save_current_editor_scene() -> Error:
	if editor_interface == null:
		return ERR_UNCONFIGURED
	if not editor_interface.has_method("save_scene"):
		return OK

	var result: Variant = editor_interface.call("save_scene")
	if typeof(result) == TYPE_INT:
		return result as Error
	return OK


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
	_render_message_panel()


func _show_background_context_viewer() -> void:
	session_list_viewer.hide()
	background_context_viewer.show()
	workspace_filter_button.hide()
	search_session_line_edit.hide()
	session_option_button.show()
	context_length_button.show()
	_render_message_panel()


func _on_create_new_session_button_pressed() -> void:
	_clear_message_queue()
	_clear_manual_guides()
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
		_process_message_queue()
		return

	var additional_context_snapshot: Array[Dictionary] = _get_additional_context_snapshot()
	if _should_queue_outgoing_message():
		if _enqueue_message(message_text, additional_context_snapshot):
			text_edit.clear()
			_clear_unpinned_additional_context_items()
			_update_send_state()
			_process_message_queue()
		return

	if _dispatch_message_text(message_text, additional_context_snapshot):
		_clear_unpinned_additional_context_items()
		if active_session_id.is_empty():
			text_edit.clear()
			_update_send_state()


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
	if active_queue_message_id > 0:
		_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_CANCELLED)
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

	if active_queue_message_id > 0:
		_set_queue_message_status(active_queue_message_id, MESSAGE_QUEUE_STATUS_SENDING)
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

	if session_id != active_session_id:
		_clear_message_queue()
		_clear_manual_guides()
	_send_request("session.open", { "sessionId": session_id, "limit": SESSION_OPEN_MESSAGE_LIMIT }, "session-open")


func _dispatch_message_text(message_text: String, additional_contexts: Array = []) -> bool:
	if not _is_socket_open():
		return false

	if active_session_id.is_empty():
		pending_chat_text = message_text
		pending_chat_additional_context = _clone_additional_context_array(additional_contexts)
		_create_session(_make_session_title(message_text))
		return true

	return _send_chat_text(message_text, "", additional_contexts)


func _send_chat_text(message_text: String, retry_from_request_id: String = "", additional_contexts: Array = []) -> bool:
	if not _is_socket_open():
		return false

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
	var additional_context_snapshot: Array[Dictionary] = _clone_additional_context_array(additional_contexts)
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	_append_timeline_entry(
		"user",
		active_stream_request_id,
		message_text,
		"",
		{
			"sent_at_utc": active_stream_started_at_utc,
			"additional_context": additional_context_snapshot
		}
	)
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
	if not additional_context_snapshot.is_empty():
		chat_params["additionalContext"] = additional_context_snapshot

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
		if active_queue_message_id > 0:
			_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_FAILED)
		return false

	_scroll_to_bottom_if_following(should_follow_bottom)
	text_edit.clear()
	_set_streaming_state(true)
	return true


func _should_queue_outgoing_message() -> bool:
	return (
		not _is_socket_open()
		or not active_stream_id.is_empty()
		or not pending_approval_id.is_empty()
		or not pending_chat_text.is_empty()
		or _has_pending_queued_messages()
	)


func _enqueue_message(message_text: String, additional_contexts: Array = []) -> bool:
	if _get_open_queue_count() >= MAX_QUEUED_MESSAGES:
		_upsert_connection_status_entry(
			"warning",
			"消息队列已满",
			"最多保留 %d 条待发送消息。请等待当前队列消化后再继续添加。" % MAX_QUEUED_MESSAGES
		)
		return false

	message_queue_next_id += 1
	var queued_message: Dictionary = {
		"id": message_queue_next_id,
		"text": message_text,
		"additional_context": _clone_additional_context_array(additional_contexts),
		"status": MESSAGE_QUEUE_STATUS_PENDING,
		"created_at_utc": _get_utc_timestamp()
	}
	queued_messages.append(queued_message)
	_show_background_context_viewer()
	_render_message_panel()
	_update_send_state()
	return true


func _process_message_queue() -> void:
	if not _can_dispatch_queued_message():
		_render_message_panel()
		return

	var queued_index: int = _find_next_pending_queue_index()
	if queued_index < 0:
		_render_message_panel()
		return

	var queued_message: Dictionary = queued_messages[queued_index]
	active_queue_message_id = int(queued_message.get("id", 0))
	queued_message["status"] = MESSAGE_QUEUE_STATUS_SENDING
	queued_messages[queued_index] = queued_message
	_render_message_panel()

	var queued_text: String = str(queued_message.get("text", ""))
	var queued_contexts: Array = queued_message.get("additional_context", []) as Array
	if not _dispatch_message_text(queued_text, queued_contexts):
		_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_FAILED)
		_process_message_queue()


func _can_dispatch_queued_message() -> bool:
	return (
		_is_socket_open()
		and active_stream_id.is_empty()
		and pending_approval_id.is_empty()
		and pending_chat_text.is_empty()
	)


func _has_pending_queued_messages() -> bool:
	return _find_next_pending_queue_index() >= 0


func _find_next_pending_queue_index() -> int:
	for index: int in range(queued_messages.size()):
		var queued_message: Dictionary = queued_messages[index]
		if str(queued_message.get("status", MESSAGE_QUEUE_STATUS_PENDING)) == str(MESSAGE_QUEUE_STATUS_PENDING):
			return index

	return -1


func _get_open_queue_count() -> int:
	var open_count: int = 0
	for queued_message: Dictionary in queued_messages:
		var status: String = str(queued_message.get("status", MESSAGE_QUEUE_STATUS_PENDING))
		if status == str(MESSAGE_QUEUE_STATUS_PENDING) or status == str(MESSAGE_QUEUE_STATUS_SENDING) or status == str(MESSAGE_QUEUE_STATUS_APPROVAL):
			open_count += 1

	return open_count


func _set_queue_message_status(queue_message_id: int, status: StringName) -> void:
	for index: int in range(queued_messages.size()):
		var queued_message: Dictionary = queued_messages[index]
		if int(queued_message.get("id", 0)) != queue_message_id:
			continue

		queued_message["status"] = status
		queued_messages[index] = queued_message
		_render_message_panel()
		return


func _finish_active_queue_message(remove_message: bool, final_status: StringName = MESSAGE_QUEUE_STATUS_FAILED) -> void:
	if active_queue_message_id <= 0:
		return

	var finished_queue_message_id: int = active_queue_message_id
	active_queue_message_id = 0
	if remove_message:
		_remove_queue_message(finished_queue_message_id)
	else:
		_set_queue_message_status(finished_queue_message_id, final_status)
	_render_message_panel()


func _remove_queue_message(queue_message_id: int) -> void:
	for index: int in range(queued_messages.size()):
		var queued_message: Dictionary = queued_messages[index]
		if int(queued_message.get("id", 0)) == queue_message_id:
			queued_messages.remove_at(index)
			return


func _clear_message_queue() -> void:
	queued_messages.clear()
	active_queue_message_id = 0
	_render_message_panel()
	_update_send_state()


func _handle_queue_tree_action(button_id: int, metadata: Dictionary) -> void:
	var queue_message_id: int = int(metadata.get("id", 0))
	var queue_status: String = str(metadata.get("status", ""))
	var queue_message_text: String = str(metadata.get("message", ""))
	if queue_message_id <= 0:
		return

	if button_id == MESSAGE_TREE_BUTTON_EDIT:
		if not _can_edit_queue_message(queue_status):
			return
		text_edit.text = queue_message_text
		text_edit.grab_focus()
		_remove_queue_message(queue_message_id)
	elif button_id == MESSAGE_TREE_BUTTON_DELETE:
		if not _can_delete_queue_message(queue_status):
			return
		_remove_queue_message(queue_message_id)

	_render_message_panel()
	_update_send_state()


func _handle_guide_tree_action(button_id: int, metadata: Dictionary) -> void:
	var local_id: String = str(metadata.get("local_id", ""))
	if local_id.is_empty():
		return

	if button_id == MESSAGE_TREE_BUTTON_GUIDE_NOW:
		_submit_manual_guide(local_id)
	elif button_id == MESSAGE_TREE_BUTTON_EDIT:
		_edit_manual_guide(local_id)
	elif button_id == MESSAGE_TREE_BUTTON_DELETE:
		_delete_manual_guide(local_id)


func _create_or_update_manual_guide_from_text_edit() -> void:
	var guide_text: String = text_edit.text.strip_edges()
	if guide_text.is_empty():
		return

	if not editing_guide_local_id.is_empty():
		if _update_editing_manual_guide(guide_text):
			text_edit.clear()
			editing_guide_local_id = ""
			_update_send_state()
		return

	manual_guide_next_id += 1
	var local_id: String = "local-guide-%d" % manual_guide_next_id
	var manual_guide: Dictionary = {
		"local_id": local_id,
		"guide_id": "",
		"client_guide_id": local_id,
		"text": guide_text,
		"status": GUIDE_STATUS_DRAFT,
		"created_at_utc": _get_utc_timestamp(),
		"updated_at_utc": _get_utc_timestamp(),
		"anchor_request_id": active_stream_request_id
	}
	manual_guides.append(manual_guide)
	text_edit.clear()
	_show_background_context_viewer()
	_render_message_panel()
	_update_send_state()


func _update_editing_manual_guide(guide_text: String) -> bool:
	var guide_index: int = _find_manual_guide_index(editing_guide_local_id)
	if guide_index < 0:
		return false

	var manual_guide: Dictionary = manual_guides[guide_index]
	var guide_status: String = str(manual_guide.get("status", GUIDE_STATUS_DRAFT))
	manual_guide["text"] = guide_text
	manual_guide["updated_at_utc"] = _get_utc_timestamp()

	if guide_status == str(GUIDE_STATUS_PENDING):
		var guide_id: String = str(manual_guide.get("guide_id", ""))
		if guide_id.is_empty() or not _is_socket_open():
			manual_guide["status"] = GUIDE_STATUS_FAILED
		else:
			var params: Dictionary[String, Variant] = {
				"guideId": guide_id,
				"text": guide_text
			}
			var update_request_id: String = _send_request("session.guide.update", params, "guide-update")
			manual_guide["pending_request_id"] = update_request_id
			manual_guide["status"] = GUIDE_STATUS_PENDING
	else:
		manual_guide["status"] = GUIDE_STATUS_DRAFT

	manual_guides[guide_index] = manual_guide
	_render_message_panel()
	return true


func _submit_manual_guide(local_id: String) -> void:
	var guide_index: int = _find_manual_guide_index(local_id)
	if guide_index < 0:
		return

	if active_session_id.is_empty():
		_upsert_connection_status_entry("warning", "无法引导", "当前没有打开的会话。请先发送一条消息或打开一个会话。")
		return
	if not _is_socket_open():
		_upsert_connection_status_entry("warning", "无法引导", "后端未连接，引导会先保留在本地。")
		return

	var manual_guide: Dictionary = manual_guides[guide_index]
	var guide_status: String = str(manual_guide.get("status", GUIDE_STATUS_DRAFT))
	if not _can_submit_manual_guide(guide_status):
		return

	var guide_text: String = str(manual_guide.get("text", "")).strip_edges()
	if guide_text.is_empty():
		return

	var params: Dictionary[String, Variant] = {
		"clientGuideId": str(manual_guide.get("client_guide_id", local_id)),
		"text": guide_text
	}
	var anchor_request_id: String = str(manual_guide.get("anchor_request_id", ""))
	if not anchor_request_id.is_empty():
		params["anchorRequestId"] = anchor_request_id

	var add_request_id: String = _send_request("session.guide.add", params, "guide-add")
	if add_request_id.is_empty():
		_upsert_connection_status_entry("warning", "无法引导", "引导提交失败，后端连接不可用。")
		return

	manual_guide["status"] = GUIDE_STATUS_SUBMITTING
	manual_guide["pending_request_id"] = add_request_id
	manual_guides[guide_index] = manual_guide
	_render_message_panel()


func _edit_manual_guide(local_id: String) -> void:
	var guide_index: int = _find_manual_guide_index(local_id)
	if guide_index < 0:
		return

	var manual_guide: Dictionary = manual_guides[guide_index]
	var guide_status: String = str(manual_guide.get("status", GUIDE_STATUS_DRAFT))
	if not _can_edit_manual_guide(guide_status):
		return

	text_edit.text = str(manual_guide.get("text", ""))
	text_edit.grab_focus()
	if guide_status == str(GUIDE_STATUS_PENDING):
		editing_guide_local_id = local_id
	elif guide_status == str(GUIDE_STATUS_DRAFT) or guide_status == str(GUIDE_STATUS_FAILED):
		manual_guides.remove_at(guide_index)
		editing_guide_local_id = ""
	else:
		editing_guide_local_id = ""
	_render_message_panel()
	_update_send_state()


func _delete_manual_guide(local_id: String) -> void:
	var guide_index: int = _find_manual_guide_index(local_id)
	if guide_index < 0:
		return

	var manual_guide: Dictionary = manual_guides[guide_index]
	var guide_status: String = str(manual_guide.get("status", GUIDE_STATUS_DRAFT))
	if not _can_delete_manual_guide(guide_status):
		return

	if guide_status == str(GUIDE_STATUS_PENDING):
		var guide_id: String = str(manual_guide.get("guide_id", ""))
		if not guide_id.is_empty() and _is_socket_open():
			var delete_request_id: String = _send_request("session.guide.delete", { "guideId": guide_id }, "guide-delete")
			manual_guide["status"] = GUIDE_STATUS_DELETING
			manual_guide["pending_request_id"] = delete_request_id
			manual_guides[guide_index] = manual_guide
		else:
			manual_guides.remove_at(guide_index)
	else:
		manual_guides.remove_at(guide_index)

	if editing_guide_local_id == local_id:
		editing_guide_local_id = ""
	_render_message_panel()
	_update_send_state()


func _find_manual_guide_index(local_id: String) -> int:
	for index: int in range(manual_guides.size()):
		var manual_guide: Dictionary = manual_guides[index]
		if str(manual_guide.get("local_id", "")) == local_id:
			return index

	return -1


func _find_manual_guide_index_by_backend_id(guide_id: String, client_guide_id: String = "") -> int:
	for index: int in range(manual_guides.size()):
		var manual_guide: Dictionary = manual_guides[index]
		if not guide_id.is_empty() and str(manual_guide.get("guide_id", "")) == guide_id:
			return index
		if not client_guide_id.is_empty() and str(manual_guide.get("client_guide_id", "")) == client_guide_id:
			return index

	return -1


func _clear_manual_guides() -> void:
	manual_guides.clear()
	editing_guide_local_id = ""
	_render_message_panel()


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
		if str(message.get("id", "")).begins_with("next-step-hints"):
			next_step_hint_request_id = ""
			next_step_hint_anchor_request_id = ""
			return
		if _handle_guide_response_error(message):
			return
		if str(message.get("id", "")).begins_with("context-popup-info"):
			context_popup_open_after_info = false
		if str(message.get("id", "")).begins_with("session-timeline"):
			timeline_loading_before = false
		if str(message.get("id", "")).begins_with("session-create") and active_queue_message_id > 0:
			pending_chat_text = ""
			_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_FAILED)
			_process_message_queue()
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
			if active_queue_message_id > 0:
				_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_FAILED)
			active_stream_id = ""
			active_stream_started_at_utc = ""
			active_assistant_item = null
			active_assistant_text = ""
			_set_streaming_state(false)
			_process_message_queue()
		else:
			_show_background_context_viewer()
			_show_response_error(message)
		return

	var result: Variant = message.get("result", {})
	if typeof(result) != TYPE_DICTIONARY:
		return

	var result_dictionary: Dictionary = result as Dictionary
	if bool(result_dictionary.get("nextStepHints", false)):
		_apply_next_step_hints_response(str(message.get("id", "")), result_dictionary)
	elif bool(result_dictionary.get("guideAdded", false)) or bool(result_dictionary.get("guideUpdated", false)):
		_apply_guide_upsert_response(result_dictionary)
	elif bool(result_dictionary.get("guideDeleted", false)):
		_apply_guide_delete_response(result_dictionary)
	elif result_dictionary.has("archivedSessions"):
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
			var next_additional_context: Array[Dictionary] = _clone_additional_context_array(pending_chat_additional_context)
			pending_chat_text = ""
			pending_chat_additional_context.clear()
			if not _send_chat_text(next_message, "", next_additional_context) and active_queue_message_id > 0:
				_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_FAILED)
				_process_message_queue()
	elif bool(result_dictionary.get("opened", false)) and str(message.get("id", "")).begins_with("session-recover-open"):
		_handle_recovered_session_open(result_dictionary)
	elif bool(result_dictionary.get("opened", false)):
		var metadata: Variant = result_dictionary.get("metadata", {})
		if typeof(metadata) == TYPE_DICTIONARY:
			_apply_session_metadata(metadata as Dictionary)
		_clear_chat_items()
		_show_background_context_viewer()
		_render_session_timeline(result_dictionary.get("messages", []), result_dictionary.get("events", []), result_dictionary)
		_sync_pending_guides_from_result(result_dictionary)
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
		var was_rejected: bool = bool(result_dictionary.get("rejected", false))
		pending_approval_id = ""
		_update_send_state()
		if was_rejected and active_queue_message_id > 0:
			_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_REJECTED)
			_process_message_queue()
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
		var completed_request_id: String = active_stream_request_id
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
		_finish_active_queue_message(true)
		if not _has_pending_queued_messages():
			_request_next_step_hints(completed_request_id, "done")
		_process_message_queue()
	elif event_name == "ai.paused":
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		var paused_request_id: String = active_stream_request_id
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
			if active_queue_message_id > 0:
				_set_queue_message_status(active_queue_message_id, MESSAGE_QUEUE_STATUS_APPROVAL)
			_show_approval_dialog(data_dictionary)
		_request_next_step_hints(paused_request_id, "paused")
	elif event_name == "ai.cancelled":
		_stop_active_stream_locally(false)
	elif event_name == "ai.thinking.delta":
		_append_thinking_event(str(data_dictionary.get("text", "")))
	elif event_name == "ai.thinking.done":
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		_flush_pending_thinking_delta()
		if not active_assistant_entry_id.is_empty():
			_append_assistant_thinking_to_timeline(active_assistant_entry_id, "", true)
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
		var tool_was_rejected: bool = event_name == "tool.rejected"
		pending_approval_id = ""
		approval_dialog.visible = false
		_update_send_state()
		if tool_was_rejected and active_queue_message_id > 0:
			_finish_active_queue_message(false, MESSAGE_QUEUE_STATUS_REJECTED)
			_process_message_queue()
		elif active_queue_message_id > 0:
			_set_queue_message_status(active_queue_message_id, MESSAGE_QUEUE_STATUS_SENDING)
	elif event_name == "workflow.started":
		active_workflow_id = str(data_dictionary.get("workflowId", ""))
	elif event_name == "workflow.todo.updated":
		_apply_workflow_todo_snapshot(data_dictionary)
	elif event_name == "guide.applied":
		_apply_guide_applied_event(data_dictionary)
	elif event_name == "guide.deleted":
		_apply_guide_deleted_event(data_dictionary)
	elif event_name == "editor.tool.requested":
		_handle_editor_tool_requested(data_dictionary)


func _is_global_event(event_name: String) -> bool:
	return event_name == "tool.approved" or event_name == "tool.rejected" or event_name == "tool.approval_required" or event_name == "ai.paused" or event_name == "ai.cancelled" or event_name == "editor.tool.requested" or event_name.begins_with("workflow.") or event_name.begins_with("guide.")


func _request_next_step_hints(anchor_request_id: String, trigger: String) -> void:
	if not next_step_hints_enabled:
		return
	if not _is_socket_open() or active_session_id.is_empty():
		return
	if not next_step_hint_request_id.is_empty():
		return

	var params: Dictionary[String, Variant] = {
		"sessionId": active_session_id,
		"trigger": trigger,
		"maxHints": 3
	}
	if not anchor_request_id.is_empty():
		params["anchorRequestId"] = anchor_request_id

	next_step_hint_request_id = _send_request("ai.next_step_hints", params, "next-step-hints")
	next_step_hint_anchor_request_id = anchor_request_id
	if next_step_hint_request_id.is_empty():
		next_step_hint_anchor_request_id = ""


func _apply_next_step_hints_response(response_id: String, result_dictionary: Dictionary) -> void:
	if response_id != next_step_hint_request_id:
		return

	next_step_hint_request_id = ""
	next_step_hint_anchor_request_id = ""
	_clear_next_step_hint_entries()

	var hints_value: Variant = result_dictionary.get("hints", [])
	if typeof(hints_value) != TYPE_ARRAY:
		text_edit.placeholder_text = ""
		return

	var hints: Array = hints_value as Array
	if hints.is_empty():
		text_edit.placeholder_text = ""
		return

	for index: int in range(hints.size()):
		var hint_value: Variant = hints[index]
		if typeof(hint_value) != TYPE_DICTIONARY:
			continue

		var hint: Dictionary = hint_value as Dictionary
		var hint_title: String = str(hint.get("title", "下一步")).strip_edges()
		var hint_message: String = str(hint.get("message", "")).strip_edges()
		if hint_message.is_empty():
			continue

		if index == 0:
			text_edit.placeholder_text = hint_message
			continue

		var action_id: String = "%s%d-%d" % [NEXT_STEP_HINT_ACTION_PREFIX, Time.get_ticks_msec(), index]
		next_step_hints_by_action_id[action_id] = hint_message
		var entry_id: String = _append_timeline_entry(
			"status",
			"",
			hint_message,
			"next-step-hint-%d-%d" % [Time.get_ticks_msec(), index],
			{
				"status": "message",
				"title": "下一步提示：%s" % hint_title,
				"detail": hint_message,
				"action_label": "Use",
				"action_id": action_id
			}
		)
		next_step_hint_entry_ids.append(entry_id)

	_schedule_timeline_render(_should_follow_timeline_updates())


func _clear_next_step_hint_entries() -> void:
	text_edit.placeholder_text = ""
	next_step_hints_by_action_id.clear()
	for entry_id: String in next_step_hint_entry_ids:
		var entry_index: int = _find_timeline_entry_index(entry_id)
		if entry_index >= 0:
			timeline_entries.remove_at(entry_index)
		var rendered_node_value: Variant = rendered_entry_nodes.get(entry_id, null)
		if rendered_node_value is Node:
			(rendered_node_value as Node).queue_free()
		rendered_entry_nodes.erase(entry_id)
		rendered_entry_indices.erase(entry_id)

	next_step_hint_entry_ids.clear()
	_rebuild_timeline_index_cache()
	_rebuild_timeline_height_cache()
	_schedule_timeline_render(_should_follow_timeline_updates())


func _handle_guide_response_error(message: Dictionary) -> bool:
	var response_id: String = str(message.get("id", ""))
	if not (response_id.begins_with("guide-add") or response_id.begins_with("guide-update") or response_id.begins_with("guide-delete")):
		return false

	for index: int in range(manual_guides.size()):
		var manual_guide: Dictionary = manual_guides[index]
		if str(manual_guide.get("pending_request_id", "")) != response_id:
			continue

		if response_id.begins_with("guide-delete"):
			manual_guide["status"] = GUIDE_STATUS_PENDING
		else:
			manual_guide["status"] = GUIDE_STATUS_FAILED
		manual_guide["pending_request_id"] = ""
		manual_guides[index] = manual_guide
		break

	_render_message_panel()
	_show_response_error(message)
	return true


func _apply_guide_upsert_response(result_dictionary: Dictionary) -> void:
	var guide_value: Variant = result_dictionary.get("guide", {})
	if typeof(guide_value) != TYPE_DICTIONARY:
		return

	var guide_dictionary: Dictionary = guide_value as Dictionary
	var guide_id: String = str(guide_dictionary.get("guideId", ""))
	var client_guide_id: String = str(guide_dictionary.get("clientGuideId", ""))
	var guide_index: int = _find_manual_guide_index_by_backend_id(guide_id, client_guide_id)
	var manual_guide: Dictionary
	if guide_index >= 0:
		manual_guide = manual_guides[guide_index]
	else:
		manual_guide_next_id += 1
		manual_guide = {
			"local_id": "remote-guide-%d" % manual_guide_next_id,
			"client_guide_id": client_guide_id
		}
		manual_guides.append(manual_guide)
		guide_index = manual_guides.size() - 1

	manual_guide["guide_id"] = guide_id
	manual_guide["client_guide_id"] = client_guide_id
	manual_guide["text"] = str(guide_dictionary.get("text", manual_guide.get("text", "")))
	manual_guide["status"] = GUIDE_STATUS_PENDING
	manual_guide["pending_request_id"] = ""
	manual_guide["updated_at_utc"] = str(guide_dictionary.get("updatedAt", _get_utc_timestamp()))
	manual_guide["anchor_request_id"] = _string_or_empty(guide_dictionary.get("anchorRequestId", ""))
	manual_guides[guide_index] = manual_guide
	_render_message_panel()


func _apply_guide_delete_response(result_dictionary: Dictionary) -> void:
	var guide_id: String = str(result_dictionary.get("guideId", ""))
	var guide_index: int = _find_manual_guide_index_by_backend_id(guide_id)
	if guide_index >= 0:
		manual_guides.remove_at(guide_index)
	_render_message_panel()


func _apply_guide_applied_event(data_dictionary: Dictionary) -> void:
	var guide_id: String = str(data_dictionary.get("guideId", ""))
	var client_guide_id: String = str(data_dictionary.get("clientGuideId", ""))
	var guide_index: int = _find_manual_guide_index_by_backend_id(guide_id, client_guide_id)
	if guide_index < 0:
		return

	var manual_guide: Dictionary = manual_guides[guide_index]
	manual_guide["status"] = GUIDE_STATUS_APPLIED
	manual_guide["pending_request_id"] = ""
	manual_guides[guide_index] = manual_guide
	_render_message_panel()


func _apply_guide_deleted_event(data_dictionary: Dictionary) -> void:
	var guide_id: String = str(data_dictionary.get("guideId", ""))
	var client_guide_id: String = str(data_dictionary.get("clientGuideId", ""))
	var guide_index: int = _find_manual_guide_index_by_backend_id(guide_id, client_guide_id)
	if guide_index >= 0:
		manual_guides.remove_at(guide_index)
	_render_message_panel()


func _sync_pending_guides_from_result(result_dictionary: Dictionary) -> void:
	var pending_guides_value: Variant = result_dictionary.get("pendingGuides", [])
	if typeof(pending_guides_value) != TYPE_ARRAY:
		return

	manual_guides.clear()
	editing_guide_local_id = ""
	var pending_guides: Array = pending_guides_value as Array
	for guide_value: Variant in pending_guides:
		if typeof(guide_value) != TYPE_DICTIONARY:
			continue

		var guide_dictionary: Dictionary = guide_value as Dictionary
		manual_guide_next_id += 1
		manual_guides.append({
			"local_id": "remote-guide-%d" % manual_guide_next_id,
			"guide_id": str(guide_dictionary.get("guideId", "")),
			"client_guide_id": str(guide_dictionary.get("clientGuideId", "")),
			"text": str(guide_dictionary.get("text", "")),
			"status": GUIDE_STATUS_PENDING,
			"pending_request_id": "",
			"created_at_utc": str(guide_dictionary.get("createdAt", "")),
			"updated_at_utc": str(guide_dictionary.get("updatedAt", "")),
			"anchor_request_id": _string_or_empty(guide_dictionary.get("anchorRequestId", ""))
		})

	_render_message_panel()


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
	_render_message_panel()


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
	next_step_hint_request_id = ""
	next_step_hint_anchor_request_id = ""
	next_step_hint_entry_ids.clear()
	next_step_hints_by_action_id.clear()
	text_edit.placeholder_text = ""
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
	_render_message_panel()


func _render_session_timeline(messages_value: Variant, events_value: Variant, page_info: Dictionary) -> void:
	timeline_message_offset = int(page_info.get("messagesOffset", 0))
	timeline_has_more_before = bool(page_info.get("hasMoreBefore", false))
	timeline_loading_before = false
	_append_session_records_to_timeline(messages_value, events_value)
	active_thinking_item = null
	active_thinking_entry_id = ""
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
	var assistant_request_ids: Dictionary[String, bool] = _collect_message_request_ids_for_role(messages, "assistant")
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
			var additional_contexts_value: Variant = message.get("additionalContext", [])
			var additional_contexts: Array = additional_contexts_value as Array if typeof(additional_contexts_value) == TYPE_ARRAY else []
			_append_timeline_entry(
				"user",
				request_id,
				content,
				_make_message_entry_id(message, role),
				{
					"sent_at_utc": created_at,
					"additional_context": _clone_additional_context_array(additional_contexts)
				}
			)
			if not request_id.is_empty() and not created_at.is_empty():
				request_started_at_by_id[request_id] = created_at
			if not request_id.is_empty() and not assistant_request_ids.has(request_id):
				_append_events_for_request(request_id, events_by_request_id, consumed_request_ids)
		elif role == "assistant":
			var body_parts: Array[Dictionary] = []
			if not request_id.is_empty():
				var request_records: Array = events_by_request_id.get(request_id, []) as Array
				_append_event_records(_filter_non_assistant_body_event_records(request_records))
				body_parts = _build_assistant_body_parts(request_records, content, request_id)
				if not consumed_request_ids.has(request_id):
					consumed_request_ids.append(request_id)
			else:
				body_parts = _build_assistant_body_parts([], content, request_id)
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
					"completed_at_utc": created_at,
					"body_parts": body_parts
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


func _collect_message_request_ids_for_role(messages: Array, target_role: String) -> Dictionary[String, bool]:
	var ids: Dictionary[String, bool] = {}
	for item: Variant in messages:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var message: Dictionary = item as Dictionary
		if str(message.get("role", "")) != target_role:
			continue

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


func _filter_non_assistant_body_event_records(records: Array) -> Array:
	var filtered_records: Array = []
	for item: Variant in records:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var event_record: Dictionary = item as Dictionary
		var event_name: String = str(event_record.get("event", ""))
		if event_name.begins_with("tool."):
			continue
		if event_name.begins_with("ai.thinking."):
			continue

		filtered_records.append(event_record)

	return filtered_records


func _build_assistant_body_parts(records: Array, message_content: String, request_id: String) -> Array[Dictionary]:
	var body_parts: Array[Dictionary] = []
	for item: Variant in records:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var event_record: Dictionary = item as Dictionary
		var event_name: String = str(event_record.get("event", ""))

		var data_value: Variant = event_record.get("data", {})
		if typeof(data_value) != TYPE_DICTIONARY:
			continue

		var event_data: Dictionary = (data_value as Dictionary).duplicate(true)
		if not event_data.has("type"):
			event_data["type"] = event_name
		event_data["_eventRecordId"] = str(event_record.get("id", ""))
		if event_name.begins_with("tool."):
			_append_tool_event_to_body_parts(body_parts, event_data, request_id)
		elif event_name == "ai.thinking.delta":
			_append_thinking_event_to_body_parts(body_parts, str(event_data.get("text", "")), false)
		elif event_name == "ai.thinking.done":
			_append_thinking_event_to_body_parts(body_parts, "", true)

	if not message_content.is_empty():
		body_parts.append({
			"type": "markdown",
			"text": message_content
		})

	return body_parts


func _append_tool_event_to_body_parts(body_parts: Array, event_data: Dictionary, request_id: String) -> void:
	var tool_call_id: String = _get_scoped_tool_call_key(event_data, request_id)
	for index: int in range(body_parts.size()):
		var part_value: Variant = body_parts[index]
		if typeof(part_value) != TYPE_DICTIONARY:
			continue

		var part: Dictionary = part_value as Dictionary
		if str(part.get("type", "")) != "tool":
			continue
		if str(part.get("tool_call_id", "")) != tool_call_id:
			continue

		var events_value: Variant = part.get("events", [])
		var events: Array = events_value as Array if typeof(events_value) == TYPE_ARRAY else []
		if _does_event_list_have_record(events, str(event_data.get("_eventRecordId", ""))):
			return

		events.append(event_data.duplicate(true))
		part["events"] = events
		body_parts[index] = part
		return

	body_parts.append({
		"type": "tool",
		"tool_call_id": tool_call_id,
		"events": [event_data.duplicate(true)]
	})


func _append_thinking_event_to_body_parts(body_parts: Array, delta_text: String, is_done: bool) -> void:
	for index: int in range(body_parts.size() - 1, -1, -1):
		var part_value: Variant = body_parts[index]
		if typeof(part_value) != TYPE_DICTIONARY:
			continue

		var part: Dictionary = part_value as Dictionary
		if str(part.get("type", "")) != "thinking":
			continue
		if bool(part.get("done", false)):
			continue

		if not delta_text.is_empty():
			part["text"] = str(part.get("text", "")) + delta_text
		if is_done:
			part["done"] = true
		body_parts[index] = part
		return

	body_parts.append({
		"type": "thinking",
		"text": delta_text,
		"done": is_done
	})


func _does_event_list_have_record(events: Array, event_record_id: String) -> bool:
	if event_record_id.is_empty():
		return false

	for event_value: Variant in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue

		var event_data: Dictionary = event_value as Dictionary
		if str(event_data.get("_eventRecordId", "")) == event_record_id:
			return true

	return false


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


func _append_assistant_delta_to_timeline(entry_id: String, delta_text: String, preserve_stream_height: bool = false) -> void:
	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0 or delta_text.is_empty():
		return

	var entry: Dictionary = timeline_entries[index]
	var next_content: String = str(entry.get("content", "")) + delta_text
	entry["content"] = next_content
	var body_parts: Array = entry.get("body_parts", []) as Array
	var should_add_markdown_part: bool = body_parts.is_empty()
	if not should_add_markdown_part:
		var last_part_value: Variant = body_parts[body_parts.size() - 1]
		should_add_markdown_part = typeof(last_part_value) != TYPE_DICTIONARY or str((last_part_value as Dictionary).get("type", "")) != "markdown"

	if should_add_markdown_part:
		body_parts.append({
			"type": "markdown",
			"text": delta_text
		})
	else:
		var part: Dictionary = body_parts[body_parts.size() - 1] as Dictionary
		part["text"] = str(part.get("text", "")) + delta_text
		body_parts[body_parts.size() - 1] = part

	entry["body_parts"] = body_parts
	if preserve_stream_height:
		timeline_entries[index] = entry
		return

	entry["height_estimate"] = _estimate_timeline_entry_height(str(entry.get("type", "")), next_content)
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
		node.call("setup", str(entry.get("content", "")), str(entry.get("request_id", "")), str(entry.get("sent_at_utc", "")), entry.get("additional_context", []))
		if node.has_signal("resend_requested"):
			node.connect("resend_requested", Callable(self, "_on_user_message_resend_requested"))
	elif entry_type == "assistant":
		node.call(
			"setup",
			str(entry.get("content", "")),
			str(entry.get("started_at_utc", "")),
			str(entry.get("completed_at_utc", "")),
			entry.get("body_parts", [])
		)
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
	var render_required: bool = false
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
		if entry_id != active_assistant_entry_id or active_stream_id.is_empty():
			render_required = true

	if changed:
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		_rebuild_timeline_height_cache()
		if render_required:
			_render_visible_timeline(should_follow_bottom)
		elif should_follow_bottom:
			_scroll_timeline_to_bottom_deferred()


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
	var active_entry_rendered: bool = rendered_entry_nodes.has(active_assistant_entry_id)
	_append_assistant_delta_to_timeline(active_assistant_entry_id, delta_text, active_entry_rendered)

	active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node
	if active_assistant_item != null:
		active_assistant_item.call("append_delta", delta_text)
		_schedule_timeline_measure()
		_scroll_to_bottom_if_following(should_follow_bottom)
		return

	_schedule_timeline_render(should_follow_bottom)


func _show_response_error(message: Dictionary) -> void:
	var should_follow_bottom: bool = _should_follow_timeline_updates()
	var error_value: Variant = message.get("error", {})
	var error_message: String = "Unknown backend error"
	if typeof(error_value) == TYPE_DICTIONARY:
		var error_dictionary: Dictionary = error_value as Dictionary
		error_message = str(error_dictionary.get("message", error_message))

	if active_assistant_item != null:
		var error_delta: String = "\n\n后端返回错误：%s" % error_message
		if not active_assistant_entry_id.is_empty():
			_append_assistant_delta_to_timeline(active_assistant_entry_id, error_delta)
		active_assistant_item.call("append_delta", error_delta)
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
	_flush_pending_assistant_delta()
	var item: Node = _append_active_assistant_tool_event(event_data, true)
	var tool_call_id: String = _get_scoped_tool_call_key(event_data, active_stream_request_id)
	if item != null:
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

	var item: Node
	if entry_id == active_assistant_entry_id:
		item = _append_active_assistant_tool_event(event_data, false)
	else:
		_append_tool_event_to_timeline(event_data, active_stream_request_id)
		item = rendered_entry_nodes.get(entry_id, null) as Node
	if item != null:
		if entry_id != active_assistant_entry_id:
			item.call("append_tool_event", event_data)
		_scroll_to_bottom_if_following(should_follow_bottom)

	_schedule_timeline_render(should_follow_bottom)


func _append_active_assistant_tool_event(event_data: Dictionary, create_if_missing: bool) -> Node:
	_ensure_active_assistant_item()
	if active_assistant_entry_id.is_empty():
		return null

	var scoped_tool_call_id: String = _get_scoped_tool_call_key(event_data, active_stream_request_id)
	_append_assistant_tool_event_to_timeline(active_assistant_entry_id, event_data, active_stream_request_id)
	active_tool_entry_ids_by_call_id[scoped_tool_call_id] = active_assistant_entry_id

	active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node
	if active_assistant_item == null:
		return null

	var local_tool_call_id: String = _get_tool_call_key(event_data)
	var item: Node = active_assistant_item.call("get_tool_item", local_tool_call_id) as Node
	if item == null and create_if_missing:
		item = active_assistant_item.call("add_tool_event", event_data) as Node
	elif item != null:
		item.call("append_tool_event", event_data)
	else:
		item = active_assistant_item.call("add_tool_event", event_data) as Node

	return item


func _append_assistant_tool_event_to_timeline(entry_id: String, event_data: Dictionary, request_id: String) -> void:
	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return

	var entry: Dictionary = timeline_entries[index]
	var body_parts: Array = entry.get("body_parts", []) as Array
	_append_tool_event_to_body_parts(body_parts, event_data, request_id)
	entry["body_parts"] = body_parts
	entry["height_actual"] = 0.0
	timeline_entries[index] = entry
	_mark_timeline_height_dirty(index)


func _ensure_active_assistant_thinking_item() -> Node:
	_ensure_active_assistant_item()
	if active_assistant_entry_id.is_empty():
		return null

	if active_thinking_entry_id.is_empty():
		active_thinking_entry_id = "thinking:%s:%d" % [active_stream_request_id, Time.get_ticks_msec()]
		_append_assistant_thinking_to_timeline(active_assistant_entry_id, "", false)

	active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node
	if active_assistant_item == null:
		return null

	var item: Node = active_assistant_item.call("get_thinking_item") as Node
	if item == null:
		item = active_assistant_item.call("add_thinking") as Node
	return item


func _append_assistant_thinking_to_timeline(entry_id: String, delta_text: String, is_done: bool) -> void:
	var index: int = _find_timeline_entry_index(entry_id)
	if index < 0:
		return

	var entry: Dictionary = timeline_entries[index]
	var body_parts: Array = entry.get("body_parts", []) as Array
	_append_thinking_event_to_body_parts(body_parts, delta_text, is_done)
	entry["body_parts"] = body_parts
	entry["height_actual"] = 0.0
	timeline_entries[index] = entry
	_mark_timeline_height_dirty(index)


func _append_thinking_event(delta_text: String) -> void:
	if delta_text.is_empty():
		return

	_show_background_context_viewer()
	if active_thinking_entry_id.is_empty():
		var should_follow_bottom: bool = _should_follow_timeline_updates()
		_flush_pending_assistant_delta()
		active_thinking_item = _ensure_active_assistant_thinking_item()
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
	if not active_assistant_entry_id.is_empty():
		_append_assistant_thinking_to_timeline(active_assistant_entry_id, delta_text, false)
	active_assistant_item = rendered_entry_nodes.get(active_assistant_entry_id, null) as Node
	if active_assistant_item != null:
		active_thinking_item = active_assistant_item.call("get_thinking_item") as Node
		if active_thinking_item == null:
			active_thinking_item = active_assistant_item.call("add_thinking") as Node
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
	if active_queue_message_id > 0:
		_set_queue_message_status(active_queue_message_id, MESSAGE_QUEUE_STATUS_APPROVAL)
	var tool_name: String = str(event_data.get("toolName", event_data.get("llmToolName", "")))
	approval_title_label.text = "需要审批：%s" % _localize_tool_name_for_display(tool_name)
	approval_description_label.text = "\n".join([
		"审批 ID：`%s`" % pending_approval_id,
		"原因：%s" % str(event_data.get("reason", "")),
		"参数：",
		_format_approval_args_preview(event_data.get("args", {}))
	])
	approval_dialog.visible = true
	_update_send_state()


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


func _set_streaming_state(_is_streaming: bool) -> void:
	_update_send_state()


func _has_message_draft() -> bool:
	return not text_edit.text.strip_edges().is_empty()


func _should_show_send_button(is_streaming: bool, has_message_draft: bool) -> bool:
	if not is_streaming:
		return true

	return has_message_draft


func _update_send_state() -> void:
	var is_streaming: bool = not active_stream_id.is_empty()
	var has_message_draft: bool = _has_message_draft()
	var has_pending_queue: bool = _has_pending_queued_messages()
	var should_show_send_button: bool = _should_show_send_button(is_streaming, has_message_draft)
	send_button.visible = should_show_send_button
	stop_button.visible = is_streaming and not should_show_send_button
	send_button.disabled = not text_edit.visible or (not has_message_draft and not has_pending_queue)
	if not socket_ready:
		send_button.tooltip_text = "Queue message until reconnected"
	elif is_streaming or not pending_approval_id.is_empty():
		send_button.tooltip_text = "Queue message"
	elif _has_pending_queued_messages():
		send_button.tooltip_text = "Send next queued message"
	else:
		send_button.tooltip_text = "Send"
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
		"customInstructions": custom_instructions,
		"nextStepHintsEnabled": next_step_hints_enabled
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
	next_custom_instructions: String,
	next_step_hints_enabled_value: bool
) -> void:
	var normalized_backend_url: String = _normalize_backend_url(next_backend_url)
	var backend_url_changed: bool = normalized_backend_url != backend_url
	backend_url = normalized_backend_url
	custom_instructions = next_custom_instructions.strip_edges()
	next_step_hints_enabled = next_step_hints_enabled_value
	_save_frontend_setting(CONFIG_BACKEND_URL_SETTING, backend_url)
	_save_frontend_setting(CONFIG_CUSTOM_INSTRUCTIONS_SETTING, custom_instructions)
	_save_frontend_setting(CONFIG_NEXT_STEP_HINTS_SETTING, next_step_hints_enabled)
	if not next_step_hints_enabled:
		_clear_next_step_hint_entries()

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
