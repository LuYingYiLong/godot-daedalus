@tool
extends Button

@onready var title_label: Label = %TitleLabel
@onready var loader_icon: TextureRect = %LoaderIcon
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var relative_time_label: Label = %RelativeTimeLabel

var session_id: String = ""


func setup(item_session_id: String, title_text: String, relative_time_text: String) -> void:
	session_id = item_session_id
	title_label.text = title_text
	relative_time_label.text = relative_time_text
	set_loading(false)


func set_loading(is_loading: bool) -> void:
	loader_icon.visible = is_loading

	if is_loading:
		animation_player.play("loading")
	else:
		animation_player.stop()
