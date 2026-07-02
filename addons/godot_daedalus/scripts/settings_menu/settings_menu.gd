@tool
extends AcceptDialog

signal provider_config_save_requested(api_key: String)
signal provider_config_clear_requested
signal frontend_config_save_requested(backend_url: String, custom_instructions: String, next_step_hints_enabled: bool)
signal archived_session_restore_requested(session_id: String)
signal archived_session_delete_requested(session_id: String)
signal mcp_server_add_requested(config: Dictionary)
signal mcp_server_remove_requested(server_id: String)
signal mcp_server_enabled_requested(server_id: String, enabled: bool)

@onready var tab_container: TabContainer = %TabContainer
@onready var provider_option_button: OptionButton = %ProviderOptionButton
@onready var backend_url_line_edit: LineEdit = %BackendURLLineEdit
@onready var deepseek_api_key_line_edit: LineEdit = %DeepseekAPIKeyLineEdit
@onready var clear_deepseek_api_key_button: Button = %ClearDeepseekAPIKeyButton
@onready var custom_instructions_label: Label = %CustomInstructionsLabel
@onready var custom_instructions_warning_button: Button = %CustomInstructionsWarningButton
@onready var next_step_hints_check_box: CheckBox = %NextStepHintsCheckBox
@onready var custom_instructions_edit: TextEdit = %CustomInstructionsEdit
@onready var add_mcp_server_button: Button = %AddMCPServerButton
@onready var mcp_status_label: Label = %MCPStatusLabel
@onready var mcp_server_list: VBoxContainer = %MCPServerList
@onready var archived_workspace_filter_option_button: OptionButton = %WorkspaceFilterOptionButton
@onready var search_archived_chat_line_edit: LineEdit = %SearchArchivedChatLineEdit
@onready var delete_all_archived_chats_button: Button = %DeleteAllArchivedChatsButton
@onready var archived_chat_list: VBoxContainer = %ArchivedChatList

const ARCHIVED_CHAT_ITEM_SCENE_UID: String = "uid://kyksk24wd7d3"
const MCP_SERVER_ITEM_SCENE_UID: String = "uid://cuwihfpwn6b68"
const ADD_MCP_SERVER_DIALOG_UID: String = "uid://cb7acb4w7s4xl"
const CUSTOM_INSTRUCTIONS_WARNING_CHARS: int = 4000
const CUSTOM_INSTRUCTIONS_HEAVY_CHARS: int = 12000
const EDITOR_TYPE: StringName = &"Editor"
const ACCEPT_DIALOG_TYPE: StringName = &"AcceptDialog"
const EDITOR_SETTINGS_DIALOG_TYPE: StringName = &"EditorSettingsDialog"
const PANEL_STYLE_NAME: StringName = &"panel"
const BASE_STYLE_NAME: StringName = &"base_style"
const BUTTONS_SEPARATION_CONSTANT: StringName = &"buttons_separation"
const BUTTONS_MIN_WIDTH_CONSTANT: StringName = &"buttons_min_width"
const BUTTONS_MIN_HEIGHT_CONSTANT: StringName = &"buttons_min_height"
const CONFIRM_ACTION_NONE: StringName = &""
const CONFIRM_ACTION_DELETE_ARCHIVED_SESSION: StringName = &"delete_archived_session"
const CONFIRM_ACTION_DELETE_ALL_ARCHIVED_SESSIONS: StringName = &"delete_all_archived_sessions"

var archived_sessions: Array[Dictionary] = []
var archived_workspaces_by_id: Dictionary[String, Dictionary] = {}
var custom_mcp_servers: Array[Dictionary] = []
var mcp_backend_available: bool = true
var mcp_add_pending: bool
var pending_mcp_server_metadata: Dictionary = {}
var archived_workspace_filter: String
var archived_search_text: String
var pending_confirmation_action: StringName = CONFIRM_ACTION_NONE
var pending_delete_session_id: String
var pending_delete_session_ids: Array[String] = []
var pending_delete_mcp_server_id: String
var archive_delete_confirmation_dialog: ConfirmationDialog
var custom_instructions_warning_dialog: AcceptDialog
var mcp_delete_confirmation_dialog: ConfirmationDialog


