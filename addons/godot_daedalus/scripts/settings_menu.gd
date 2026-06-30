@tool
extends AcceptDialog

signal provider_config_save_requested(api_key: String)
signal provider_config_clear_requested

@onready var deepseek_api_key_line_edit: LineEdit = $GridContainer/HBoxContainer/DeepseekAPIKeyLineEdit
@onready var clear_deepseek_api_key_button: Button = $GridContainer/HBoxContainer/ClearDeepseekAPIKeyButton
@onready var provider_option_button: OptionButton = $GridContainer/ProviderOptionButton

func _ready() -> void:
	show()

func setup_provider_config(status: Dictionary) -> void:
	var configured: bool = bool(status.get("configured", false))

	if configured:
		deepseek_api_key_line_edit.placeholder_text = "Set new API key"
	else:
		deepseek_api_key_line_edit.placeholder_text = "Set API key"

	clear_deepseek_api_key_button.disabled = not configured
	provider_option_button.disabled = true


func _on_confirmed() -> void:
	var api_key: String = deepseek_api_key_line_edit.text.strip_edges()
	provider_config_save_requested.emit(api_key)
	queue_free()


func _on_clear_deepseek_api_key_button_pressed() -> void:
	provider_config_clear_requested.emit()
	queue_free()


func _on_close_requested() -> void:
	queue_free()
