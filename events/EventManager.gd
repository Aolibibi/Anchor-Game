# events/EventManager.gd - 论坛事件触发管理
extends Node

var _events: Array = []
var _last_triggered: Dictionary = {}

func _ready() -> void:
	_load_events()
	EventBus.loop_step_completed.connect(_on_loop_step_completed)
	EventBus.player_action.connect(_on_player_action)

func _load_events() -> void:
	var file = FileAccess.open("res://data/events.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and data.has("forum_events"):
			_events = data["forum_events"]

func _on_loop_step_completed(step: int) -> void:
	if step == 6:
		_check_events()

func _on_player_action(action_type: String, data: Dictionary) -> void:
	if action_type == "scold":
		if randf() < 0.2:
			_trigger_event("admin_warning")

func _check_events() -> void:
	if _events.is_empty():
		_rollback_to_basic_events()
	for event in _events:
		if _should_trigger(event):
			_trigger_event(event["id"])
			break

func _rollback_to_basic_events() -> void:
	_events = [
		{"id": "flame_war", "trigger_condition": {"type": "qi_ren", "value": 50}, "trigger_probability": 0.5, "leads_to_node": null},
		{"id": "add_more", "trigger_condition": {"type": "ren_qi", "value": 50}, "trigger_probability": 0.3, "leads_to_node": 1},
		{"id": "gift", "trigger_condition": {"type": "ren_qi", "value": 70}, "trigger_probability": 0.4, "leads_to_node": null},
		{"id": "admin_warning", "trigger_condition": {"type": "qi_ren", "value": 70}, "trigger_probability": 1.0, "leads_to_node": null},
		{"id": "deleted_post", "trigger_condition": {"type": "random", "value": 0}, "trigger_probability": 0.1, "leads_to_node": null}
	]

func _should_trigger(event: Dictionary) -> bool:
	var event_id: String = event["id"]
	if _last_triggered.has(event_id):
		if Time.get_ticks_msec() - _last_triggered[event_id] < 30000:
			return false
	var cond: Dictionary = event.get("trigger_condition", {})
	var cond_type: String = cond.get("type", "")
	var cond_value: int = cond.get("value", 0)
	var met: bool = false
	match cond_type:
		"qi_ren":
			met = ResourceManager.qi_ren >= cond_value
		"ren_qi":
			met = ResourceManager.ren_qi >= cond_value
		"random":
			met = true
	if not met:
		return false
	var prob: float = event.get("trigger_probability", 0.5)
	if randf() < prob:
		_last_triggered[event_id] = Time.get_ticks_msec()
		return true
	return false

func _trigger_event(event_id: String) -> void:
	EventBus.forum_event_triggered.emit(event_id)
	var event: Dictionary = _find_event(event_id)
	if event.is_empty():
		return
	var leads_to: Variant = event.get("leads_to_node", null)
	if leads_to != null and leads_to is int and leads_to > 0:
		await get_tree().create_timer(2.0).timeout
		EventBus.scene_entered.emit("node_" + str(leads_to))
	await get_tree().create_timer(5.0).timeout
	EventBus.forum_event_ended.emit(event_id)

func _find_event(event_id: String) -> Dictionary:
	for e in _events:
		if e["id"] == event_id:
			return e
	return {}
