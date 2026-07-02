extends Control

@onready var target_label: Label = %TargetLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var attempts_label: Label = %AttemptsLabel
@onready var best_record_label: Label = %BestRecordLabel
@onready var history_container: VBoxContainer = %HistoryContainer
@onready var input_field: LineEdit = %InputField
@onready var guess_button: Button = %GuessButton
@onready var hint_button: Button = %HintButton
@onready var restart_button: Button = %RestartButton
@onready var easy_button: Button = %EasyButton
@onready var medium_button: Button = %MediumButton
@onready var hard_button: Button = %HardButton
@onready var range_bar: ProgressBar = %RangeBar
@onready var stats_panel: PanelContainer = %StatsPanel
@onready var stats_close_btn: Button = %StatsCloseBtn
@onready var stats_content: VBoxContainer = %StatsContent

var _tween: Tween

enum Difficulty { EASY, MEDIUM, HARD }
var current_difficulty: Difficulty = Difficulty.MEDIUM

var target_number: int
var attempts: int = 0
var last_guess: int = -1
var range_low: int
var range_high: int

const DIFFICULTY_CFG: Dictionary = {
	Difficulty.EASY:   {"min": 1, "max": 50,  "limit": 10},
	Difficulty.MEDIUM: {"min": 1, "max": 100, "limit": 7},
	Difficulty.HARD:   {"min": 1, "max": 200, "limit": 5},
}

const CONFIG_PATH: String = "user://guess_number.cfg"
const CONFIG_SECTION: String = "best"
const STATS_PATH: String = "user://guess_number_stats.json"


func _ready() -> void:
	_load_records()
	_load_stats()
	_setup_stats_panel_style()
	_update_difficulty_ui()
	_setup_range_bar_style()
	new_game()


func new_game() -> void:
	var cfg: Dictionary = DIFFICULTY_CFG[current_difficulty]
	target_number = randi_range(cfg["min"], cfg["max"])
	attempts = 0
	last_guess = -1
	range_low = cfg["min"]
	range_high = cfg["max"]
	target_label.text = "请输入 %d-%d 之间的数字" % [cfg["min"], cfg["max"]]
	feedback_label.text = ""
	feedback_label.modulate = Color.WHITE
	attempts_label.text = "已猜次数：0 / %d" % cfg["limit"]
	input_field.text = ""
	input_field.editable = true
	guess_button.disabled = false
	hint_button.disabled = false

	for child in history_container.get_children():
		child.queue_free()

	_update_best_display()
	_update_range_bar()
	stats_panel.visible = false
	input_field.grab_focus()


func _on_guess_pressed() -> void:
	var text: String = input_field.text.strip_edges()
	if text.is_empty():
		feedback_label.text = "⚠️ 请输入数字！"
		_shake_feedback()
		return

	var guess: int = int(text)
	var cfg: Dictionary = DIFFICULTY_CFG[current_difficulty]
	if guess < cfg["min"] or guess > cfg["max"]:
		feedback_label.text = "⚠️ 请输入 %d-%d 之间的数字！" % [cfg["min"], cfg["max"]]
		_shake_feedback()
		return

	attempts += 1
	last_guess = guess
	attempts_label.text = "已猜次数：%d / %d" % [attempts, cfg["limit"]]

	if guess == target_number:
		feedback_label.text = "🎉 恭喜！就是 %d！" % target_number
		feedback_label.modulate = Color(1.0, 0.84, 0.0)
		_animate_correct()
		_try_save_best()
		_record_game_result(attempts, true)
		_end_game()
		return

	if guess < target_number:
		feedback_label.text = "📈 小了，再大一点！"
		feedback_label.modulate = Color(0.3, 0.6, 1.0)
		range_low = max(range_low, guess + 1)
		_update_range_bar()
		_add_history_label(guess, false)
	else:
		feedback_label.text = "📉 大了，再小一点！"
		feedback_label.modulate = Color(1.0, 0.3, 0.3)
		range_high = min(range_high, guess - 1)
		_update_range_bar()
		_add_history_label(guess, true)

	if attempts >= cfg["limit"]:
		feedback_label.text = "😢 游戏结束！数字是 %d" % target_number
		feedback_label.modulate = Color(0.5, 0.5, 0.5)
		_record_game_result(attempts, false)
		_end_game()

	input_field.text = ""
	input_field.grab_focus()


func _on_hint_pressed() -> void:
	if last_guess < 0:
		feedback_label.text = "💡 请先猜一个数字！"
		feedback_label.modulate = Color(0.7, 0.5, 1.0)
		return
	feedback_label.text = _get_temperature_hint(last_guess, target_number, range_high - range_low)
	feedback_label.modulate = Color(0.7, 0.5, 1.0)


