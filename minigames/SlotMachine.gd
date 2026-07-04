# minigames/SlotMachine.gd - 拉霸小游戏（10-15秒）
extends MiniGameBase
class_name SlotMachine

const REEL_COUNT: int = 3
const SYMBOLS: Array[String] = ["剑", "盾", "鸡", "火", "水", "龙", "宝", "骷"]

@onready var reels_container: HBoxContainer = $ReelsContainer
@onready var result_label: Label = $ResultLabel
@onready var hint_label: Label = $HintLabel

var _reel_labels: Array[Label] = []
var _reel_symbols: Array[String] = []
var _reel_spinning: Array[bool] = []
var _reel_timers: Array[float] = []
var _reel_speeds: Array[float] = []
var _stopped_count: int = 0

func get_game_type() -> String:
	return "slot_machine"

func start_game() -> void:
	duration = 12.0
	_timer = duration
	_stopped_count = 0
	_setup_reels()

func _setup_reels() -> void:
	for child in reels_container.get_children():
		child.queue_free()
	_reel_labels.clear()
	_reel_symbols.clear()
	_reel_spinning.clear()
	_reel_timers.clear()
	_reel_speeds.clear()
	for i in range(REEL_COUNT):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(140, 180)
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var label = Label.new()
		label.text = "?"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		vbox.add_child(label)
		panel.add_child(vbox)
		var btn = Button.new()
		btn.text = "停止"
		btn.custom_minimum_size = Vector2(140, 40)
		btn.pressed.connect(_on_stop_pressed.bind(i))
		var wrapper = VBoxContainer.new()
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_child(panel)
		wrapper.add_child(btn)
		reels_container.add_child(wrapper)
		_reel_labels.append(label)
		_reel_symbols.append("?")
		_reel_spinning.append(true)
		_reel_timers.append(0.0)
		_reel_speeds.append(randf_range(0.08, 0.15))
	hint_label.text = "点击[停止]停止滚轮（3个全停才算结果）"

func update_game(delta: float) -> void:
	for i in range(REEL_COUNT):
		if _reel_spinning[i]:
			_reel_timers[i] += delta
			if _reel_timers[i] >= _reel_speeds[i]:
				_reel_timers[i] = 0.0
				_reel_symbols[i] = SYMBOLS[randi() % SYMBOLS.size()]
				_reel_labels[i].text = _reel_symbols[i]

func _on_stop_pressed(idx: int) -> void:
	if not _reel_spinning[idx]:
		return
	_reel_spinning[idx] = false
	_stopped_count += 1
	if _stopped_count >= REEL_COUNT:
		_check_result()

func _check_result() -> void:
	var s1: String = _reel_symbols[0]
	var s2: String = _reel_symbols[1]
	var s3: String = _reel_symbols[2]
	var keywords: Array = [s1, s2, s3]
	if s1 == s2 and s2 == s3:
		result_label.text = "三连！大奖！[" + s1 + s2 + s3 + "]"
		ResourceManager.add_ren_qi(20)
		end_game(true, 100, keywords)
	elif s1 == s2 or s2 == s3 or s1 == s3:
		result_label.text = "两连！小奖"
		ResourceManager.add_ren_qi(8)
		for s in [s1, s2, s3]:
		end_game(true, 50, keywords)
	else:
		result_label.text = "没连上，再来！[" + s1 + s2 + s3 + "]"
		ResourceManager.add_qi_ren(5)
		end_game(false, 10, keywords)
