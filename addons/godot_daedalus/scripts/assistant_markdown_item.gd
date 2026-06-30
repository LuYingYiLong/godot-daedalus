@tool
extends MarginContainer

@onready var markdown_label: MarkdownLabel = $MarkdownLabel


func clear_message() -> void:
	markdown_label.clear()


func append_delta(delta_text: String) -> void:
	markdown_label.append_text(delta_text)


func finish_message() -> void:
	markdown_label.finish_stream()


func setup(message_text: String) -> void:
	markdown_label.clear()
	markdown_label.append_text(message_text)
	markdown_label.finish_stream()