func _get_temperature_hint(guess: int, target: int, range_size: int) -> String:
	var distance: int = abs(guess - target)
	if range_size <= 0:
		return "🎉 已经找到了！"
	var ratio: float = float(distance) / float(range_size)
	if ratio < 0.05:
		return "🔥 快烧着了！"
	elif ratio < 0.15:
		return "🟠 很接近"
	elif ratio < 0.30:
		return "🟡 有点远"
	else:
		return "🔵 还差得远"


func _on_restart_pressed() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	new_game()


func _on_input_text_entered(_new_text: String) -> void:
	_on_guess_pressed()


func _on_easy_pressed() -> void:
	if current_difficulty == Difficulty.EASY:
		return
	current_difficulty = Difficulty.EASY
	_update_difficulty_ui()
	new_game()


func _on_medium_pressed() -> void:
	if current_difficulty == Difficulty.MEDIUM:
		return
	current_difficulty = Difficulty.MEDIUM
	_update_difficulty_ui()
	new_game()


func _on_hard_pressed() -> void:
	if current_difficulty == Difficulty.HARD:
		return
	current_difficulty = Difficulty.HARD
	_update_difficulty_ui()
	new_game()


func _update_difficulty_ui() -> void:
	easy_button.disabled = current_difficulty == Difficulty.EASY
	medium_button.disabled = current_difficulty == Difficulty.MEDIUM
	hard_button.disabled = current_difficulty == Difficulty.HARD


func _end_game() -> void:
	input_field.editable = false
	guess_button.disabled = true
	hint_button.disabled = true


func _add_history_label(guess: int, is_greater: bool) -> void:
	var label: Label = Label.new()
	label.text = "%d  %s" % [guess, "↑" if is_greater else "↓"]
	if is_greater:
		label.modulate = Color(1.0, 0.3, 0.3)
	else:
		label.modulate = Color(0.3, 0.6, 1.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	label.add_theme_constant_override("outline_size", 1)
	history_container.add_child(label)


func _shake_feedback() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(feedback_label, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	_tween.tween_property(feedback_label, "modulate", Color.WHITE, 0.08)
	_tween.tween_property(feedback_label, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	_tween.tween_property(feedback_label, "modulate", Color.WHITE, 0.08)


func _animate_correct() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BOUNCE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(feedback_label, "scale", Vector2(1.5, 1.5), 0.3)
	_tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.3)


# ---------- 范围可视化条 ----------

func _setup_range_bar_style() -> void:
	range_bar.min_value = 0
	range_bar.max_value = 100
	range_bar.show_percentage = false
	range_bar.add_theme_stylebox_override("fill", _make_range_bar_fill())


func _make_range_bar_fill() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 0.9)
	style.border_color = Color(0.3, 0.6, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _update_range_bar() -> void:
	var cfg: Dictionary = DIFFICULTY_CFG[current_difficulty]
	var total: int = cfg["max"] - cfg["min"]
	var current: int = range_high - range_low
	var progress: float = float(total - current) / total * 100.0
	range_bar.value = clamp(progress, 0, 100)
	if progress < 40:
		range_bar.modulate = Color(0.2, 0.5, 0.9)
	elif progress < 75:
		range_bar.modulate = Color(1.0, 0.65, 0.2)
	else:
		range_bar.modulate = Color(0.9, 0.3, 0.2)


# ---------- 最佳记录持久化 ----------

var _records: Dictionary = {}


func _difficulty_key() -> String:
	match current_difficulty:
		Difficulty.EASY:   return "easy"
		Difficulty.MEDIUM: return "medium"
		Difficulty.HARD:   return "hard"
	return "medium"


func _load_records() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for key in ["easy", "medium", "hard"]:
		if cfg.has_section_key(CONFIG_SECTION, key):
			_records[key] = cfg.get_value(CONFIG_SECTION, key, 999)


func _save_records() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	for key in _records:
		cfg.set_value(CONFIG_SECTION, key, _records[key])
	cfg.save(CONFIG_PATH)


func _try_save_best() -> void:
	var key: String = _difficulty_key()
	var best: int = _records.get(key, 999)
	if attempts < best:
		_records[key] = attempts
		_save_records()
		_update_best_display()


func _update_best_display() -> void:
	var key: String = _difficulty_key()
	var best: int = _records.get(key, 0)
	if best > 0:
		best_record_label.text = "🏆 最佳记录：%d 次" % best
	else:
		best_record_label.text = ""


# ---------- 统计系统 ----------

var _stats_data: Dictionary = {}


func _setup_stats_panel_style() -> void:
	# 半透明遮罩背景
	var backdrop: StyleBoxFlat = StyleBoxFlat.new()
	backdrop.bg_color = Color(0, 0, 0, 0.5)
	stats_panel.add_theme_stylebox_override("panel", backdrop)

	# 卡片背景
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color(0.12, 0.12, 0.22, 0.95)
	card.border_color = Color(0.35, 0.35, 0.55)
	card.border_width_left = 1
	card.border_width_top = 1
	card.border_width_right = 1
	card.border_width_bottom = 1
	card.corner_radius_top_left = 12
	card.corner_radius_top_right = 12
	card.corner_radius_bottom_left = 12
	card.corner_radius_bottom_right = 12
	card.content_margin_left = 20
	card.content_margin_top = 14
	card.content_margin_right = 20
	card.content_margin_bottom = 16

	var stats_card_node: PanelContainer = stats_panel.get_node("StatsCenter/StatsCard") as PanelContainer
	stats_card_node.add_theme_stylebox_override("panel", card)

	# 关闭按钮样式
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.25, 0.35)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	btn_style.content_margin_top = 4
	btn_style.content_margin_bottom = 4
	stats_close_btn.add_theme_stylebox_override("normal", btn_style)
	stats_close_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))


