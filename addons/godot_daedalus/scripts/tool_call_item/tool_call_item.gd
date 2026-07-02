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
	var event_data: Dictionary = {
		"toolName": tool_name_text,
		"summary": detail_text
	}
	var display_event: Dictionary = _normalize_tool_event(event_data)
	tool_name = str(display_event.get("toolName", tool_name_text))
	foldable_container.title = _format_foldable_title(display_event)
	_add_unknown_item(str(display_event.get("title", _localize_tool_name(tool_name))), str(display_event.get("summary", detail_text)))


func setup_tool_event(event_data: Dictionary) -> void:
	var display_event: Dictionary = _normalize_tool_event(event_data)
	tool_call_id = str(display_event.get("toolCallId", ""))
	tool_name = str(display_event.get("toolName", "tool"))
	foldable_container.title = _format_foldable_title(display_event)
	_clear_thinking_state()

	for child: Node in item_container.get_children():
		child.queue_free()

	_add_item_for_event(display_event)


func setup_thinking() -> void:
	tool_name = "Thinking"
	foldable_container.title = "Thinking"
	_clear_thinking_state()

	for child: Node in item_container.get_children():
		child.queue_free()

	_add_thinking_summary_item()


func append_tool_event(event_data: Dictionary) -> void:
	var display_event: Dictionary = _normalize_tool_event(event_data)
	var event_type: String = str(display_event.get("type", ""))
	if event_type == "tool.result":
		_add_result_item(display_event)
		_set_folded(true)
	elif event_type == "tool.error":
		_add_error_item(display_event)
		_set_folded(true)
	elif event_type == "tool.approval_required":
		_add_approval_item(display_event)
	else:
		_add_item_for_event(display_event)
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
	elif category == "propose":
		_add_unknown_item(str(event_data.get("title", "预览修改")), str(event_data.get("summary", _summarize_event(event_data))))
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
		var action_text: String = str(event_data.get("title", verb))
		button.text = "%s：%s" % [action_text, file_path]
		button.tooltip_text = "打开 %s" % file_path
		button.pressed.connect(_on_file_link_pressed.bind(file_path))


func _add_scene_item(event_data: Dictionary) -> void:
	var item: Node = SCENE_EDIT_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var target: Dictionary = _get_target(event_data)
	var scene_path: String = _get_target_path(target)
	var button: LinkButton = item.get_node_or_null("%DetailsButton") as LinkButton
	if button != null:
		button.text = "%s：%s" % [str(event_data.get("title", "场景")), scene_path]
		button.tooltip_text = "打开 %s" % scene_path
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
		button.text = "等待审批：%s" % _format_foldable_title(event_data)
		button.tooltip_text = "审批 ID：%s\n%s" % [approval_id, str(event_data.get("reason", "需要审批"))]


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
	_add_unknown_item("完成", "返回 %d 字符%s" % [result_chars, suffix])


func _add_error_item(event_data: Dictionary) -> void:
	_add_unknown_item("失败", str(event_data.get("message", "")))


func _add_unknown_item(title_text: String, detail_text: String) -> void:
	var item: Node = UNKNOWN_ITEM_SCENE.instantiate()
	item_container.add_child(item)

	var label: Label = item.get_node_or_null("%DetailsLabel") as Label
	if label != null:
		var display_title: String = _localize_tool_name(title_text)
		var display_detail: String = _format_unknown_detail(detail_text)
		if display_detail.is_empty():
			label.text = display_title
		else:
			label.text = "%s：%s" % [display_title, display_detail]


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
		return _format_unknown_detail(summary_text)

	var args_value: Variant = event_data.get("args", {})
	if typeof(args_value) == TYPE_DICTIONARY:
		var args: Dictionary = args_value as Dictionary
		if args.is_empty():
			return ""
		return JSON.stringify(args, "\t")

	return _localize_tool_name(tool_name)


func _normalize_tool_event(event_data: Dictionary) -> Dictionary:
	var display_event: Dictionary = event_data.duplicate(true)
	var normalized_tool_name: String = _normalize_tool_name(str(display_event.get("toolName", "")))
	if normalized_tool_name.is_empty():
		normalized_tool_name = _normalize_tool_name(str(display_event.get("llmToolName", "")))
	if normalized_tool_name.is_empty():
		normalized_tool_name = "tool"

	display_event["toolName"] = normalized_tool_name
	var args: Dictionary = _get_args(display_event)
	var target: Dictionary = _get_target(display_event)
	if target.is_empty() or str(target.get("kind", "unknown")) == "unknown":
		target = _infer_target(normalized_tool_name, args)
		if not target.is_empty():
			display_event["target"] = target

	var category: String = str(display_event.get("category", ""))
	if category.is_empty() or category == "unknown":
		display_event["category"] = _infer_category(normalized_tool_name, target)

	var title: String = str(display_event.get("title", ""))
	if title.is_empty() or _looks_like_internal_tool_name(title):
		display_event["title"] = _localize_tool_name(normalized_tool_name)

	var summary: String = str(display_event.get("summary", ""))
	if summary.is_empty() or _looks_like_internal_tool_name(summary):
		display_event["summary"] = _build_tool_summary(normalized_tool_name, display_event)

	return display_event


