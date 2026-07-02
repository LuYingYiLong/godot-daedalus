extends HBoxContainer

@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var unarchive_button: Button = %UnarchiveButton
@onready var delete_button: Button = %DeleteButton


func _on_mouse_entered() -> void:
	unarchive_button.show()
	delete_button.show()


func _on_mouse_exited() -> void:
	unarchive_button.hide()
	delete_button.hide()
