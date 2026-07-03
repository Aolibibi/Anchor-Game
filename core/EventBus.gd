# core/EventBus.gd - 全局信号总线，所有模块通过信号通信
# 此文件为所有模块的通信枢纽，禁止修改信号签名（除非全员同意）
extends Node

# === 循环流程信号 ===
signal scene_entered(scene_id: String)
signal options_ready(roll_pool: Array)
signal player_action(action_type: String, data: Dictionary)
signal dice_rolling()
signal dice_result(roll_value: int, selected_option: Dictionary)
signal minigame_start(game_type: String)
signal minigame_result(success: bool, score: int, keywords: Array)
signal loop_step_completed(step: int)

# === 资源信号 ===
signal qi_ren_changed(value: int, delta: int)
signal ren_qi_changed(value: int, delta: int)

# === 节点信号 ===
signal node_entered(node_id: int)
signal node_completed(node_id: int, outcome: String)

# === 论坛事件信号 ===
signal forum_event_triggered(event_id: String)
signal forum_event_ended(event_id: String)

# === 混沌池信号 ===
signal keyword_added(keyword: String)
signal keyword_consumed(keyword: String)
signal combo_triggered(combo_id: String, result: Dictionary)
