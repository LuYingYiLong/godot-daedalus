@tool
extends PopupPanel

@onready var usage_percent_label: Label = %UsagePercentLabel
@onready var usage_tokens_label: Label = %UsageTokensLabel
@onready var context_usage_progress_bar: ProgressBar = %ContextUsageProgressBar
@onready var model_value_label: Label = %ModelValueLabel
@onready var history_messages_value_label: Label = %HistoryMessagesValueLabel
@onready var context_window_value_label: Label = %ContextWindowValueLabel
@onready var max_output_value_label: Label = %MaxOutputValueLabel
@onready var output_reserve_value_label: Label = %OutputReserveValueLabel
@onready var safety_margin_value_label: Label = %SafetyMarginValueLabel
@onready var summary_value_label: Label = %SummaryValueLabel
@onready var approval_value_label: Label = %ApprovalValueLabel
@onready var mcp_value_label: Label = %McpValueLabel
@onready var workspace_value_label: Label = %WorkspaceValueLabel


func setup(info: Dictionary) -> void:
	var context_window_tokens: int = int(info.get("contextWindowTokens", 0))
	var history_tokens_stored: int = int(info.get("historyTokensStored", 0))
	var default_output_reserve_tokens: int = int(info.get("defaultOutputReserveTokens", 0))
	var safety_margin_tokens: int = int(info.get("safetyMarginTokens", 0))
	var max_output_tokens: int = int(info.get("maxOutputTokens", 0))
	var history_messages_stored: int = int(info.get("historyMessagesStored", 0))
	var history_budget_tokens: int = max(0, context_window_tokens - default_output_reserve_tokens - safety_margin_tokens)
	var context_ratio: float = _get_ratio(history_tokens_stored, context_window_tokens)
	var budget_ratio: float = _get_ratio(history_tokens_stored, history_budget_tokens)

	usage_percent_label.text = _format_usage_percent(context_ratio)
	usage_tokens_label.text = "%s / %s tokens" % [
		_format_compact_token_count(history_tokens_stored),
		_format_compact_token_count(context_window_tokens)
	]
	context_usage_progress_bar.value = clampf(context_ratio * 100.0, 0.0, 100.0)

	model_value_label.text = str(info.get("model", "Unknown"))
	history_messages_value_label.text = "%d messages" % history_messages_stored
	context_window_value_label.text = "%s tokens" % _format_compact_token_count(context_window_tokens)
	max_output_value_label.text = "%s tokens" % _format_compact_token_count(max_output_tokens)
	output_reserve_value_label.text = "%s reserved" % _format_compact_token_count(default_output_reserve_tokens)
	safety_margin_value_label.text = "%s margin" % _format_compact_token_count(safety_margin_tokens)
	summary_value_label.text = _format_summary(info)
	approval_value_label.text = _format_approval(info)
	mcp_value_label.text = _format_mcp_servers(info.get("mcpServers", []))
	workspace_value_label.text = _format_workspace(info)


func _get_ratio(current_tokens: int, max_tokens: int) -> float:
	if max_tokens <= 0:
		return 0.0

	return float(current_tokens) / float(max_tokens)


func _format_usage_percent(ratio: float) -> String:
	var percent: float = ratio * 100.0
	if percent > 0.0 and percent < 0.01:
		return "<0.01%"
	if percent < 1.0:
		return "%.2f%%" % percent
	if percent < 10.0:
		return "%.1f%%" % percent

	return "%d%%" % int(round(percent))


func _format_compact_token_count(token_count: int) -> String:
	var absolute_count: int = absi(token_count)
	if absolute_count >= 1000000:
		return "%.1fM" % (float(token_count) / 1000000.0)
	if absolute_count >= 1000:
		return "%.1fk" % (float(token_count) / 1000.0)

	return str(token_count)


func _format_summary(info: Dictionary) -> String:
	var summary_active: bool = bool(info.get("summaryActive", false))
	if not summary_active:
		return "Inactive"

	var summary_covered_message_count: int = int(info.get("summaryCoveredMessageCount", 0))
	var summary_length: int = int(info.get("summaryLength", 0))
	return "Active, %d covered, %d chars" % [summary_covered_message_count, summary_length]


func _format_approval(info: Dictionary) -> String:
	var approval_mode: String = _format_approval_mode(str(info.get("approvalMode", "")))
	var pending_approvals: int = int(info.get("pendingApprovals", 0))
	return "%s, %d pending" % [approval_mode, pending_approvals]


func _format_approval_mode(mode: String) -> String:
	if mode == "auto-safe":
		return "Auto Safe"
	if mode == "read-only":
		return "Read Only"
	if mode == "manual":
		return "Manual"

	return "Unknown"


func _format_mcp_servers(value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "0 connected"

	var servers: Array = value as Array
	if servers.is_empty():
		return "0 connected"

	var names: PackedStringArray = PackedStringArray()
	for item: Variant in servers:
		names.append(str(item))

	return "%d connected: %s" % [names.size(), ", ".join(names)]


func _format_workspace(info: Dictionary) -> String:
	var active_workspace_value: Variant = info.get("activeWorkspace", {})
	if typeof(active_workspace_value) == TYPE_DICTIONARY:
		var active_workspace: Dictionary = active_workspace_value as Dictionary
		var workspace_name: String = str(active_workspace.get("name", ""))
		if not workspace_name.is_empty():
			return workspace_name

	var project_path: String = str(info.get("godotProjectPath", ""))
	if not project_path.is_empty():
		return project_path

	return "No workspace"
