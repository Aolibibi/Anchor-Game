# ui/ResourceBar.gd - 资源条UI（气人值/人气值）
extends Control

@export var bar_type: String = "qi_ren"  # "qi_ren" 或 "ren_qi"

func _ready() -> void:
	if bar_type == "qi_ren":
		EventBus.qi_ren_changed.connect(_on_value_changed)
	else:
		EventBus.ren_qi_changed.connect(_on_value_changed)

func _on_value_changed(value: int, delta: int) -> void:
	# TODO: 更新资源条显示
	pass
