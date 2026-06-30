@tool
extends MarginContainer

@onready var foldable_container: FoldableContainer = $FoldableContainer


func setup(tool_name: String, detail_text: String) -> void:
	foldable_container.title = tool_name
	#detail_label.text = detail_text


func append_detail(detail_text: String) -> void:
	#if not detail_label.text.is_empty():
		#detail_label.text += "\n\n"
#
	#detail_label.text += detail_text
	pass