func _ready() -> void:
	tab_container.current_tab = 0
	_update_custom_instructions_status()
	_render_mcp_servers()
	_update_delete_all_archived_chats_button()
	call_deferred(&"_apply_editor_dialog_theme")


func setup_provider_config(status: Dictionary, frontend_config: Dictionary = {}) -> void:
	var configured: bool = bool(status.get("configured", false))
	backend_url_line_edit.text = str(frontend_config.get("backendUrl", "ws://localhost:8080"))
	custom_instructions_edit.text = str(frontend_config.get("customInstructions", ""))
	next_step_hints_check_box.button_pressed = bool(frontend_config.get("nextStepHintsEnabled", false))
	_update_custom_instructions_status()

	if configured:
		deepseek_api_key_line_edit.placeholder_text = "Set new API key"
	else:
		deepseek_api_key_line_edit.placeholder_text = "Set API key"

	clear_deepseek_api_key_button.disabled = not configured
	provider_option_button.disabled = true
	show()


func setup_archived_sessions(sessions: Array, workspaces: Array = []) -> void:
	archived_sessions.clear()
	for item: Variant in sessions:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		archived_sessions.append((item as Dictionary).duplicate(true))

	archived_workspaces_by_id.clear()
	for item: Variant in workspaces:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var workspace: Dictionary = item as Dictionary
		var workspace_id: String = str(workspace.get("id", ""))
		if workspace_id.is_empty():
			continue

		archived_workspaces_by_id[workspace_id] = workspace.duplicate(true)

	_populate_archived_workspace_filter()
	_render_archived_sessions()
	_update_delete_all_archived_chats_button()


func setup_mcp_servers(servers: Array, backend_available: bool = true) -> void:
	custom_mcp_servers.clear()
	for item: Variant in servers:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		custom_mcp_servers.append((item as Dictionary).duplicate(true))

	mcp_backend_available = backend_available
	mcp_add_pending = false
	pending_mcp_server_metadata.clear()
	_render_mcp_servers()


func show_mcp_error(message_text: String) -> void:
	mcp_add_pending = false
	pending_mcp_server_metadata.clear()
	mcp_status_label.visible = true
	mcp_status_label.text = message_text
	mcp_status_label.tooltip_text = message_text


func _on_confirmed() -> void:
	var api_key: String = deepseek_api_key_line_edit.text.strip_edges()
	frontend_config_save_requested.emit(
		backend_url_line_edit.text.strip_edges(),
		custom_instructions_edit.text.strip_edges(),
		next_step_hints_check_box.button_pressed
	)
	provider_config_save_requested.emit(api_key)
	queue_free()


func _on_clear_deepseek_api_key_button_pressed() -> void:
	provider_config_clear_requested.emit()
	queue_free()


func _on_close_requested() -> void:
	queue_free()


func _on_workspace_filter_option_button_item_selected(index: int) -> void:
	if index < 0 or index >= archived_workspace_filter_option_button.get_item_count():
		return

	archived_workspace_filter = str(archived_workspace_filter_option_button.get_item_metadata(index))
	_render_archived_sessions()


func _on_search_archived_chat_line_edit_text_changed(new_text: String) -> void:
	archived_search_text = new_text.strip_edges()
	_render_archived_sessions()


