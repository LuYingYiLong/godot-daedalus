@tool
extends PanelContainer

signal action_requested(action_id: String)

const CONNECTED_ICON: Texture2D = preload("uid://1eh7wxaewfje")
const CONNECT_FAILED_ICON: Texture2D = preload("uid://chihcwe7t0f2g")
const DISCONNECTED_ICON: Texture2D = preload("uid://cq15q550jtb21")
const RELOAD_ICON: Texture2D = preload("uid://d2wspeualsu1d")
const STATUS_WARNING_ICON: Texture2D = preload("uid://gytxgaev43it")

const STATUS_MESSAGE: String = "message"
const STATUS_WARNING: String = "warning"
const STATUS_ERROR: String = "error"
const STATUS_SUCCESS: String = "success"
const STATUS_RECONNECTING: String = "reconnecting"

@onready var status_icon: TextureRect = %StatusIcon
@onready var title_label: Label = %TitleLabel
@onready var details_label: Label = %DetailsLabel
@onready var action_button: Button = %ActionButton

var current_status: String = STATUS_MESSAGE
var current_title: String
var current_details: String
var current_action_label: String
var current_action_id: String


func _ready() -> void:
	_apply_status()


func setup(status_text: String, title_text: String, details_text: String, action_label: String = "", action_id: String = "") -> void:
	current_status = status_text
	current_title = title_text
	current_details = details_text
	current_action_label = action_label
	current_action_id = action_id
	_apply_status()


func _apply_status() -> void:
	if not is_inside_tree():
		return
	if status_icon == null or title_label == null or details_label == null or action_button == null:
		return

	title_label.text = current_title
	details_label.text = current_details
	details_label.visible = not current_details.strip_edges().is_empty()
	status_icon.texture = _get_status_icon()
	action_button.visible = not current_action_label.strip_edges().is_empty()
	action_button.text = current_action_label
	action_button.icon = RELOAD_ICON if current_action_id == "reconnect" else null
	action_button.disabled = current_action_id.strip_edges().is_empty()


func _get_status_icon() -> Texture2D:
	match current_status:
		STATUS_ERROR:
			return CONNECT_FAILED_ICON
		STATUS_SUCCESS:
			return CONNECTED_ICON
		STATUS_RECONNECTING:
			return RELOAD_ICON
		STATUS_WARNING:
			return STATUS_WARNING_ICON

	return DISCONNECTED_ICON


func _on_action_button_pressed() -> void:
	if current_action_id.strip_edges().is_empty():
		return

	action_requested.emit(current_action_id)
