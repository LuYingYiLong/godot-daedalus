@tool
extends AcceptDialog

signal provider_config_save_requested(api_key: String)
signal provider_config_clear_requested
signal frontend_config_save_requested(backend_url: String, custom_instructions: String)
signal archived_session_restore_requested(session_id: String)
signal archived_session_delete_requested(session_id: String)

@onready var provider_option_button: OptionButton = %ProviderOptionButton
@onready var backend_url_line_edit: LineEdit = %BackendURLLineEdit
@onready var deepseek_api_key_line_edit: LineEdit = %DeepseekAPIKeyLineEdit
@onready var clear_deepseek_api_key_button: Button = %ClearDeepseekAPIKeyButton
@onready var custom_instructions_edit: TextEdit = %CustomInstructionsEdit
@onready var archived_workspace_filter_option_button: OptionButton = %WorkspaceFilterOptionButton
@onready var search_archived_chat_line_edit: LineEdit = %SearchArchivedChatLineEdit
@onready var archived_chat_list: VBoxContainer = %ArchivedChatList

const ARCHIVED_CHAT_ITEM_SCENE_UID: String = "uid://kyksk24wd7d3"
const EDITOR_TYPE: StringName = &"Editor"
const ACCEPT_DIALOG_TYPE: StringName = &"AcceptDialog"
const EDITOR_SETTINGS_DIALOG_TYPE: StringName = &"EditorSettingsDialog"
const PANEL_STYLE_NAME: StringName = &"panel"
const BASE_STYLE_NAME: StringName = &"base_style"
const BUTTONS_SEPARATION_CONSTANT: StringName = &"buttons_separation"
const BUTTONS_MIN_WIDTH_CONSTANT: StringName = &"buttons_min_width"
const BUTTONS_MIN_HEIGHT_CONSTANT: StringName = &"buttons_min_height"

var archived_sessions: Array[Dictionary] = []
var archived_workspaces_by_id: Dictionary[String, Dictionary] = {}
var archived_workspace_filter: String
var archived_search_text: String


func _ready() -> void:
	call_deferred(&"_apply_editor_dialog_theme")


func setup_provider_config(status: Dictionary, frontend_config: Dictionary = {}) -> void:
	var configured: bool = bool(status.get("configured", false))
	backend_url_line_edit.text = str(frontend_config.get("backendUrl", "ws://localhost:8080"))
	custom_instructions_edit.text = str(frontend_config.get("customInstructions", ""))

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


func _on_confirmed() -> void:
	var api_key: String = deepseek_api_key_line_edit.text.strip_edges()
	frontend_config_save_requested.emit(
		backend_url_line_edit.text.strip_edges(),
		custom_instructions_edit.text.strip_edges()
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
	archived_session_delete_requested.emit(session_id)


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