func _populate_archived_workspace_filter() -> void:
	var previous_filter: String = archived_workspace_filter
	var workspace_ids: Array[String] = []
	for metadata: Dictionary in archived_sessions:
		var workspace_id: String = str(metadata.get("workspaceId", ""))
		if workspace_ids.has(workspace_id):
			continue

		workspace_ids.append(workspace_id)

	archived_workspace_filter_option_button.clear()
	archived_workspace_filter_option_button.add_item("All", 0)
	archived_workspace_filter_option_button.set_item_metadata(0, "")

	for workspace_id: String in workspace_ids:
		archived_workspace_filter_option_button.add_item(_format_workspace_name(workspace_id))
		archived_workspace_filter_option_button.set_item_metadata(
			archived_workspace_filter_option_button.get_item_count() - 1,
			workspace_id
		)

	archived_workspace_filter = ""
	for index: int in range(archived_workspace_filter_option_button.get_item_count()):
		if str(archived_workspace_filter_option_button.get_item_metadata(index)) == previous_filter:
			archived_workspace_filter = previous_filter
			archived_workspace_filter_option_button.select(index)
			return

	archived_workspace_filter_option_button.select(0)


func _render_mcp_servers() -> void:
	for child_node: Node in mcp_server_list.get_children():
		child_node.queue_free()

	add_mcp_server_button.disabled = not mcp_backend_available or mcp_add_pending
	add_mcp_server_button.tooltip_text = "Adding custom MCP server..." if mcp_add_pending else ("Add custom MCP server" if mcp_backend_available else "Backend is disconnected")
	if not mcp_backend_available:
		mcp_status_label.visible = true
		mcp_status_label.text = "Backend is disconnected. MCP server settings are unavailable."
	elif mcp_add_pending:
		mcp_status_label.visible = true
		mcp_status_label.text = "Adding custom MCP server..."
	elif custom_mcp_servers.is_empty():
		mcp_status_label.visible = true
		mcp_status_label.text = "No custom MCP servers"
	else:
		mcp_status_label.visible = false
		mcp_status_label.text = ""

	var rendered_servers: Array[Dictionary] = []
	for metadata: Dictionary in custom_mcp_servers:
		rendered_servers.append(metadata)
	if mcp_add_pending and not pending_mcp_server_metadata.is_empty():
		rendered_servers.append(pending_mcp_server_metadata.duplicate(true) as Dictionary)

	if rendered_servers.is_empty():
		return

	var item_scene: PackedScene = load(MCP_SERVER_ITEM_SCENE_UID) as PackedScene
	if item_scene == null:
		return

	for metadata: Dictionary in rendered_servers:
		var mcp_server_item: Node = item_scene.instantiate()
		mcp_server_list.add_child(mcp_server_item)
		mcp_server_item.call("setup", metadata)
		mcp_server_item.connect("remove_requested", Callable(self, "_on_mcp_server_item_remove_requested"))
		mcp_server_item.connect("enabled_changed", Callable(self, "_on_mcp_server_item_enabled_changed"))


func _render_archived_sessions() -> void:
	for child_node: Node in archived_chat_list.get_children():
		child_node.queue_free()

	var item_scene: PackedScene = load(ARCHIVED_CHAT_ITEM_SCENE_UID) as PackedScene
	if item_scene == null:
		return

	var rendered_count: int = 0
	for metadata: Dictionary in archived_sessions:
		if not _does_archived_session_match_filters(metadata):
			continue

		var archived_chat_item: Node = item_scene.instantiate()
		archived_chat_list.add_child(archived_chat_item)
		archived_chat_item.call(
			"setup",
			str(metadata.get("id", "")),
			str(metadata.get("title", "Untitled")),
			_format_archived_time(metadata)
		)
		archived_chat_item.connect(
			"restore_requested",
			Callable(self, "_on_archived_chat_item_restore_requested")
		)
		archived_chat_item.connect(
			"delete_requested",
			Callable(self, "_on_archived_chat_item_delete_requested")
		)
		rendered_count += 1

	if rendered_count == 0:
		var empty_label: Label = Label.new()
		empty_label.text = "No archived chats"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.theme_type_variation = &"LabelNoMargin"
		archived_chat_list.add_child(empty_label)

	_update_delete_all_archived_chats_button()