func _load_stats() -> void:
	if not FileAccess.file_exists(STATS_PATH):
		_stats_data = _empty_stats_dict()
		return
	var file: FileAccess = FileAccess.open(STATS_PATH, FileAccess.READ)
	if file == null:
		_stats_data = _empty_stats_dict()
		return
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		_stats_data = _empty_stats_dict()
		return
	var raw = json.get_data()
	if typeof(raw) != TYPE_DICTIONARY:
		_stats_data = _empty_stats_dict()
		return
	_stats_data = raw


func _save_stats() -> void:
	var file: FileAccess = FileAccess.open(STATS_PATH, FileAccess.WRITE)
	if file == null:
		return
	var json: JSON = JSON.new()
	file.store_string(json.stringify(_stats_data, "\t"))
	file.close()


func _empty_stats_dict() -> Dictionary:
	return {"total_games": 0, "total_wins": 0, "easy": {"games": 0, "wins": 0, "total_guesses": 0}, "medium": {"games": 0, "wins": 0, "total_guesses": 0}, "hard": {"games": 0, "wins": 0, "total_guesses": 0}}


func _record_game_result(guess_count: int, won: bool) -> void:
	var key: String = _difficulty_key()
	_stats_data["total_games"] = _stats_data.get("total_games", 0) + 1
	if won:
		_stats_data["total_wins"] = _stats_data.get("total_wins", 0) + 1
	var diff_data: Dictionary = _stats_data.get(key, {})
	diff_data["games"] = diff_data.get("games", 0) + 1
	if won:
		diff_data["wins"] = diff_data.get("wins", 0) + 1
		diff_data["total_guesses"] = diff_data.get("total_guesses", 0) + guess_count
	_stats_data[key] = diff_data
	_save_stats()


func _on_stats_pressed() -> void:
	_populate_stats()
	stats_panel.visible = true


func _on_stats_close_pressed() -> void:
	stats_panel.visible = false


func _populate_stats() -> void:
	for child in stats_content.get_children():
		child.queue_free()

	var total_games: int = _stats_data.get("total_games", 0)
	var total_wins: int = _stats_data.get("total_wins", 0)
	var win_rate: String = "0%"
	if total_games > 0:
		win_rate = "%d%%" % int(float(total_wins) / float(total_games) * 100)

	# 总览行
	_add_stat_line("📋 总对局数：%d    🏆 总胜场：%d    📈 胜率：%s" % [total_games, total_wins, win_rate], Color(0.9, 0.9, 0.9), 16)
	_add_stat_separator()

	# 各难度
	for diff_key in ["easy", "medium", "hard"]:
		var diff_data: Dictionary = _stats_data.get(diff_key, {})
		var games: int = diff_data.get("games", 0)
		var wins: int = diff_data.get("wins", 0)
		var guesses: int = diff_data.get("total_guesses", 0)

		var icon: String = {"easy": "🟢", "medium": "🟡", "hard": "🔴"}[diff_key]
		var label_text: String
		if games == 0:
			label_text = "%s %s：暂无数据" % [icon, _diff_label(diff_key)]
		else:
			var rate: String = "%d%%" % int(float(wins) / float(games) * 100)
			var avg: String = "暂无" if wins == 0 else "%.1f" % (float(guesses) / float(wins))
			label_text = "%s %s：%d局  %d胜  %s  ⌀%s次" % [icon, _diff_label(diff_key), games, wins, rate, avg]

		_add_stat_line(label_text, Color(0.75, 0.75, 0.8), 14)

	_add_stat_separator()
	_add_stat_line("💡 点击 ✕ 关闭面板", Color(0.5, 0.5, 0.6), 12)


func _diff_label(key: String) -> String:
	match key:
		"easy":   return "简单"
		"medium": return "中等"
		"hard":   return "困难"
	return key


func _add_stat_line(text: String, color: Color, font_size: int) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	stats_content.add_child(label)


func _add_stat_separator() -> void:
	var sep: HSeparator = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 8)
	stats_content.add_child(sep)
