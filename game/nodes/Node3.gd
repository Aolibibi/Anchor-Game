# game/nodes/Node3.gd - 节点③脚本（待策划填写内容）
extends NodeBase
class_name Node3

func _ready() -> void:
	node_id = 3
	super._ready()

func enter_node() -> void:
	# TODO: 策划填写节点③的解谜玩法
	pass

func complete_node(outcome: String) -> void:
	super.complete_node(outcome)
