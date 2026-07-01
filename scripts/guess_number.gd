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

var _tween: Tween

enum Difficulty { EASY, MEDIUM, HARD }
var current_difficulty: Difficulty = Difficulty.MEDIUM

var target_number: int
var attempts: int = 0
var hint_cycle: int = 0
var range_low: int
var range_high: int

const DIFFICULTY_CFG: Dictionary = {
	Difficulty.EASY:   {"min": 1, "max": 50,  "limit": 10},
	Difficulty.MEDIUM: {"min": 1, "max": 100, "limit": 7},
	Difficulty.HARD:   {"min": 1, "max": 200, "limit": 5},
}

const CONFIG_PATH: String = "user://guess_number.cfg"
const CONFIG_SECTION: String = "best"


func _ready() -> void:
	_load_records()
	_update_difficulty_ui()
	_setup_range_bar_style()
	new_game()


func new_game() -> void:
	var cfg: Dictionary = DIFFICULTY_CFG[current_difficulty]
	target_number = randi_range(cfg["min"], cfg["max"])
	attempts = 0
	hint_cycle = 0
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
	attempts_label.text = "已猜次数：%d / %d" % [attempts, cfg["limit"]]

	if guess == target_number:
		feedback_label.text = "🎉 恭喜！就是 %d！" % target_number
		feedback_label.modulate = Color(1.0, 0.84, 0.0)
		_animate_correct()
		_try_save_best()
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
		_end_game()

	input_field.text = ""
	input_field.grab_focus()


func _on_hint_pressed() -> void:
	var hints: Array[String] = _generate_hints()
	hint_cycle = (hint_cycle + 1) % hints.size()
	feedback_label.text = hints[hint_cycle]
	feedback_label.modulate = Color(0.7, 0.5, 1.0)  # 紫色


func _generate_hints() -> Array[String]:
	var result: Array[String] = []
	# 1. 奇偶提示
	result.append("💡 数字是 %s" % ("奇数" if target_number % 2 == 1 else "偶数"))
	# 2. 范围缩小提示
	var cfg: Dictionary = DIFFICULTY_CFG[current_difficulty]
	var mid: int = (cfg["min"] + cfg["max"]) / 2
	if target_number <= mid:
		result.append("💡 目标在 %d ~ %d 之间" % [cfg["min"], mid])
	else:
		result.append("💡 目标在 %d ~ %d 之间" % [mid + 1, cfg["max"]])
	# 3. 整除性提示（随机 3-9）
	var n: int = randi_range(3, 9)
	result.append("💡 数字%s被 %d 整除" % ["能" if target_number % n == 0 else "不能", n])
	return result


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
	# 随进度改变颜色：蓝 → 橙 → 红
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
