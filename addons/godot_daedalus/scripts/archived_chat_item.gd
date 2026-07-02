@tool
extends HBoxContainer

signal restore_requested(session_id: String)
signal delete_requested(session_id: String)

@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var unarchive_button: Button = %UnarchiveButton
@onready var delete_button: Button = %DeleteButton

var session_id: String


func setup(item_session_id: String, title_text: String, time_text: String) -> void:
	session_id = item_session_id
	title_label.text = title_text
	time_label.text = time_text


func _on_mouse_entered() -> void:
	unarchive_button.show()
	delete_button.show()


func _on_mouse_exited() -> void:
	unarchive_button.hide()
	delete_button.hide()


func _on_unarchive_button_pressed() -> void:
	restore_requested.emit(session_id)


func _on_delete_button_pressed() -> void:
	delete_requested.emit(session_id)
