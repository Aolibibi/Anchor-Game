# Main.gd - 主界面控制器，管理左右双栏与顶部资源条
extends Control

@onready var qi_ren_bar: ProgressBar = $TopBar/QiRenContainer/QiRenBar
@onready var qi_ren_label: Label = $TopBar/QiRenContainer/QiRenLabel
@onready var ren_qi_bar: ProgressBar = $TopBar/RenQiContainer/RenQiBar
@onready var ren_qi_label: Label = $TopBar/RenQiContainer/RenQiLabel
@onready var chapter_label: Label = $TopBar/ChapterLabel
@onready var game_scene_root: Node2D = $GamePanel/GameViewportContainer/GameViewport/GameSceneRoot

func _ready() -> void:
	EventBus.qi_ren_changed.connect(_on_qi_ren_changed)
	EventBus.ren_qi_changed.connect(_on_ren_qi_changed)
	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.dice_result.connect(_on_dice_result)
	_update_resource_bars()
	GameManager.start_game()
	chapter_label.text = GameManager.get_progress_text()

func _update_resource_bars() -> void:
	qi_ren_bar.value = ResourceManager.qi_ren
	qi_ren_label.text = "气人值 " + str(ResourceManager.qi_ren)
	ren_qi_bar.value = ResourceManager.ren_qi
	ren_qi_label.text = "人气值 " + str(ResourceManager.ren_qi)

func _on_qi_ren_changed(value: int, _delta: int) -> void:
	qi_ren_bar.value = value
	qi_ren_label.text = "气人值 " + str(value)
	_check_endings()

func _on_ren_qi_changed(value: int, _delta: int) -> void:
	ren_qi_bar.value = value
	ren_qi_label.text = "人气值 " + str(value)
	_check_endings()

func _on_scene_entered(scene_id: String) -> void:
	_clear_game_scene()
	if scene_id.begins_with("node_"):
		_load_node_scene(scene_id)
	elif scene_id.begins_with("ending_"):
		_load_ending_scene(scene_id)
		chapter_label.text = GameManager.get_progress_text()
	else:
		_load_random_scene(scene_id)
	chapter_label.text = GameManager.get_progress_text()

func _on_dice_result(_roll_value: int, _selected_option: Dictionary) -> void:
	pass

func _check_endings() -> void:
	if GameManager.game_ended:
		return
	if ResourceManager.qi_ren >= 100:
		EventBus.scene_entered.emit("ending_banned")
	elif ResourceManager.ren_qi >= 100:
		EventBus.scene_entered.emit("ending_become_author")

func _clear_game_scene() -> void:
	for child in game_scene_root.get_children():
		child.queue_free()

func _load_node_scene(scene_id: String) -> void:
	var node_num: int = scene_id.substr(5).to_int()
	var scene_path: String = "res://game/nodes/Node" + str(node_num) + ".tscn"
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path).instantiate()
		game_scene_root.add_child(scene)

func _load_ending_scene(scene_id: String) -> void:
	var label = Label.new()
	label.text = "【结局】\n" + GameManager.get_progress_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.position = Vector2(200, 400)
	label.size = Vector2(800, 200)
	game_scene_root.add_child(label)

func _load_random_scene(scene_id: String) -> void:
	var label = Label.new()
	label.text = "场景: " + scene_id + "\n（随机事件，等待论坛安价...）"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.position = Vector2(200, 450)
	label.size = Vector2(800, 150)
	game_scene_root.add_child(label)
