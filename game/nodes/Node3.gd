# game/nodes/Node3.gd - 节点③：小鸡堵河（场景互动解谜，招牌关）
extends NodeBase
class_name Node3

const TIME_LIMIT: float = 30.0
const SUCCESS_REN_QI: int = 15
const WRONG_COMBO_QI_REN: int = 5
const TIMEOUT_QI_REN: int = 10
const ELEMENT_BUTTON_SIZE: Vector2 = Vector2(180, 100)

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var timer_label: Label = $TimerLabel
@onready var elements_root: Node2D = $ElementsRoot
@onready var state_label: Label = $StateLabel
@onready var hint_label: Label = $HintLabel

var _time_left: float = TIME_LIMIT
var _is_active: bool = false
var _chicken_big: bool = false
var _first_selected: String = ""
var _scene_elements: Dictionary = {}

func _ready() -> void:
	node_id = 3
	super._ready()

func enter_node() -> void:
	title_label.text = "节点③ 小鸡堵河"
	desc_label.text = "勇者来到河边，没有桥。岸边有一只小鸡、一棵树、一块石头。"
	state_label.text = "状态: 小鸡很普通，河水很急"
	hint_label.text = "点击场景元素尝试组合（先选元素A，再选元素B）"
	_time_left = TIME_LIMIT
	_is_active = true
	_chicken_big = false
	_first_selected = ""
	_setup_scene()
	_update_timer()

func _setup_scene() -> void:
	for child in elements_root.get_children():
		child.queue_free()
	_scene_elements.clear()

	var elements: Array[String] = ["小鸡", "树", "石头", "河"]
	var positions: Array[Vector2] = [
		Vector2(130, 390),
		Vector2(370, 330),
		Vector2(620, 420),
		Vector2(860, 360)
	]

	for index in range(elements.size()):
		var element_name: String = elements[index]
		var button: Button = Button.new()
		button.text = element_name
		button.position = positions[index]
		button.size = ELEMENT_BUTTON_SIZE
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_on_element_pressed.bind(element_name))
		elements_root.add_child(button)
		_scene_elements[element_name] = button

func _on_element_pressed(element_name: String) -> void:
	if not _is_active:
		return
	if _first_selected == "":
		_select_element(element_name)
	elif _first_selected == element_name:
		_clear_selection()
		hint_label.text = "取消选择"
	else:
		_try_combine(_first_selected, element_name)
		_clear_selection()

func _select_element(element_name: String) -> void:
	_first_selected = element_name
	var button: Button = _scene_elements[element_name] as Button
	button.modulate = Color(1.35, 1.35, 1.35, 1.0)
	hint_label.text = "选中: " + element_name + "，再选一个进行组合"

func _clear_selection() -> void:
	if _first_selected != "" and _scene_elements.has(_first_selected):
		var button: Button = _scene_elements[_first_selected] as Button
		button.modulate = Color(1, 1, 1, 1)
	_first_selected = ""

func _try_combine(first_element: String, second_element: String) -> void:
	var combo: String = first_element + "+" + second_element
	match combo:
		"小鸡+石头", "石头+小鸡":
			_make_chicken_big()
		"小鸡+河", "河+小鸡":
			_try_block_river()
		"小鸡+树", "树+小鸡":
			_wrong_combo("小鸡飞到了树上，没什么用")
		"树+河", "河+树":
			_wrong_combo("树太重，勇者搬不动")
		"石头+河", "河+石头":
			_wrong_combo("石头沉到河底，没用")
		"石头+树", "树+石头":
			_wrong_combo("没什么反应")
		_:
			_wrong_combo("这两个组合没什么效果")

func _make_chicken_big() -> void:
	if _chicken_big:
		hint_label.text = "小鸡已经够大了"
		return
	_chicken_big = true
	state_label.text = "状态: 小鸡变大了，也许能堵住河流"
	hint_label.text = "小鸡吃了石头（？）变大了！"
	var chicken_button: Button = _scene_elements["小鸡"] as Button
	chicken_button.scale = Vector2(1.2, 1.2)
	chicken_button.modulate = Color(1.0, 0.95, 0.55, 1.0)

func _try_block_river() -> void:
	if not _chicken_big:
		_wrong_combo("小鸡太小了，被河水冲走了")
		return
	_is_active = false
	state_label.text = "状态: 变大的小鸡堵住了河流"
	hint_label.text = "成功过河！"
	ResourceManager.add_ren_qi(SUCCESS_REN_QI)
	complete_node("小鸡堵河成功")

func _wrong_combo(message: String) -> void:
	hint_label.text = message
	ResourceManager.add_qi_ren(WRONG_COMBO_QI_REN)

func _update_timer() -> void:
	timer_label.text = "时间: " + str(int(max(_time_left, 0))) + "s"

func _process(delta: float) -> void:
	if not _is_active:
		return
	_time_left -= delta
	_update_timer()
	if _time_left <= 0:
		_is_active = false
		hint_label.text = "时间到！勇者在河边绕了半天"
		ResourceManager.add_qi_ren(TIMEOUT_QI_REN)
		complete_node("超时，未能过河")
