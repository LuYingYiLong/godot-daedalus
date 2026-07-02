@tool
extends MarginContainer

const TOOL_CALL_ITEM_SCENE: PackedScene = preload("uid://c2a5o7qi58fus")
const MARKDOWN_THEME: Theme = preload("uid://dhartxld7pqyb")
const ELAPSED_UPDATE_INTERVAL_SECONDS: float = 1.0

@onready var header_container: VBoxContainer = $VBoxContainer/HeaderContainer
@onready var elapsed_time_label: Label = %ElapsedTimeLabel
@onready var body_container: VBoxContainer = %BodyContainer
@onready var footer_container: HBoxContainer = %FooterContainer
@onready var end_time_label: Label = %EndTimeLabel

var current_markdown_label: MarkdownLabel
var markdown_segments: PackedStringArray = PackedStringArray()
var tool_items_by_call_id: Dictionary[String, Node] = {}
var thinking_item: Node
var thinking_finished_current: bool
var started_at_utc_current: String
var completed_at_utc_current: String
var elapsed_update_accumulator: float


func clear_message() -> void:
	for child: Node in body_container.get_children():
		child.queue_free()

	current_markdown_label = null
	markdown_segments.clear()
	tool_items_by_call_id.clear()
	thinking_item = null
	thinking_finished_current = false
	_set_completion_times("", "")


func append_delta(delta_text: String) -> void:
	if delta_text.is_empty():
		return

	var label: MarkdownLabel = _ensure_current_markdown_label()
	label.append_text(delta_text)
	if markdown_segments.is_empty():
		markdown_segments.append(delta_text)
	else:
		markdown_segments[markdown_segments.size() - 1] += delta_text


func finish_message(started_at_utc: String = "", completed_at_utc: String = "") -> void:
	_finish_current_markdown_label()
	var normalized_started_at: String = started_at_utc.strip_edges()
	var normalized_completed_at: String = completed_at_utc.strip_edges()
	if normalized_started_at.is_empty():
		normalized_started_at = started_at_utc_current
	if normalized_completed_at.is_empty() and not normalized_started_at.is_empty():
		normalized_completed_at = _get_utc_timestamp()
	_set_completion_times(normalized_started_at, normalized_completed_at)


func setup(
	message_text: String,
	started_at_utc: String = "",
	completed_at_utc: String = "",
	body_parts: Array = []
) -> void:
	clear_message()
	if not body_parts.is_empty():
		_setup_body_parts(body_parts)
	elif not message_text.is_empty():
		append_delta(message_text)
		if not completed_at_utc.strip_edges().is_empty():
			_finish_current_markdown_label()
	_set_completion_times(started_at_utc, completed_at_utc)


func add_tool_event(event_data: Dictionary) -> Node:
	_finish_current_markdown_label()
	var tool_call_id: String = _get_tool_call_key(event_data)
	var tool_item: Node = TOOL_CALL_ITEM_SCENE.instantiate()
	body_container.add_child(tool_item)
	if tool_item.has_signal("content_height_changed"):
		tool_item.connect("content_height_changed", Callable(self, "_on_body_child_content_height_changed"))
	tool_item.call("setup_tool_event", event_data)
	if not tool_call_id.is_empty():
		tool_items_by_call_id[tool_call_id] = tool_item
	return tool_item


func append_tool_event(event_data: Dictionary) -> void:
	var tool_call_id: String = _get_tool_call_key(event_data)
	var tool_item: Node = tool_items_by_call_id.get(tool_call_id, null) as Node
	if tool_item == null:
		add_tool_event(event_data)
		return

	tool_item.call("append_tool_event", event_data)


func get_tool_item(tool_call_id: String) -> Node:
	return tool_items_by_call_id.get(tool_call_id, null) as Node


func add_thinking() -> Node:
	_finish_current_markdown_label()
	if thinking_item != null and is_instance_valid(thinking_item) and not thinking_finished_current:
		return thinking_item

	thinking_item = TOOL_CALL_ITEM_SCENE.instantiate()
	thinking_finished_current = false
	body_container.add_child(thinking_item)
	if thinking_item.has_signal("content_height_changed"):
		thinking_item.connect("content_height_changed", Callable(self, "_on_body_child_content_height_changed"))
	thinking_item.call("setup_thinking")
	return thinking_item


func append_thinking_delta(delta_text: String) -> void:
	if delta_text.is_empty():
		return

	var item: Node = add_thinking()
	item.call("append_thinking_delta", delta_text)


func finish_thinking() -> void:
	if thinking_item == null or not is_instance_valid(thinking_item):
		return

	thinking_item.call("finish_thinking")
	thinking_finished_current = true


func get_thinking_item() -> Node:
	return thinking_item if thinking_item != null and is_instance_valid(thinking_item) and not thinking_finished_current else null


func _on_mouse_entered() -> void:
	footer_container.modulate.a = 1.0


func _on_mouse_exited() -> void:
	footer_container.modulate.a = 0.0


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set("\n\n".join(markdown_segments))


func _process(delta: float) -> void:
	if started_at_utc_current.is_empty() or not completed_at_utc_current.is_empty():
		set_process(false)
		return

	elapsed_update_accumulator += delta
	if elapsed_update_accumulator < ELAPSED_UPDATE_INTERVAL_SECONDS:
		return

	elapsed_update_accumulator = 0.0
	_update_elapsed_label(started_at_utc_current, _get_utc_timestamp())


