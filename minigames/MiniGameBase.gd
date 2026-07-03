# minigames/MiniGameBase.gd - 小游戏基类，所有小游戏继承此类
extends Node2D
class_name MiniGameBase

@export var duration: float = 15.0
var chaos_pool_ref: Array = []
var _timer: float = 0.0

func _ready() -> void:
	EventBus.minigame_start.emit(get_game_type())
	_timer = duration
	start_game()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		end_game(false, 0, [])
	update_game(delta)

# 子类必须实现
func get_game_type() -> String:
	return "base"

func start_game() -> void:
	pass

func update_game(delta: float) -> void:
	pass

func end_game(success: bool, score: int = 0, keywords: Array = []) -> void:
	EventBus.minigame_result.emit(success, score, keywords)
	queue_free()
