# core/ResourceManager.gd - 气人值/人气值管理
extends Node

var qi_ren: int = 0    # 气人值 0-100
var ren_qi: int = 0    # 人气值 0-100

func add_qi_ren(amount: int) -> void:
	qi_ren = clamp(qi_ren + amount, 0, 100)
	EventBus.qi_ren_changed.emit(qi_ren, amount)

func add_ren_qi(amount: int) -> void:
	ren_qi = clamp(ren_qi + amount, 0, 100)
	EventBus.ren_qi_changed.emit(ren_qi, amount)

func spend_ren_qi(amount: int) -> bool:
	if ren_qi >= amount:
		ren_qi -= amount
		EventBus.ren_qi_changed.emit(ren_qi, -amount)
		return true
	return false

# 返回0-3: 0低(0-29) 1中(30-49) 2高(50-69) 3满(70-100)
func get_qi_ren_level() -> int:
	if qi_ren >= 70:
		return 3
	elif qi_ren >= 50:
		return 2
	elif qi_ren >= 30:
		return 1
	else:
		return 0

func get_ren_qi_level() -> int:
	if ren_qi >= 70:
		return 3
	elif ren_qi >= 50:
		return 2
	elif ren_qi >= 30:
		return 1
	else:
		return 0
