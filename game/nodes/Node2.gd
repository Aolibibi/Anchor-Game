# game/nodes/Node2.gd - 节点②：森林迷雾（画线连符文）
extends NodeBase
class_name Node2

const TIME_LIMIT: float = 30.0
const RUNE_COUNT: int = 4

@onready var title_label: Label = $TitleLabel
@onready var timer_label: Label = $TimerLabel
@onready var hint_label: Label = $HintLabel
@onready var progress_label: Label = $ProgressLabel

var _connected_count: int = 0
var _time_left: float = TIME_LIMIT
var _is_active: bool = false
var _rune_buttons: Array = []

func _ready() -> void:
	node_id = 2
	super._ready()

func enter_node() -> void:
	title_label.text = "节点② 森林迷雾"
	hint_label.text = "点击颜色相同的符文进行连接（每色2个）"
	_setup_runes()
	_is_active = true
	_time_left = TIME_LIMIT
	_connected_count = 0
	_update_progress()

func _setup_runes() -> void:
	var colors: Array[String] = ["红符文", "蓝符文", "绿符文", "黄符文"]
	var positions: Array[Vector2] = []
	for i in range(RUNE_COUNT):
		positions.append(Vector2(200 + i * 250, 300))
		positions.append(Vector2(200 + i * 250, 600))
	positions.shuffle()
	var idx: int = 0
	for color_name in colors:
		for _j in range(2):
			var btn = Button.new()
			btn.text = color_name
			btn.position = positions[idx]
			btn.size = Vector2(180, 80)
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(_on_rune_pressed.bind(btn, color_name))
			add_child(btn)
			_rune_buttons.append(btn)
			idx += 1

var _first_selected: Button = null
var _first_color: String = ""

func _on_rune_pressed(btn: Button, color_name: String) -> void:
	if not _is_active:
		return
	if _first_selected == null:
		_first_selected = btn
		_first_color = color_name
		btn.modulate = Color(1.5, 1.5, 1.5)
		hint_label.text = "选中: " + color_name + "，点击同色另一个"
	elif _first_selected == btn:
		_first_selected.modulate = Color(1, 1, 1)
		_first_selected = null
		_first_color = ""
		hint_label.text = "取消选择"
	elif _first_color == color_name:
		_first_selected.modulate = Color(0.6, 1.0, 0.6)
		btn.modulate = Color(0.6, 1.0, 0.6)
		_first_selected.disabled = true
		btn.disabled = true
		_connected_count += 1
		_first_selected = null
		_first_color = ""
		_update_progress()
		hint_label.text = "连接成功！"
		if _connected_count >= RUNE_COUNT:
			_complete_success()
	else:
		hint_label.text = "颜色不符！"
		_first_selected.modulate = Color(1, 1, 1)
		_first_selected = null
		_first_color = ""

func _update_progress() -> void:
	progress_label.text = "进度: " + str(_connected_count) + "/" + str(RUNE_COUNT)

func _complete_success() -> void:
	_is_active = false
	hint_label.text = "所有符文连接成功！"
	ResourceManager.add_ren_qi(12)
	complete_node("符文全部连接")

func _process(delta: float) -> void:
	if _is_active:
		_time_left -= delta
		timer_label.text = "时间: " + str(int(_time_left)) + "s"
		if _time_left <= 0:
			_is_active = false
			hint_label.text = "时间到！迷雾未散"
			ResourceManager.add_qi_ren(10)
			complete_node("超时，迷路")
