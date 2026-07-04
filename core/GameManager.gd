# core/GameManager.gd - 全局游戏状态管理
extends Node

const TOTAL_NODES: int = 5

var current_chapter: int = 1
var current_node_index: int = 1
var game_started: bool = false
var game_ended: bool = false
var ending_type: String = ""

func _ready() -> void:
	EventBus.node_entered.connect(_on_node_entered)
	EventBus.node_completed.connect(_on_node_completed)
	EventBus.scene_entered.connect(_on_scene_entered)

func start_game() -> void:
	game_started = true
	game_ended = false
	current_chapter = 1
	current_node_index = 1
	ResourceManager.qi_ren = 0
	ResourceManager.ren_qi = 0

func _on_node_entered(node_id: int) -> void:
	current_node_index = node_id
	current_chapter = node_id

func _on_node_completed(node_id: int, outcome: String) -> void:
	if node_id >= TOTAL_NODES:
		_trigger_ending()

func _on_scene_entered(scene_id: String) -> void:
	if scene_id.begins_with("ending_"):
		game_ended = true
		ending_type = scene_id.substr(8)

func _trigger_ending() -> void:
	var ending: String = "normal"
	if ResourceManager.qi_ren >= 100:
		ending = "banned"
	elif ResourceManager.ren_qi >= 100:
		ending = "become_author"
	elif ResourceManager.qi_ren >= 80 and ResourceManager.ren_qi >= 80:
		ending = "dual_cultivation"
	EventBus.scene_entered.emit("ending_" + ending)

func get_progress_text() -> String:
	if game_ended:
		return "结局: " + _get_ending_name()
	return "章节 " + str(current_chapter) + "/5  循环中"

func _get_ending_name() -> String:
	match ending_type:
		"banned": return "封号结局"
		"become_author": return "成为楼主"
		"dual_cultivation": return "双修结局"
		_: return "正常结局"