func _does_archived_session_match_filters(metadata: Dictionary) -> bool:
	if not archived_workspace_filter.is_empty() and str(metadata.get("workspaceId", "")) != archived_workspace_filter:
		return false

	if archived_search_text.is_empty():
		return true

	var query: String = archived_search_text.to_lower()
	var title_text: String = str(metadata.get("title", "")).to_lower()
	var workspace_id: String = str(metadata.get("workspaceId", ""))
	var workspace_text: String = _format_workspace_name(workspace_id).to_lower()

	return title_text.contains(query) or workspace_id.to_lower().contains(query) or workspace_text.contains(query)


func _format_archived_time(metadata: Dictionary) -> String:
	var archived_at: String = str(metadata.get("archivedAt", ""))
	if not archived_at.is_empty():
		return "Archived " + _format_relative_time(archived_at)

	return _format_relative_time(str(metadata.get("updatedAt", "")))


func _format_relative_time(timestamp: String) -> String:
	if timestamp.is_empty():
		return ""

	return timestamp.replace("T", " ").replace("Z", "")


func _format_workspace_name(workspace_id: String) -> String:
	if workspace_id.is_empty():
		return "No workspace"

	var workspace: Dictionary = archived_workspaces_by_id.get(workspace_id, {}) as Dictionary
	if workspace.is_empty():
		return workspace_id

	return str(workspace.get("name", workspace_id))


func _on_archived_chat_item_restore_requested(session_id: String) -> void:
	archived_session_restore_requested.emit(session_id)


func _on_archived_chat_item_delete_requested(session_id: String) -> void:
	if session_id.is_empty():
		return

	var title_text: String = _get_archived_session_title(session_id)
	var session_ids: Array[String] = [session_id]
	_show_archive_delete_confirmation(
		CONFIRM_ACTION_DELETE_ARCHIVED_SESSION,
		"Delete archived chat?",
		"Delete archived chat \"%s\" permanently?\n\nThis cannot be undone." % title_text,
		session_ids
	)


func _apply_editor_dialog_theme() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _is_in_edited_scene():
		return

	var editor_theme: Theme = EditorInterface.get_editor_theme()
	if editor_theme == null:
		return

	var panel_style: StyleBox = _find_editor_settings_panel_style(editor_theme)
	if panel_style != null:
		var panel_style_copy: StyleBox = panel_style.duplicate(true) as StyleBox
		if panel_style_copy != null:
			add_theme_stylebox_override(PANEL_STYLE_NAME, panel_style_copy)

	_copy_accept_dialog_constant(editor_theme, BUTTONS_SEPARATION_CONSTANT)
	_copy_accept_dialog_constant(editor_theme, BUTTONS_MIN_WIDTH_CONSTANT)
	_copy_accept_dialog_constant(editor_theme, BUTTONS_MIN_HEIGHT_CONSTANT)


func _find_editor_settings_panel_style(editor_theme: Theme) -> StyleBox:
	var panel_style: StyleBox = _get_editor_stylebox(
		editor_theme,
		PANEL_STYLE_NAME,
		EDITOR_SETTINGS_DIALOG_TYPE
	)
	if panel_style != null:
		return panel_style

	panel_style = _get_editor_stylebox(editor_theme, PANEL_STYLE_NAME, ACCEPT_DIALOG_TYPE)
	if panel_style != null:
		return panel_style

	return _get_editor_stylebox(editor_theme, BASE_STYLE_NAME, EDITOR_TYPE)


func _get_editor_stylebox(
	editor_theme: Theme,
	style_name: StringName,
	theme_type: StringName
) -> StyleBox:
	if not editor_theme.has_stylebox(style_name, theme_type):
		return null

	return editor_theme.get_stylebox(style_name, theme_type)


func _copy_accept_dialog_constant(editor_theme: Theme, constant_name: StringName) -> void:
	if not editor_theme.has_constant(constant_name, ACCEPT_DIALOG_TYPE):
		return

	add_theme_constant_override(
		constant_name,
		editor_theme.get_constant(constant_name, ACCEPT_DIALOG_TYPE)
	)


func _is_in_edited_scene() -> bool:
	if not is_inside_tree():
		return false

	var edited_scene_root: Node = get_tree().get_edited_scene_root()
	if edited_scene_root == null:
		return false

	return edited_scene_root == self or edited_scene_root.is_ancestor_of(self)