func _normalize_tool_name(raw_tool_name: String) -> String:
	var normalized_name: String = raw_tool_name.strip_edges()
	if normalized_name.is_empty():
		return ""
	if normalized_name.begins_with("mcp_"):
		return normalized_name

	match normalized_name:
		"get_project_summary":
			return "mcp_godot_get_project_summary"
		"list_project_files":
			return "mcp_godot_list_project_files"
		"list_scenes":
			return "mcp_godot_list_scenes"
		"list_scripts":
			return "mcp_godot_list_scripts"
		"read_text_file":
			return "mcp_godot_read_text_file"
		"search_text":
			return "mcp_godot_search_text"
		"create_text_file":
			return "mcp_godot_create_text_file"
		"overwrite_text_file":
			return "mcp_godot_overwrite_text_file"
		"replace_text_in_file":
			return "mcp_godot_replace_text_in_file"
		"delete_file":
			return "mcp_godot_delete_file"
		"inspect_scene_tree":
			return "mcp_godot_inspect_scene_tree"
		"create_scene":
			return "mcp_godot_create_scene"
		"apply_scene_patch":
			return "mcp_godot_apply_scene_patch"
		"run_safe_preset":
			return "mcp_terminal_run_safe_preset"
		"run_write_preset":
			return "mcp_terminal_run_write_preset"
		"run_godot_scene_script":
			return "mcp_terminal_run_godot_scene_script"

	return normalized_name


func _localize_tool_name(raw_tool_name: String) -> String:
	var normalized_tool_name: String = _normalize_tool_name(raw_tool_name)
	match normalized_tool_name:
		"mcp_godot_get_project_summary":
			return "读取项目摘要"
		"mcp_godot_list_project_files":
			return "列出项目文件"
		"mcp_godot_list_scenes":
			return "列出场景"
		"mcp_godot_list_scripts":
			return "列出脚本"
		"mcp_godot_read_text_file":
			return "读取文件"
		"mcp_godot_search_text":
			return "搜索文本"
		"mcp_godot_propose_create_text_file":
			return "预览创建文件"
		"mcp_godot_create_text_file":
			return "创建文件"
		"mcp_godot_propose_overwrite_text_file":
			return "预览覆盖文件"
		"mcp_godot_overwrite_text_file":
			return "覆盖文件"
		"mcp_godot_propose_replace_text_in_file":
			return "预览替换文件内容"
		"mcp_godot_replace_text_in_file":
			return "替换文件内容"
		"mcp_godot_delete_file":
			return "删除文件"
		"mcp_godot_inspect_scene_tree":
			return "查看场景树"
		"mcp_godot_propose_create_scene":
			return "预览创建场景"
		"mcp_godot_create_scene":
			return "创建场景"
		"mcp_godot_propose_add_node_to_scene":
			return "预览添加场景节点"
		"mcp_godot_add_node_to_scene":
			return "添加场景节点"
		"mcp_godot_propose_attach_script_to_node":
			return "预览挂载脚本"
		"mcp_godot_attach_script_to_node":
			return "挂载脚本"
		"mcp_godot_propose_connect_signal_in_scene":
			return "预览连接信号"
		"mcp_godot_connect_signal_in_scene":
			return "连接信号"
		"mcp_godot_propose_apply_scene_patch":
			return "预览批量编辑场景"
		"mcp_godot_apply_scene_patch":
			return "批量编辑场景"
		"mcp_terminal_get_capabilities":
			return "读取终端能力"
		"mcp_terminal_run_safe_preset":
			return "运行验证命令"
		"mcp_terminal_run_write_preset":
			return "运行写入命令"
		"mcp_terminal_run_godot_scene_script":
			return "执行场景脚本"

	if _looks_like_internal_tool_name(normalized_tool_name):
		return "内部工具"

	return normalized_tool_name


