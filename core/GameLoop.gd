# core/GameLoop.gd - 游戏循环辅助管理（时序由ForumUI驱动）
extends Node

var _loop_count: int = 0
var _is_running: bool = false

func _ready() -> void:
	EventBus.node_completed.connect(_on_node_completed)

func start_game() -> void:
	_is_running = true
	_loop_count = 0

func _on_node_completed(node_id: int, _outcome: String) -> void:
	_loop_count += 1

func get_loop_count() -> int:
	return _loop_count

func is_running() -> bool:
	return _is_running
