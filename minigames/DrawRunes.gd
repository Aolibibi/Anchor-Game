# minigames/DrawRunes.gd - 画线连符文小游戏
extends MiniGameBase
class_name DrawRunes

var _score: int = 0

func get_game_type() -> String:
	return "draw_runes"

func start_game() -> void:
	# TODO: 生成符文点（颜色来自混沌池）
	pass

func update_game(delta: float) -> void:
	# TODO: 鼠标画线检测 + 连线判定
	pass