func _infer_category(normalized_tool_name: String, target: Dictionary) -> String:
	if normalized_tool_name.contains("search_text"):
		return "search"
	if normalized_tool_name.contains("propose_"):
		return "propose"
	if normalized_tool_name.begins_with("mcp_terminal_"):
		if normalized_tool_name == "mcp_terminal_run_godot_scene_script":
			return "scene"
		return "terminal"
	if normalized_tool_name.contains("scene") or str(target.get("kind", "")) == "scene":
		if normalized_tool_name.contains("inspect"):
			return "read"
		return "scene"
	if normalized_tool_name.contains("create_") or normalized_tool_name.contains("overwrite_") or normalized_tool_name.contains("replace_") or normalized_tool_name.contains("delete_") or normalized_tool_name.contains("write_"):
		return "write"
	if normalized_tool_name.contains("read_") or normalized_tool_name.contains("list_") or normalized_tool_name.contains("get_project"):
		return "read"

	return "unknown"


func _infer_target(normalized_tool_name: String, args: Dictionary) -> Dictionary:
	var path_text: String = _get_first_string_arg(args, ["relativePath", "scenePath", "path"])
	if path_text.is_empty() and normalized_tool_name == "mcp_terminal_run_godot_scene_script":
		path_text = _get_scene_path_from_operation_json(args)

	if not path_text.is_empty():
		var target_kind: String = "scene" if path_text.ends_with(".tscn") or normalized_tool_name.contains("scene") else "file"
		return {
			"kind": target_kind,
			"path": path_text,
			"label": path_text
		}

	if normalized_tool_name.contains("search_text"):
		var query: String = _get_first_string_arg(args, ["query"])
		return {
			"kind": "query",
			"label": query
		}

	if normalized_tool_name.begins_with("mcp_terminal_"):
		var preset_name: String = _get_first_string_arg(args, ["presetName"])
		return {
			"kind": "command",
			"label": preset_name
		}

	return {}


func _build_tool_summary(normalized_tool_name: String, event_data: Dictionary) -> String:
	var title: String = str(event_data.get("title", _localize_tool_name(normalized_tool_name)))
	var target: Dictionary = _get_target(event_data)
	var target_text: String = str(target.get("label", target.get("path", ""))).strip_edges()
	if not target_text.is_empty():
		return "%s %s" % [title, target_text]

	var args: Dictionary = _get_args(event_data)
	if not args.is_empty():
		var query: String = _get_first_string_arg(args, ["query", "presetName"])
		if not query.is_empty():
			return "%s %s" % [title, query]

	return title


func _format_foldable_title(event_data: Dictionary) -> String:
	var title: String = str(event_data.get("title", _localize_tool_name(str(event_data.get("toolName", "tool")))))
	var target: Dictionary = _get_target(event_data)
	var target_text: String = str(target.get("label", target.get("path", ""))).strip_edges()
	if target_text.is_empty() or title.contains(target_text):
		return title

	return "%s · %s" % [title, target_text]


func _get_args(event_data: Dictionary) -> Dictionary:
	var args_value: Variant = event_data.get("args", {})
	if typeof(args_value) == TYPE_DICTIONARY:
		return args_value as Dictionary

	return {}


func _get_first_string_arg(args: Dictionary, keys: Array[String]) -> String:
	for key: String in keys:
		var value: Variant = args.get(key, "")
		if typeof(value) == TYPE_STRING and not str(value).strip_edges().is_empty():
			return str(value).strip_edges()

	return ""


func _get_scene_path_from_operation_json(args: Dictionary) -> String:
	var operation_json: String = _get_first_string_arg(args, ["operationJson"])
	if operation_json.is_empty():
		return ""

	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(operation_json)
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return ""

	var operation: Dictionary = json.data as Dictionary
	return _get_first_string_arg(operation, ["scene_path", "scenePath", "path"])


func _format_unknown_detail(detail_text: String) -> String:
	var normalized_detail: String = detail_text.strip_edges()
	if normalized_detail == "{}" or normalized_detail == "[]":
		return ""
	if _looks_like_internal_tool_name(normalized_detail):
		var colon_index: int = normalized_detail.find(":")
		if colon_index >= 0:
			var suffix_text: String = normalized_detail.substr(colon_index + 1).strip_edges()
			if suffix_text.is_empty() or suffix_text == "{}" or suffix_text == "[]":
				return ""
			return suffix_text
		return ""

	return normalized_detail


func _looks_like_internal_tool_name(text: String) -> bool:
	var normalized_text: String = text.strip_edges()
	return normalized_text.begins_with("mcp_") or normalized_text.contains("mcp_godot_") or normalized_text.contains("mcp_terminal_")


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
