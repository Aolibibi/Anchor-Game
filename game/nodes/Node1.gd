# game/nodes/Node1.gd - 节点①：装备选择（拖拽配装）
extends NodeBase
class_name Node1

const SLOTS_COUNT: int = 3
const TIME_LIMIT: float = 30.0

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var timer_label: Label = $TimerLabel
@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var items_container: HBoxContainer = $ItemsContainer
@onready var hint_label: Label = $HintLabel

var _equipped: Array[String] = []
var _time_left: float = TIME_LIMIT
var _is_active: bool = false

func _ready() -> void:
	node_id = 1
	super._ready()

func enter_node() -> void:
	title_label.text = "节点① 装备选择"
	desc_label.text = "30秒内为勇者配齐3件装备（拖拽到槽位）"
	_setup_items()
	_setup_slots()
	_is_active = true
	_time_left = TIME_LIMIT

func _setup_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	var items: Array[String] = ["剑", "盾", "弓", "魔法书", "面包", "鸡毛掸子"]
	for item_name in items:
		var btn = Button.new()
		btn.text = item_name
		btn.custom_minimum_size = Vector2(120, 80)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_item_pressed.bind(item_name))
		items_container.add_child(btn)

func _setup_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	_equipped.clear()
	for i in range(SLOTS_COUNT):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(150, 100)
		var label = Label.new()
		label.text = "槽位 " + str(i + 1) + "\n(空)"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		slot.add_child(label)
		slots_container.add_child(slot)

func _on_item_pressed(item_name: String) -> void:
	if not _is_active:
		return
	if _equipped.size() >= SLOTS_COUNT:
		hint_label.text = "槽位已满！"
		return
	_equipped.append(item_name)
	ChaosPool.add_keyword(item_name)
	var slot_idx: int = _equipped.size() - 1
	var slot = slots_container.get_child(slot_idx)
	var label = slot.get_child(0) as Label
	label.text = "槽位 " + str(slot_idx + 1) + "\n" + item_name
	hint_label.text = "装备了: " + item_name
	if _equipped.size() >= SLOTS_COUNT:
		hint_label.text = "配装完成！"
		_complete_success()

func _complete_success() -> void:
	_is_active = false
	var outcome: String = "装备: " + ", ".join(_equipped)
	ResourceManager.add_ren_qi(12)
	complete_node(outcome)

func _process(delta: float) -> void:
	if _is_active:
		_time_left -= delta
		timer_label.text = "时间: " + str(int(_time_left)) + "s"
		if _time_left <= 0:
			_is_active = false
			hint_label.text = "时间到！按默认配置出发"
			ResourceManager.add_qi_ren(10)
			complete_node("超时，默认装备")
