@tool
extends MarginContainer

@onready var header_container: VBoxContainer = $VBoxContainer/HeaderContainer
@onready var elapsed_time_label: Label = %ElapsedTimeLabel
@onready var body_container: VBoxContainer = %BodyContainer
@onready var markdown_label: MarkdownLabel = %MarkdownLabel
@onready var footer_container: HBoxContainer = %FooterContainer
@onready var end_time_label: Label = %EndTimeLabel


func clear_message() -> void:
	markdown_label.clear()
	_set_completion_times("", "")


func append_delta(delta_text: String) -> void:
	markdown_label.append_text(delta_text)


func finish_message(started_at_utc: String = "", completed_at_utc: String = "") -> void:
	markdown_label.finish_stream()
	_set_completion_times(started_at_utc, completed_at_utc)


func setup(message_text: String, started_at_utc: String = "", completed_at_utc: String = "") -> void:
	markdown_label.clear()
	markdown_label.append_text(message_text)
	markdown_label.finish_stream()
	_set_completion_times(started_at_utc, completed_at_utc)


func _on_mouse_entered() -> void:
	footer_container.modulate.a = 1.0


func _on_mouse_exited() -> void:
	footer_container.modulate.a = 0.0


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(markdown_label.text)


func _set_completion_times(started_at_utc: String, completed_at_utc: String) -> void:
	var normalized_completed_at: String = completed_at_utc.strip_edges()
	var normalized_started_at: String = started_at_utc.strip_edges()
	var has_completed_time: bool = not normalized_completed_at.is_empty()
	var has_elapsed_time: bool = has_completed_time and not normalized_started_at.is_empty()

	end_time_label.visible = has_completed_time
	if has_completed_time:
		end_time_label.text = "Completed: %s" % _format_utc_time(normalized_completed_at)

	header_container.visible = has_elapsed_time
	if has_elapsed_time:
		var elapsed_seconds: int = maxi(0, _timestamp_to_unix(normalized_completed_at) - _timestamp_to_unix(normalized_started_at))
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


func _format_elapsed_seconds(elapsed_seconds: int) -> String:
	if elapsed_seconds < 60:
		return "%ds" % elapsed_seconds
	if elapsed_seconds < 3600:
		return "%dm %02ds" % [int(elapsed_seconds / 60), elapsed_seconds % 60]

	return "%dh %02dm %02ds" % [int(elapsed_seconds / 3600), int(elapsed_seconds / 60) % 60, elapsed_seconds % 60]