func _on_custom_instructions_warning_button_pressed() -> void:
	if custom_instructions_warning_dialog != null and is_instance_valid(custom_instructions_warning_dialog):
		custom_instructions_warning_dialog.popup_centered()
		return

	var custom_instructions_text: String = custom_instructions_edit.text.strip_edges()
	var character_count: int = custom_instructions_text.length()
	custom_instructions_warning_dialog = AcceptDialog.new()
	custom_instructions_warning_dialog.title = "Custom instructions context"
	var dialog_lines: PackedStringArray = [
		"Custom instructions are active this turn and are sent with every chat request.",
		"",
		"Current size: %s",
		"",
		"Long instructions consume context before the conversation history is selected.",
		"",
		"Priority: backend/system rules > tool safety > project instruction files such as AGENTS.md > current chat request > custom instructions."
	]
	custom_instructions_warning_dialog.dialog_text = "\n".join(dialog_lines) % _format_character_count(character_count)
	add_child(custom_instructions_warning_dialog)
	custom_instructions_warning_dialog.confirmed.connect(Callable(self, "_on_custom_instructions_warning_dialog_closed"))
	custom_instructions_warning_dialog.close_requested.connect(Callable(self, "_on_custom_instructions_warning_dialog_closed"))
	custom_instructions_warning_dialog.popup_centered()


func _on_delete_all_archived_chats_button_pressed() -> void:
	if archived_sessions.is_empty():
		return

	var session_ids: Array[String] = []
	for metadata: Dictionary in archived_sessions:
		var session_id: String = str(metadata.get("id", ""))
		if session_id.is_empty():
			continue

		session_ids.append(session_id)

	if session_ids.is_empty():
		return

	_show_archive_delete_confirmation(
		CONFIRM_ACTION_DELETE_ALL_ARCHIVED_SESSIONS,
		"Delete all archived chats?",
		"Delete all %d archived chats permanently?\n\nThis cannot be undone." % session_ids.size(),
		session_ids
	)


func _on_custom_instructions_edit_text_changed() -> void:
	_update_custom_instructions_status()


func _update_custom_instructions_status() -> void:
	if custom_instructions_edit == null or custom_instructions_warning_button == null:
		return

	var custom_instructions_text: String = custom_instructions_edit.text.strip_edges()
	var character_count: int = custom_instructions_text.length()
	var has_custom_instructions: bool = character_count > 0
	var status_text: String = _format_custom_instructions_status(character_count)

	custom_instructions_label.text = "Custom instructions (active this turn)" if has_custom_instructions else "Custom instructions"
	custom_instructions_label.tooltip_text = status_text
	custom_instructions_edit.tooltip_text = status_text
	custom_instructions_warning_button.visible = character_count >= CUSTOM_INSTRUCTIONS_WARNING_CHARS
	custom_instructions_warning_button.disabled = not has_custom_instructions
	custom_instructions_warning_button.tooltip_text = status_text


func _format_custom_instructions_status(character_count: int) -> String:
	if character_count <= 0:
		return "No custom instructions will be sent this turn."

	var status_text: String = "Custom instructions are active this turn: %s." % _format_character_count(character_count)
	if character_count >= CUSTOM_INSTRUCTIONS_HEAVY_CHARS:
		return status_text + " This is very long and will consume a noticeable amount of context every request."
	if character_count >= CUSTOM_INSTRUCTIONS_WARNING_CHARS:
		return status_text + " This is long enough to affect context usage every request."

	return status_text + " Priority: backend/system rules > tool safety > project instruction files > current chat request > custom instructions."


func _format_character_count(character_count: int) -> String:
	if character_count >= 1000:
		return "%.1fk chars" % (float(character_count) / 1000.0)

	return "%d chars" % character_count


