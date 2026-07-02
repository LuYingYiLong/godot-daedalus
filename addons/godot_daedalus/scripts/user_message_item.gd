@tool
extends MarginContainer

signal resend_requested(request_id: String, message_text: String)

const ADDITIONAL_CONTEXT_ITEM_SCENE: PackedScene = preload("uid://rfwvgjocqqva")

@onready var additional_context_viewer: ScrollContainer = %AdditionalContextViewer
@onready var additional_context_container: HBoxContainer = %AdditionalContextContainer
@onready var user_message_label: MarkdownLabel = %UserMessageLabel
@onready var text_edit: TextEdit = %TextEdit
@onready var footer_container: HBoxContainer = %FooterContainer
@onready var send_time_label: Label = %SendTimeLabel
@onready var send_button: Button = %SendButton

var request_id: String


func setup(message_text: String, message_request_id: String = "", sent_at_utc: String = "", additional_contexts: Array = []) -> void:
	request_id = message_request_id
	user_message_label.text = message_text
	_set_send_time(sent_at_utc)
	_render_additional_contexts(additional_contexts)
	text_edit.hide()
	text_edit.clear()
	send_button.hide()


func _on_mouse_entered() -> void:
	footer_container.modulate.a = 1.0


func _on_mouse_exited() -> void:
	footer_container.modulate.a = 0.0


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(user_message_label.text)


func _on_edit_button_pressed() -> void:
	user_message_label.hide()
	text_edit.text = user_message_label.text
	text_edit.show()
	send_button.show()


func _on_send_button_pressed() -> void:
	var message_text: String = text_edit.text.strip_edges()
	if message_text.is_empty():
		return

	send_button.hide()
	text_edit.hide()
	text_edit.clear()
	user_message_label.show()
	resend_requested.emit(request_id, message_text)


func _set_send_time(sent_at_utc: String) -> void:
	var normalized_sent_at: String = sent_at_utc.strip_edges()
	send_time_label.visible = not normalized_sent_at.is_empty()
	if normalized_sent_at.is_empty():
		return

	send_time_label.text = "Sent: %s" % _format_utc_time(normalized_sent_at)


func _format_utc_time(timestamp: String) -> String:
	var formatted_timestamp: String = timestamp.strip_edges()
	if formatted_timestamp.is_empty():
		return ""
	if formatted_timestamp.ends_with(" UTC"):
		return formatted_timestamp
	if formatted_timestamp.ends_with("Z"):
		formatted_timestamp = formatted_timestamp.substr(0, formatted_timestamp.length() - 1)
	var dot_index: int = formatted_timestamp.find(".")
	if dot_index >= 0:
		formatted_timestamp = formatted_timestamp.substr(0, dot_index)
	formatted_timestamp = formatted_timestamp.replace("T", " ")
	return "%s UTC" % formatted_timestamp


func _render_additional_contexts(additional_contexts: Array) -> void:
	for child: Node in additional_context_container.get_children():
		child.queue_free()

	additional_context_viewer.visible = not additional_contexts.is_empty()
	if additional_contexts.is_empty():
		return

	for context_value: Variant in additional_contexts:
		if typeof(context_value) != TYPE_DICTIONARY:
			continue

		var context_dictionary: Dictionary = context_value as Dictionary
		var context_item: Node = ADDITIONAL_CONTEXT_ITEM_SCENE.instantiate()
		additional_context_container.add_child(context_item)
		context_item.call("setup", context_dictionary)
		if context_item.has_method("set_interactive"):
			context_item.call("set_interactive", false)