func _setup_body_parts(body_parts: Array) -> void:
	for part_value: Variant in body_parts:
		if typeof(part_value) != TYPE_DICTIONARY:
			continue

		var part: Dictionary = part_value as Dictionary
		var part_type: String = str(part.get("type", ""))
		if part_type == "markdown":
			var text: String = str(part.get("text", ""))
			if text.is_empty():
				continue

			append_delta(text)
			_finish_current_markdown_label()
		elif part_type == "tool":
			var events_value: Variant = part.get("events", [])
			if typeof(events_value) != TYPE_ARRAY:
				continue

			var events: Array = events_value as Array
			var is_first_event: bool = true
			for event_value: Variant in events:
				if typeof(event_value) != TYPE_DICTIONARY:
					continue

				var event_data: Dictionary = event_value as Dictionary
				if is_first_event:
					add_tool_event(event_data)
					is_first_event = false
				else:
					append_tool_event(event_data)
		elif part_type == "thinking":
			var text: String = str(part.get("text", ""))
			if not text.is_empty():
				append_thinking_delta(text)
			else:
				add_thinking()
			if bool(part.get("done", false)):
				finish_thinking()


func _ensure_current_markdown_label() -> MarkdownLabel:
	if current_markdown_label != null and is_instance_valid(current_markdown_label):
		return current_markdown_label

	current_markdown_label = MarkdownLabel.new()
	current_markdown_label.content_margin = 8
	current_markdown_label.context_menu_enabled = true
	current_markdown_label.fit_content = true
	current_markdown_label.streaming_enabled = true
	current_markdown_label.deferred_layout_enabled = true
	current_markdown_label.layout_flush_interval_msec = 33
	current_markdown_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_markdown_label.theme = MARKDOWN_THEME
	body_container.add_child(current_markdown_label)
	current_markdown_label.clear()
	markdown_segments.append("")
	return current_markdown_label


func _finish_current_markdown_label() -> void:
	if current_markdown_label == null or not is_instance_valid(current_markdown_label):
		current_markdown_label = null
		return

	current_markdown_label.finish_stream()
	current_markdown_label = null


func _on_body_child_content_height_changed() -> void:
	queue_sort()


func _set_completion_times(started_at_utc: String, completed_at_utc: String) -> void:
	var normalized_completed_at: String = completed_at_utc.strip_edges()
	var normalized_started_at: String = started_at_utc.strip_edges()
	started_at_utc_current = normalized_started_at
	completed_at_utc_current = normalized_completed_at
	var has_started_time: bool = not normalized_started_at.is_empty()
	var has_completed_time: bool = not normalized_completed_at.is_empty()

	end_time_label.visible = has_completed_time
	if has_completed_time:
		end_time_label.text = "Completed: %s" % _format_utc_time(normalized_completed_at)

	header_container.visible = has_started_time
	if has_started_time:
		var elapsed_until: String = normalized_completed_at if has_completed_time else _get_utc_timestamp()
		_update_elapsed_label(normalized_started_at, elapsed_until)

	set_process(has_started_time and not has_completed_time)


func _update_elapsed_label(started_at_utc: String, until_utc: String) -> void:
	var elapsed_seconds: int = maxi(0, _timestamp_to_unix(until_utc) - _timestamp_to_unix(started_at_utc))
	elapsed_time_label.text = "Elapsed: %s" % _format_elapsed_seconds(elapsed_seconds)


func _format_utc_time(timestamp: String) -> String:
	var formatted_timestamp: String = timestamp.strip_edges()
	if formatted_timestamp.is_empty():
		return ""
	if formatted_timestamp.ends_with(" UTC"):
		return formatted_timestamp
	if formatted_timestamp.ends_with("Z"):
		formatted_timestamp = formatted_timestamp.substr(0, formatted_timestamp.length() - 1)
	var dot_index: int = formatted_timestamp.find(".")
	if dot_index >= 0:
		formatted_timestamp = formatted_timestamp.substr(0, dot_index)
	formatted_timestamp = formatted_timestamp.replace("T", " ")
	return "%s UTC" % formatted_timestamp


func _timestamp_to_unix(timestamp: String) -> int:
	var normalized_timestamp: String = timestamp.strip_edges()
	if normalized_timestamp.ends_with("Z"):
		normalized_timestamp = normalized_timestamp.substr(0, normalized_timestamp.length() - 1)
	var dot_index: int = normalized_timestamp.find(".")
	if dot_index >= 0:
		normalized_timestamp = normalized_timestamp.substr(0, dot_index)
	normalized_timestamp = normalized_timestamp.replace("T", " ")
	return int(Time.get_unix_time_from_datetime_string(normalized_timestamp))


func _get_utc_timestamp() -> String:
	return "%sZ" % Time.get_datetime_string_from_system(true, false)


func _get_tool_call_key(event_data: Dictionary) -> String:
	var tool_call_id: String = str(event_data.get("toolCallId", ""))
	if not tool_call_id.is_empty():
		return tool_call_id

	var approval_id: String = str(event_data.get("approvalId", ""))
	if not approval_id.is_empty():
		return "approval:%s" % approval_id

	return str(event_data.get("toolName", "tool"))


func _format_elapsed_seconds(elapsed_seconds: int) -> String:
	if elapsed_seconds < 60:
		return "%ds" % elapsed_seconds
	if elapsed_seconds < 3600:
		return "%dm %02ds" % [int(elapsed_seconds / 60), elapsed_seconds % 60]

	return "%dh %02dm %02ds" % [int(elapsed_seconds / 3600), int(elapsed_seconds / 60) % 60, elapsed_seconds % 60]
