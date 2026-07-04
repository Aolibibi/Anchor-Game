# game/nodes/Node3.gd - 节点③：小鸡堵河（场景互动解谜，招牌关）
extends NodeBase
class_name Node3

@onready var title_label: Label = $TitleLabel
@onready var hint_label: Label = $HintLabel
@onready var scene_desc: Label = $SceneDesc

var _river_blocked: bool = false
var _chicken_big: bool = false
var _chicken_moved: bool = false
var _is_completed: bool = false

func _ready() -> void:
	node_id = 3
	super._ready()

func enter_node() -> void:
	title_label.text = "节点③ 小鸡堵河"
	scene_desc.text = "勇者来到河边，没有桥。岸边有一只小鸡、一棵树、一块石头。"
	hint_label.text = "点击场景元素尝试组合（点击元素A再点击元素B）"
	_setup_scene()

var _scene_elements: Dictionary = {}
var _first_selected: String = ""

func _setup_scene() -> void:
	var elements: Array[String] = ["小鸡", "树", "石头", "河"]
	var x: int = 150
	for elem in elements:
		var btn = Button.new()
		btn.text = elem
		btn.position = Vector2(x, 400)
		btn.size = Vector2(180, 100)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_element_pressed.bind(elem))
		add_child(btn)
		_scene_elements[elem] = btn
		x += 220

func _on_element_pressed(elem: String) -> void:
	if _is_completed:
		return
	if _first_selected == "":
		_first_selected = elem
		hint_label.text = "选中: " + elem + "，再选一个进行组合"
	elif _first_selected == elem:
		_first_selected = ""
		hint_label.text = "取消选择"
	else:
		_try_combine(_first_selected, elem)
		_first_selected = ""

func _try_combine(a: String, b: String) -> void:
	var combo: String = a + "+" + b
	match combo:
		"小鸡+河", "河+小鸡":
			if not _chicken_big:
				hint_label.text = "小鸡太小了，被河水冲走了"
				ResourceManager.add_qi_ren(5)
			else:
				_river_blocked = true
				_chicken_moved = true
				hint_label.text = "变大的小鸡堵住了河流！勇者可以过河了"
				_complete_success()
		"小鸡+石头", "石头+小鸡":
			_chicken_big = true
			hint_label.text = "小鸡吃了石头（？）变大了！"
		"小鸡+树", "树+小鸡":
			hint_label.text = "小鸡飞到了树上，没什么用"
		"树+河", "河+树":
			hint_label.text = "树太重，勇者搬不动"
		"石头+河", "河+石头":
			hint_label.text = "石头沉到河底，没用"
		"石头+树", "树+石头":
			hint_label.text = "没什么反应"
		_:
			hint_label.text = "这两个组合没什么效果..."

func _complete_success() -> void:
	_is_completed = true
	ResourceManager.add_ren_qi(15)
	hint_label.text = "成功过河！"
	complete_node("小鸡堵河成功")
