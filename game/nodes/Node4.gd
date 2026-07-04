# game/nodes/Node4.gd - 节点④：密码锁（卡牌拼点）
extends NodeBase
class_name Node4

const TARGET_SUM: int = 250
const SLOTS_COUNT: int = 5

@onready var title_label: Label = $TitleLabel
@onready var target_label: Label = $TargetLabel
@onready var current_label: Label = $CurrentLabel
@onready var hint_label: Label = $HintLabel
@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var cards_container: HBoxContainer = $CardsContainer

var _card_values: Array[int] = []
var _placed_values: Array[int] = []
var _is_completed: bool = false

func _ready() -> void:
	node_id = 4
	super._ready()

func enter_node() -> void:
	title_label.text = "节点④ 密码锁"
	target_label.text = "目标: 总和 = " + str(TARGET_SUM)
	hint_label.text = "点击卡牌放入槽位，5张总和需等于目标"
	_generate_cards()
	_setup_slots()

func _generate_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	_card_values.clear()
	for i in range(8):
		var val: int = randi_range(20, 80)
		_card_values.append(val)
		var btn = Button.new()
		btn.text = str(val)
		btn.custom_minimum_size = Vector2(100, 140)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_card_pressed.bind(val, btn))
		cards_container.add_child(btn)

func _setup_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	_placed_values.clear()
	for i in range(SLOTS_COUNT):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(110, 150)
		var label = Label.new()
		label.text = "?"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 32)
		slot.add_child(label)
		slots_container.add_child(slot)
	_update_current()

func _on_card_pressed(val: int, btn: Button) -> void:
	if _is_completed:
		return
	if _placed_values.size() >= SLOTS_COUNT:
		hint_label.text = "槽位已满，点击[重置]清空"
		return
	_placed_values.append(val)
	btn.disabled = true
	btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
	var idx: int = _placed_values.size() - 1
	var slot = slots_container.get_child(idx)
	var label = slot.get_child(0) as Label
	label.text = str(val)
	_update_current()
	if _placed_values.size() >= SLOTS_COUNT:
		_check_result()

func _update_current() -> void:
	var total: int = 0
	for v in _placed_values:
		total += v
	current_label.text = "当前: " + str(total)

func _check_result() -> void:
	var total: int = 0
	for v in _placed_values:
		total += v
	if total == TARGET_SUM:
		hint_label.text = "完美！密码锁打开！"
		_is_completed = true
		ResourceManager.add_ren_qi(15)
		complete_node("密码锁开启")
	elif abs(total - TARGET_SUM) <= 10:
		hint_label.text = "接近了！差" + str(abs(total - TARGET_SUM)) + "，锁卡住了"
		ResourceManager.add_qi_ren(5)
	else:
		hint_label.text = "差太远，完全不对。差" + str(abs(total - TARGET_SUM))
		ResourceManager.add_qi_ren(10)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reset()

func _reset() -> void:
	if _is_completed:
		return
	for child in cards_container.get_children():
		var btn = child as Button
		btn.disabled = false
		btn.modulate = Color(1, 1, 1, 1)
	_setup_slots()
	hint_label.text = "已重置，按R可再次重置"
