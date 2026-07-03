# minigames/DodgeBullets.gd - 躲避弹幕小游戏
extends MiniGameBase
class_name DodgeBullets

@export var player_speed: float = 300.0

var _score: int = 0

func get_game_type() -> String:
	return "dodge_bullets"

func start_game() -> void:
	# TODO: 加载弹幕图案（从混沌池关键词生成）
	pass

func update_game(delta: float) -> void:
	# TODO: 鼠标控制勇者移动 + 弹幕生成与移动
	pass
