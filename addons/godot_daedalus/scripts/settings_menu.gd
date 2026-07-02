@tool
extends AcceptDialog

signal provider_config_save_requested(api_key: String)
signal provider_config_clear_requested
signal frontend_config_save_requested(backend_url: String, custom_instructions: String)

@onready var provider_option_button: OptionButton = %ProviderOptionButton
@onready var backend_url_line_edit: LineEdit = %BackendURLLineEdit
@onready var deepseek_api_key_line_edit: LineEdit = %DeepseekAPIKeyLineEdit
@onready var clear_deepseek_api_key_button: Button = %ClearDeepseekAPIKeyButton
@onready var custom_instructions_edit: TextEdit = %CustomInstructionsEdit

const EDITOR_TYPE: StringName = &"Editor"
const ACCEPT_DIALOG_TYPE: StringName = &"AcceptDialog"
const EDITOR_SETTINGS_DIALOG_TYPE: StringName = &"EditorSettingsDialog"
const PANEL_STYLE_NAME: StringName = &"panel"
const BASE_STYLE_NAME: StringName = &"base_style"
const BUTTONS_SEPARATION_CONSTANT: StringName = &"buttons_separation"
const BUTTONS_MIN_WIDTH_CONSTANT: StringName = &"buttons_min_width"
const BUTTONS_MIN_HEIGHT_CONSTANT: StringName = &"buttons_min_height"


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
