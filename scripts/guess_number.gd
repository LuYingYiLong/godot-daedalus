extends Control

@onready var target_label: Label = %TargetLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var attempts_label: Label = %AttemptsLabel
@onready var input_field: LineEdit = %InputField
@onready var guess_button: Button = %GuessButton
@onready var restart_button: Button = %RestartButton

var target_number: int
var attempts: int = 0
const MAX_ATTEMPTS: int = 7
const MIN_NUMBER: int = 1
const MAX_NUMBER: int = 100


func _ready() -> void:
	new_game()


func new_game() -> void:
	target_number = randi_range(MIN_NUMBER, MAX_NUMBER)
	attempts = 0
	target_label.text = "请输入 %d-%d 之间的数字" % [MIN_NUMBER, MAX_NUMBER]
	feedback_label.text = ""
	attempts_label.text = "已猜次数：0 / %d" % MAX_ATTEMPTS
	input_field.text = ""
	input_field.editable = true
	guess_button.disabled = false
	input_field.grab_focus()


func _on_guess_pressed() -> void:
	var text := input_field.text.strip_edges()
	if text.is_empty():
		feedback_label.text = "请输入数字！"
		return

	var guess := int(text)
	if guess < MIN_NUMBER or guess > MAX_NUMBER:
		feedback_label.text = "请输入 %d-%d 之间的数字！" % [MIN_NUMBER, MAX_NUMBER]
		return

	attempts += 1
	attempts_label.text = "已猜次数：%d / %d" % [attempts, MAX_ATTEMPTS]

	if guess == target_number:
		feedback_label.text = "🎉 恭喜你猜对了！就是 %d！" % target_number
		_end_game()
		return

	if guess < target_number:
		feedback_label.text = "小了，再大一点！"
	else:
		feedback_label.text = "大了，再小一点！"

	if attempts >= MAX_ATTEMPTS:
		feedback_label.text = "😢 游戏结束！数字是 %d" % target_number
		_end_game()

	input_field.text = ""
	input_field.grab_focus()


func _on_restart_pressed() -> void:
	new_game()


func _on_input_text_entered(_new_text: String) -> void:
	_on_guess_pressed()


func _end_game() -> void:
	input_field.editable = false
	guess_button.disabled = true
