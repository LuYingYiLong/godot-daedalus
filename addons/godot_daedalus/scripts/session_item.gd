@tool
extends Button

signal open_requested(session_id: String)
signal archive_requested(session_id: String)

@onready var title_label: Label = %TitleLabel
@onready var loader_icon: TextureRect = %LoaderIcon
@onready var archive_button: Button = %ArchiveButton
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var relative_time_label: Label = %RelativeTimeLabel

var session_id: String
var suppress_next_open: bool


func setup(item_session_id: String, title_text: String, relative_time_text: String) -> void:
	session_id = item_session_id
	title_label.text = title_text
	relative_time_label.text = relative_time_text
	set_loading(false)


func set_loading(is_loading: bool) -> void:
	loader_icon.visible = is_loading

	if is_loading:
		animation_player.play(&"running")
	else:
		animation_player.stop()


func _on_mouse_entered() -> void:
	archive_button.show()


func _on_mouse_exited() -> void:
	var button_rect: Rect2 = archive_button.get_rect()
	if button_rect.has_point(get_local_mouse_position()): return
	archive_button.hide()


func _on_archive_button_pressed() -> void:
	suppress_next_open = true
	archive_requested.emit(session_id)
	archive_button.hide()


func _on_pressed() -> void:
	if suppress_next_open:
		suppress_next_open = false
		return

	open_requested.emit(session_id)
