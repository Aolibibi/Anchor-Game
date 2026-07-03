# forum/ForumUI.gd - 论坛主界面UI控制
extends Control

func _ready() -> void:
	# TODO: 连接EventBus信号
	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.dice_result.connect(_on_dice_result)
	EventBus.forum_event_triggered.connect(_on_forum_event_triggered)

func _on_scene_entered(scene_id: String) -> void:
	pass  # TODO: 更新论坛显示

func _on_dice_result(roll_value: int, selected_option: Dictionary) -> void:
	pass  # TODO: 显示骰子结果

func _on_forum_event_triggered(event_id: String) -> void:
	pass  # TODO: 显示论坛事件
