@tool
extends CenterContainer

signal reconnect_requested

@onready var error_container: VBoxContainer = %ErrorContainer
@onready var error_label: Label = %ErrorLabel
@onready var error_details_label: Label = %ErrorDetailsLabel


func _ready() -> void:
	error_container.hide()


func show_connecting() -> void:
	error_container.hide()


func show_error(title: String, details: String) -> void:
	error_label.text = title
	error_details_label.text = details
	error_container.show()


func _on_reconnect_button_pressed() -> void:
	reconnect_requested.emit()
