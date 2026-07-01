@tool
extends HBoxContainer

const TODO_UNCHECKED_ICON: Texture2D = preload("uid://6mfyj4c6motv")
const TODO_RUNNING_ICON: Texture2D = preload("uid://p6usuyfrlohx")
const TODO_CHECKED_ICON: Texture2D = preload("uid://cxkgwdaoj5cq2")

@onready var icon: TextureRect = %Icon
@onready var todo_label: Label = %TodoLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var todo_text: String = "Todo"
var todo_icon: Texture2D = TODO_UNCHECKED_ICON


func _ready() -> void:
	_apply_state()


func setup(item_text: String, item_icon: Texture2D) -> void:
	todo_text = item_text
	todo_icon = item_icon
	if is_node_ready():
		_apply_state()


func setup_status(item_text: String, status: String) -> void:
	setup(item_text, _get_icon_for_status(status))


func _get_icon_for_status(status: String) -> Texture2D:
	if status == "done":
		return TODO_CHECKED_ICON
	if status == "running":
		return TODO_RUNNING_ICON

	return TODO_UNCHECKED_ICON


func _apply_state() -> void:
	todo_label.text = todo_text
	icon.texture = todo_icon
	if todo_icon == TODO_RUNNING_ICON:
		animation_player.play("running")
	else:
		animation_player.play("RESET")