func _get_archived_session_title(session_id: String) -> String:
	for metadata: Dictionary in archived_sessions:
		if str(metadata.get("id", "")) == session_id:
			var title_text: String = str(metadata.get("title", "Untitled")).strip_edges()
			if not title_text.is_empty():
				return title_text

	return "Untitled"


func _show_archive_delete_confirmation(
	action: StringName,
	title_text: String,
	message_text: String,
	session_ids: Array[String]
) -> void:
	if session_ids.is_empty():
		return

	_close_archive_delete_confirmation_dialog()
	pending_confirmation_action = action
	pending_delete_session_id = session_ids[0]
	pending_delete_session_ids.clear()
	for session_id: String in session_ids:
		pending_delete_session_ids.append(session_id)

	archive_delete_confirmation_dialog = ConfirmationDialog.new()
	archive_delete_confirmation_dialog.title = title_text
	archive_delete_confirmation_dialog.dialog_text = message_text
	archive_delete_confirmation_dialog.ok_button_text = "Delete"
	add_child(archive_delete_confirmation_dialog)
	archive_delete_confirmation_dialog.confirmed.connect(Callable(self, "_on_archive_delete_confirmation_confirmed"))
	archive_delete_confirmation_dialog.canceled.connect(Callable(self, "_on_archive_delete_confirmation_closed"))
	archive_delete_confirmation_dialog.close_requested.connect(Callable(self, "_on_archive_delete_confirmation_closed"))
	archive_delete_confirmation_dialog.popup_centered()


func _on_archive_delete_confirmation_confirmed() -> void:
	if pending_confirmation_action == CONFIRM_ACTION_DELETE_ARCHIVED_SESSION:
		archived_session_delete_requested.emit(pending_delete_session_id)
	elif pending_confirmation_action == CONFIRM_ACTION_DELETE_ALL_ARCHIVED_SESSIONS:
		for session_id: String in pending_delete_session_ids:
			archived_session_delete_requested.emit(session_id)

	_on_archive_delete_confirmation_closed()


func _on_archive_delete_confirmation_closed() -> void:
	pending_confirmation_action = CONFIRM_ACTION_NONE
	pending_delete_session_id = ""
	pending_delete_session_ids.clear()
	_close_archive_delete_confirmation_dialog()


func _close_archive_delete_confirmation_dialog() -> void:
	if archive_delete_confirmation_dialog == null or not is_instance_valid(archive_delete_confirmation_dialog):
		archive_delete_confirmation_dialog = null
		return

	archive_delete_confirmation_dialog.queue_free()
	archive_delete_confirmation_dialog = null


func _on_custom_instructions_warning_dialog_closed() -> void:
	if custom_instructions_warning_dialog == null or not is_instance_valid(custom_instructions_warning_dialog):
		custom_instructions_warning_dialog = null
		return

	custom_instructions_warning_dialog.queue_free()
	custom_instructions_warning_dialog = null


func _update_delete_all_archived_chats_button() -> void:
	if delete_all_archived_chats_button == null:
		return

	delete_all_archived_chats_button.disabled = archived_sessions.is_empty()
	delete_all_archived_chats_button.tooltip_text = "Delete all archived chats permanently." if not archived_sessions.is_empty() else "No archived chats to delete."


func _on_add_mcp_server_button_pressed() -> void:
	if not mcp_backend_available:
		show_mcp_error("Backend is disconnected. Reconnect before adding an MCP server.")
		return

	var packed_scene: PackedScene = load(ADD_MCP_SERVER_DIALOG_UID) as PackedScene
	if packed_scene == null:
		show_mcp_error("Add MCP server dialog could not be loaded.")
		return

	var dialog: ConfirmationDialog = packed_scene.instantiate() as ConfirmationDialog
	add_child(dialog)
	var submit_callable: Callable = Callable(self, "_on_add_mcp_server_dialog_submitted").bind(dialog)
	dialog.connect("server_config_submitted", submit_callable)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


