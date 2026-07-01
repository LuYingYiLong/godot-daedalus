@tool
extends MarginContainer

signal content_height_changed

const READ_ITEM_SCENE: PackedScene = preload("uid://dwi5h81jkortw")
const WRITE_ITEM_SCENE: PackedScene = preload("uid://c0all82wnhv1l")
const TERMINAL_ITEM_SCENE: PackedScene = preload("uid://c1ougymen6yqh")
const SCENE_EDIT_ITEM_SCENE: PackedScene = preload("uid://b2qcnd4eg8gwd")
const APPROVAL_ITEM_SCENE: PackedScene = preload("uid://c0fteh4alx02y")
const THINKING_ITEM_SCENE: PackedScene = preload("uid://bc6odrlupcfyr")
const UNKNOWN_ITEM_SCENE: PackedScene = preload("uid://b5esov6oww3y3")
const SEARCH_ITEM_SCENE: PackedScene = preload("uid://dxmloi863owr8")

@onready var foldable_container: FoldableContainer = $FoldableContainer
@onready var item_container: VBoxContainer = %ItemContainer

var target_path: String
var tool_call_id: String
var tool_name: String
var thinking_text: String
var thinking_finished: bool
var thinking_markdown_loaded: bool
var thinking_summary_label: Label
var thinking_show_button: Button
var thinking_markdown_label: MarkdownLabel


func _ready() -> void:
	for child: Node in item_container.get_children():
		child.queue_free()


func setup(tool_name_text: String, detail_text: String) -> void:
	tool_name = tool_name_text
	foldable_container.title = tool_name_text
	_add_unknown_item(tool_name_text, detail_text)


func setup_tool_event(event_data: Dictionary) -> void:
	tool_call_id = str(event_data.get("toolCallId", ""))
	tool_name = str(event_data.get("toolName", "tool"))
	foldable_container.title = str(event_data.get("title", tool_name))
	_clear_thinking_state()

	for child: Node in item_container.get_children():
		child.queue_free()

	_add_item_for_event(event_data)


func setup_thinking() -> void:
	tool_name = "Thinking"
	foldable_container.title = "Thinking"
	_clear_thinking_state()

	for child: Node in item_container.get_children():
		child.queue_free()

	_add_thinking_summary_item()


func append_tool_event(event_data: Dictionary) -> void:
	var event_type: String = str(event_data.get("type", ""))
	if event_type == "tool.result":
		_add_result_item(event_data)
		_set_folded(true)
	elif event_type == "tool.error":
		_add_error_item(event_data)
		_set_folded(true)
	elif event_type == "tool.approval_required":
		_add_approval_item(event_data)
	else:
		_add_item_for_event(event_data)
	content_height_changed.emit()


func append_detail(detail_text: String) -> void:
	_add_unknown_item(tool_name, detail_text)


func append_thinking_delta(text: String) -> void:
	if thinking_summary_label == null:
		setup_thinking()

	thinking_text += text
	_update_thinking_summary()
	if thinking_markdown_loaded and thinking_markdown_label != null:
		thinking_markdown_label.append_text(text)


func finish_thinking() -> void:
	thinking_finished = true
	_update_thinking_summary()
	if thinking_markdown_loaded and thinking_markdown_label != null:
		thinking_markdown_label.finish_stream()
	_set_folded(true)


func _set_folded(is_folded: bool) -> void:
	for property: Dictionary in foldable_container.get_property_list():
		var property_name: String = str(property.get("name", ""))
		if property_name == "folded" or property_name == "collapsed":
			foldable_container.set(property_name, is_folded)
			return
		if property_name == "expanded":
			foldable_container.set(property_name, not is_folded)
			return


func _add_item_for_event(event_data: Dictionary) -> void:
	var category: String = str(event_data.get("category", "unknown"))
	var target: Dictionary = _get_target(event_data)
	var target_kind: String = str(target.get("kind", "unknown"))

	if category == "read" and target_kind == "file":
		_add_file_link_item(READ_ITEM_SCENE, event_data, "Read")
	elif category == "write":
		_add_file_link_item(WRITE_ITEM_SCENE, event_data, "Write")
	elif category == "search" or category == "docs":
		_add_search_item(event_data)
	elif category == "terminal":
		_add_terminal_item(event_data)
	elif category == "scene" or target_kind == "scene":
		_add_scene_item(event_data)
	elif category == "approval":
		_add_approval_item(event_data)
	else:
		_add_unknown_item(str(event_data.get("title", tool_name)), _summarize_event(event_data))


func _add_file_link_item(scene: PackedScene, event_data: Dictionary, verb: String) -> void:
	var item: Node = scene.instantiate()
	item_container.add_child(item)

	var target: Dictionary = _get_target(event_data)
	var file_path: String = _get_target_path(target)
	var button: LinkButton = item.get_node_or_null("%DetailsButton") as LinkButton
	if button != null:
		button.text = "%s: %s" % [verb, file_path]
		button.tooltip_text = "Open %s" % file_path
		button.pressed.connect(_on_file_link_pressed.bind(file_path))


