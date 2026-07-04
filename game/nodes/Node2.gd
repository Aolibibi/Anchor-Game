# game/nodes/Node2.gd - 节点②：森林迷图（点击同色符文配对）
extends NodeBase
class_name Node2

const TIME_LIMIT: float = 30.0
const RUNE_PAIR_COUNT: int = 4
const RUNE_BUTTON_SIZE: Vector2 = Vector2(150, 72)
const SUCCESS_REN_QI: int = 12
const TIMEOUT_QI_REN: int = 10

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var timer_label: Label = $TimerLabel
@onready var progress_label: Label = $ProgressLabel
@onready var lines_root: Node2D = $LinesRoot
@onready var runes_root: Node2D = $RunesRoot
@onready var hint_label: Label = $HintLabel

var _connected_count: int = 0
var _time_left: float = TIME_LIMIT
var _is_active: bool = false
var _first_selected: Button = null
var _first_rune_name: String = ""
var _rune_buttons: Array[Button] = []

func _ready() -> void:
	node_id = 2
	super._ready()

func enter_node() -> void:
	title_label.text = "节点② 森林迷图"
	desc_label.text = "30秒内点击相同颜色的符文进行连接（每种颜色2个）"
	hint_label.text = "先点击一个符文，再点击同色的另一个符文"
	_connected_count = 0
	_first_selected = null
	_first_rune_name = ""
	_time_left = TIME_LIMIT
	_is_active = true
	_clear_lines()
	_setup_runes()
	_update_timer()
	_update_progress()

func _setup_runes() -> void:
	for child in runes_root.get_children():
		child.queue_free()
	_rune_buttons.clear()

	var rune_names: Array[String] = ["红符文", "蓝符文", "绿符文", "黄符文"]
	var positions: Array[Vector2] = [
		Vector2(140, 250), Vector2(440, 230), Vector2(740, 250), Vector2(250, 420),
		Vector2(650, 420), Vector2(900, 420), Vector2(360, 590), Vector2(760, 600)
	]
	positions.shuffle()

	var position_index: int = 0
	for rune_name in rune_names:
		for _pair_index in range(2):
			var button: Button = Button.new()
			button.text = rune_name
			button.position = positions[position_index]
			button.size = RUNE_BUTTON_SIZE
			button.add_theme_font_size_override("font_size", 20)
			button.add_theme_color_override("font_color", _get_rune_color(rune_name))
			button.pressed.connect(_on_rune_pressed.bind(button, rune_name))
			runes_root.add_child(button)
			_rune_buttons.append(button)
			position_index += 1

func _clear_lines() -> void:
	for child in lines_root.get_children():
		child.queue_free()

func _on_rune_pressed(button: Button, rune_name: String) -> void:
	if not _is_active:
		return
	if _first_selected == null:
		_select_rune(button, rune_name)
	elif _first_selected == button:
		_clear_selection()
		hint_label.text = "取消选择"
	elif _first_rune_name == rune_name:
		_connect_pair(button, rune_name)
	else:
		hint_label.text = "颜色不符，符文没有响应"
		_clear_selection()

func _select_rune(button: Button, rune_name: String) -> void:
	_first_selected = button
	_first_rune_name = rune_name
	button.modulate = Color(1.35, 1.35, 1.35, 1.0)
	hint_label.text = "选中: " + rune_name

func _clear_selection() -> void:
	if _first_selected != null:
		_first_selected.modulate = Color(1, 1, 1, 1)
	_first_selected = null
	_first_rune_name = ""

func _connect_pair(button: Button, rune_name: String) -> void:
	_draw_connection(_first_selected, button, rune_name)
	_first_selected.disabled = true
	button.disabled = true
	_first_selected.modulate = Color(0.6, 1.0, 0.6, 1.0)
	button.modulate = Color(0.6, 1.0, 0.6, 1.0)
	_first_selected = null
	_first_rune_name = ""
	_connected_count += 1
	hint_label.text = "连接成功: " + rune_name
	_update_progress()
	if _connected_count >= RUNE_PAIR_COUNT:
		_complete_success()

func _draw_connection(from_button: Button, to_button: Button, rune_name: String) -> void:
	var line: Line2D = Line2D.new()
	line.width = 6.0
	line.default_color = _get_rune_color(rune_name)
	line.points = PackedVector2Array([
		from_button.position + from_button.size * 0.5,
		to_button.position + to_button.size * 0.5
	])
	lines_root.add_child(line)

func _get_rune_color(rune_name: String) -> Color:
	match rune_name:
		"红符文":
			return Color(0.95, 0.2, 0.2, 1.0)
		"蓝符文":
			return Color(0.25, 0.45, 1.0, 1.0)
		"绿符文":
			return Color(0.2, 0.75, 0.35, 1.0)
		"黄符文":
			return Color(0.95, 0.75, 0.2, 1.0)
		_:
			return Color(1, 1, 1, 1)

func _update_timer() -> void:
	timer_label.text = "时间: " + str(int(max(_time_left, 0))) + "s"

func _update_progress() -> void:
	progress_label.text = "进度: " + str(_connected_count) + "/" + str(RUNE_PAIR_COUNT)

func _complete_success() -> void:
	_is_active = false
	hint_label.text = "符文全部连接，森林迷雾散开了！"
	ResourceManager.add_ren_qi(SUCCESS_REN_QI)
	complete_node("符文全部连接")

func _process(delta: float) -> void:
	if not _is_active:
		return
	_time_left -= delta
	_update_timer()
	if _time_left <= 0:
		_is_active = false
		hint_label.text = "时间到，勇者在森林里迷路了"
		ResourceManager.add_qi_ren(TIMEOUT_QI_REN)
		complete_node("超时，迷路")