func _on_add_mcp_server_dialog_submitted(config: Dictionary, dialog: ConfirmationDialog) -> void:
	mcp_add_pending = true
	pending_mcp_server_metadata = _create_pending_mcp_server_metadata(config)
	mcp_server_add_requested.emit(config)
	_render_mcp_servers()
	if dialog != null and is_instance_valid(dialog):
		dialog.queue_free()


func _create_pending_mcp_server_metadata(config: Dictionary) -> Dictionary:
	var metadata: Dictionary = {
		"id": "__pending_mcp_server__",
		"name": str(config.get("name", "Custom MCP")),
		"description": str(config.get("description", "")),
		"transport": str(config.get("transport", "stdio")),
		"enabled": true,
		"status": "connecting",
		"toolCount": 0,
		"pending": true
	}

	var command_text: String = str(config.get("command", "")).strip_edges()
	if not command_text.is_empty():
		metadata["command"] = command_text

	var url_text: String = str(config.get("url", "")).strip_edges()
	if not url_text.is_empty():
		metadata["url"] = url_text

	var env_value: Variant = config.get("env", {})
	if typeof(env_value) == TYPE_DICTIONARY:
		metadata["envNames"] = (env_value as Dictionary).keys()

	var headers_value: Variant = config.get("headers", {})
	if typeof(headers_value) == TYPE_DICTIONARY:
		metadata["headerNames"] = (headers_value as Dictionary).keys()

	return metadata


func _on_mcp_server_item_enabled_changed(server_id: String, enabled: bool) -> void:
	if server_id.is_empty():
		return
	if not mcp_backend_available:
		show_mcp_error("Backend is disconnected. Reconnect before changing MCP servers.")
		_render_mcp_servers()
		return

	mcp_server_enabled_requested.emit(server_id, enabled)


func _on_mcp_server_item_remove_requested(server_id: String) -> void:
	if server_id.is_empty():
		return
	if not mcp_backend_available:
		show_mcp_error("Backend is disconnected. Reconnect before removing MCP servers.")
		return

	var server_name: String = _get_mcp_server_name(server_id)
	_close_mcp_delete_confirmation_dialog()
	pending_delete_mcp_server_id = server_id
	mcp_delete_confirmation_dialog = ConfirmationDialog.new()
	mcp_delete_confirmation_dialog.title = "Remove MCP server?"
	mcp_delete_confirmation_dialog.dialog_text = "Remove custom MCP server \"%s\"?\n\nSaved env/header secrets for this server will be deleted." % server_name
	mcp_delete_confirmation_dialog.ok_button_text = "Remove"
	add_child(mcp_delete_confirmation_dialog)
	mcp_delete_confirmation_dialog.confirmed.connect(Callable(self, "_on_mcp_delete_confirmation_confirmed"))
	mcp_delete_confirmation_dialog.canceled.connect(Callable(self, "_on_mcp_delete_confirmation_closed"))
	mcp_delete_confirmation_dialog.close_requested.connect(Callable(self, "_on_mcp_delete_confirmation_closed"))
	mcp_delete_confirmation_dialog.popup_centered()


func _on_mcp_delete_confirmation_confirmed() -> void:
	if not pending_delete_mcp_server_id.is_empty():
		mcp_server_remove_requested.emit(pending_delete_mcp_server_id)

	_on_mcp_delete_confirmation_closed()


func _on_mcp_delete_confirmation_closed() -> void:
	pending_delete_mcp_server_id = ""
	_close_mcp_delete_confirmation_dialog()


func _close_mcp_delete_confirmation_dialog() -> void:
	if mcp_delete_confirmation_dialog == null or not is_instance_valid(mcp_delete_confirmation_dialog):
		mcp_delete_confirmation_dialog = null
		return

	mcp_delete_confirmation_dialog.queue_free()
	mcp_delete_confirmation_dialog = null


func _get_mcp_server_name(server_id: String) -> String:
	for metadata: Dictionary in custom_mcp_servers:
		if str(metadata.get("id", "")) == server_id:
			var server_name: String = str(metadata.get("name", "Custom MCP")).strip_edges()
			if not server_name.is_empty():
				return server_name

	return "Custom MCP"