func _add_scene_item(event_data: Dictionary) -> void:
	var item: Node = SCENE_EDIT_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var target: Dictionary = _get_target(event_data)
	var scene_path: String = _get_target_path(target)
	var button: LinkButton = item.get_node_or_null("%DetailsButton") as LinkButton
	if button != null:
		button.text = "%s: %s" % [str(event_data.get("title", "Scene")), scene_path]
		button.tooltip_text = "Open %s" % scene_path
		button.pressed.connect(_on_file_link_pressed.bind(scene_path))


func _add_search_item(event_data: Dictionary) -> void:
	var item: Node = SEARCH_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var label: Label = item.get_node_or_null("DetailsLabel") as Label
	if label != null:
		label.text = str(event_data.get("summary", _summarize_event(event_data)))


func _add_terminal_item(event_data: Dictionary) -> void:
	var item: Node = TERMINAL_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var label: RichTextLabel = item.get_node_or_null("%TerminalLogLabel") as RichTextLabel
	if label != null:
		label.text = str(event_data.get("summary", _summarize_event(event_data)))


func _add_approval_item(event_data: Dictionary) -> void:
	var item: Node = APPROVAL_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var button: LinkButton = item.get_node_or_null("%DetailsButton") as LinkButton
	if button != null:
		var approval_id: String = str(event_data.get("approvalId", ""))
		button.text = "Approval required: %s" % approval_id
		button.tooltip_text = str(event_data.get("reason", "Needs approval"))


func _clear_thinking_state() -> void:
	thinking_text = ""
	thinking_finished = false
	thinking_markdown_loaded = false
	thinking_summary_label = null
	thinking_show_button = null
	thinking_markdown_label = null


func _add_thinking_summary_item() -> void:
	var summary_row: HBoxContainer = HBoxContainer.new()
	summary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.add_child(summary_row)

	thinking_summary_label = Label.new()
	thinking_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(thinking_summary_label)

	thinking_show_button = Button.new()
	thinking_show_button.text = "查看"
	thinking_show_button.focus_mode = Control.FOCUS_NONE
	thinking_show_button.pressed.connect(_on_show_thinking_button_pressed)
	summary_row.add_child(thinking_show_button)

	_update_thinking_summary()


func _update_thinking_summary() -> void:
	if thinking_summary_label == null:
		return

	var status_text: String = "已完成" if thinking_finished else "思考中"
	thinking_summary_label.text = "%s · %d 字符" % [status_text, thinking_text.length()]
	if thinking_show_button != null:
		thinking_show_button.visible = thinking_text.length() > 0
		thinking_show_button.disabled = thinking_markdown_loaded
		thinking_show_button.text = "已显示" if thinking_markdown_loaded else "查看"


func _on_show_thinking_button_pressed() -> void:
	if thinking_markdown_loaded:
		return

	thinking_markdown_loaded = true
	var item: Node = THINKING_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var label: MarkdownLabel = item.get_node_or_null("%MessageLabel") as MarkdownLabel
	if label != null:
		label.clear()
		label.append_text(thinking_text)
		if thinking_finished:
			label.finish_stream()
		thinking_markdown_label = label
	_update_thinking_summary()
	content_height_changed.emit()


func _add_result_item(event_data: Dictionary) -> void:
	var result_chars: int = int(event_data.get("resultChars", 0))
	var truncated: bool = bool(event_data.get("truncated", false))
	var suffix: String = "，已截断" if truncated else ""
	_add_unknown_item("Result", "Result chars: %d%s" % [result_chars, suffix])


func _add_error_item(event_data: Dictionary) -> void:
	_add_unknown_item("Error", str(event_data.get("message", "")))


func _add_unknown_item(title_text: String, detail_text: String) -> void:
	var item: Node = UNKNOWN_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var label: Label = item.get_node_or_null("%DetailsLabel") as Label
	if label != null:
		if detail_text.is_empty():
			label.text = title_text
		else:
			label.text = "%s: %s" % [title_text, detail_text]


func _get_target(event_data: Dictionary) -> Dictionary:
	var target_value: Variant = event_data.get("target", {})
	if typeof(target_value) == TYPE_DICTIONARY:
		return target_value as Dictionary

	return {}


func _get_target_path(target: Dictionary) -> String:
	var path_text: String = str(target.get("path", ""))
	if path_text.is_empty():
		path_text = str(target.get("label", "unknown"))
	return path_text


func _summarize_event(event_data: Dictionary) -> String:
	var summary_text: String = str(event_data.get("summary", ""))
	if not summary_text.is_empty():
		return summary_text

	var args_value: Variant = event_data.get("args", {})
	if typeof(args_value) == TYPE_DICTIONARY:
		return JSON.stringify(args_value, "\t")

	return tool_name


func _on_file_link_pressed(relative_path: String) -> void:
	if relative_path.is_empty():
		return

	var resource_path: String = relative_path
	if not resource_path.begins_with("res://"):
		resource_path = "res://%s" % relative_path.trim_prefix("/")

	var resource: Resource = load(resource_path)
	if resource != null and Engine.is_editor_hint():
		EditorInterface.edit_resource(resource)
		return

	OS.shell_open(ProjectSettings.globalize_path(resource_path))
