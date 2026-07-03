# game/nodes/NodeBase.gd - 节点基类，所有节点继承此类
extends Node2D
class_name NodeBase

@export var node_id: int = 0
var preset_options: Array = []

func _ready() -> void:
	EventBus.node_entered.emit(node_id)
	_load_options()
	enter_node()

func _load_options() -> void:
	var file = FileAccess.open("res://data/options.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data.has(str(node_id)):
			preset_options = data[str(node_id)]

func enter_node() -> void:
	pass  # 子类实现

func complete_node(outcome: String) -> void:
	EventBus.node_completed.emit(node_id, outcome)
