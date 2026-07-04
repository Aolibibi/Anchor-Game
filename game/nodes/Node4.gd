# game/nodes/Node4.gd - 节点④：密码锁（卡牌拼点）
extends NodeBase
class_name Node4

const TARGET_SUM: int = 250
const SLOTS_COUNT: int = 5
const SUCCESS_REN_QI: int = 15
const CLOSE_QI_REN: int = 5
const FAILURE_QI_REN: int = 10

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var timer_label: Label = $TimerLabel
@onready var target_label: Label = $TargetLabel
@onready var current_label: Label = $CurrentLabel
@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var cards_container: HBoxContainer = $CardsContainer
@onready var reset_button: Button = $ResetButton
@onready var hint_label: Label = $HintLabel

var _is_active: bool = false
var _card_values: Array[int] = []
var _placed_values: Array[int] = []

func _ready() -> void:
	node_id = 4
	super._ready()

func enter_node() -> void:
	title_label.text = "节点④ 密码锁"
	desc_label.text = "点击5张卡牌放入槽位，让总和等于目标值"
	target_label.text = "目标: 总和 = " + str(TARGET_SUM)
	hint_label.text = "从8张卡牌中选择5张，点错可以点击重置"
	reset_button.text = "重置"
	reset_button.pressed.connect(_reset)
	_is_active = true
	_generate_cards()
	_setup_slots()
	_update_timer()

func _generate_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	_card_values = [20, 35, 45, 65, 85, 30, 70, 95]
	_card_values.shuffle()
	for card_value in _card_values:
		var button: Button = Button.new()
		button.text = str(card_value)
		button.custom_minimum_size = Vector2(100, 140)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_on_card_pressed.bind(card_value, button))
		cards_container.add_child(button)

func _setup_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	_placed_values.clear()
	for slot_index in range(SLOTS_COUNT):
		var slot: Panel = Panel.new()
		slot.custom_minimum_size = Vector2(110, 150)
		var label: Label = Label.new()
		label.text = "槽位 " + str(slot_index + 1) + "\n?"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		slot.add_child(label)
		slots_container.add_child(slot)
	_update_current()

func _on_card_pressed(card_value: int, button: Button) -> void:
	if not _is_active:
		return
	if _placed_values.size() >= SLOTS_COUNT:
		hint_label.text = "槽位已满，点击重置清空"
		return
	_placed_values.append(card_value)
	button.disabled = true
	button.modulate = Color(0.5, 0.5, 0.5, 0.5)
	var slot_index: int = _placed_values.size() - 1
	var slot: Node = slots_container.get_child(slot_index)
	var label: Label = slot.get_child(0) as Label
	label.text = "槽位 " + str(slot_index + 1) + "\n" + str(card_value)
	hint_label.text = "放入卡牌: " + str(card_value)
	_update_current()
	if _placed_values.size() >= SLOTS_COUNT:
		_check_result()

func _update_current() -> void:
	current_label.text = "当前: " + str(_get_current_total())

func _get_current_total() -> int:
	var total: int = 0
	for card_value in _placed_values:
		total += card_value
	return total

func _check_result() -> void:
	var total: int = _get_current_total()
	var difference: int = abs(total - TARGET_SUM)
	if total == TARGET_SUM:
		_complete_success()
	elif difference <= 10:
		hint_label.text = "接近了！差" + str(difference) + "，点击重置再试"
		ResourceManager.add_qi_ren(CLOSE_QI_REN)
	else:
		hint_label.text = "差太远，完全不对。差" + str(difference) + "，点击重置再试"
		ResourceManager.add_qi_ren(FAILURE_QI_REN)

func _complete_success() -> void:
	_is_active = false
	hint_label.text = "完美！密码锁打开！"
	ResourceManager.add_ren_qi(SUCCESS_REN_QI)
	complete_node("密码锁开启")

func _reset() -> void:
	if not _is_active:
		return
	for child in cards_container.get_children():
		var button: Button = child as Button
		button.disabled = false
		button.modulate = Color(1, 1, 1, 1)
	_setup_slots()
	hint_label.text = "已重置，请重新选择5张卡牌"

func _update_timer() -> void:
	timer_label.text = "时间: 不限"
