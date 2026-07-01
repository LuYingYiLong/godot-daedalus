extends PanelContainer

@export var error_panel: StyleBox
@export var message_panel: StyleBox

@export_multiline() var text: String
@export_enum("Message", "Error") var status: int

@onready var label: Label = %Label


func _ready() -> void:
	pass # Replace with function body.
