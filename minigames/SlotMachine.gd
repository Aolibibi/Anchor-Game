# minigames/SlotMachine.gd - 拉霸小游戏
extends MiniGameBase
class_name SlotMachine

var _score: int = 0

func get_game_type() -> String:
	return "slot_machine"

func start_game() -> void:
	# TODO: 初始化3个滚轮（图案来自混沌池）
	pass

func update_game(delta: float) -> void:
	# TODO: 滚轮动画 + 点击停止判定
	pass
