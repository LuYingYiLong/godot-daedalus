@tool
extends MarginContainer

@onready var user_message_label: MarkdownLabel = $PanelContainer/UserMessageLabel


func setup(message_text: String) -> void:
	user_message_label.text = message_text
