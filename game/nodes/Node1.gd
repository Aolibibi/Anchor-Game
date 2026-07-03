# game/nodes/Node1.gd - 节点①脚本（待策划填写内容）
extends NodeBase
class_name Node1

func _ready() -> void:
	node_id = 1
	super._ready()

func enter_node() -> void:
	# TODO: 策划填写节点①的解谜玩法
	pass

func complete_node(outcome: String) -> void:
	super.complete_node(outcome)
