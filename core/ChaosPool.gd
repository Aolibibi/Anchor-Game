# core/ChaosPool.gd - 混沌池管理（关键词积累与组合）
extends Node

const MAX_POOL_SIZE: int = 8

var _keywords: Array[String] = []
var _combos: Array = []

func _ready() -> void:
	_load_combos()

func _load_combos() -> void:
	var file = FileAccess.open("res://data/chaos_combos.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and data.has("combos"):
			_combos = data["combos"]

func add_keyword(keyword: String) -> void:
	if _keywords.size() >= MAX_POOL_SIZE:
		_keywords.pop_front()
	_keywords.append(keyword)
	EventBus.keyword_added.emit(keyword)
	check_combos()

func consume_keyword(keyword: String) -> bool:
	if keyword in _keywords:
		_keywords.erase(keyword)
		EventBus.keyword_consumed.emit(keyword)
		return true
	return false

func get_keywords() -> Array[String]:
	return _keywords

func clear() -> void:
	_keywords.clear()

func check_combos() -> void:
	for combo in _combos:
		if _has_all_keywords(combo["keywords"]):
			EventBus.combo_triggered.emit(combo["id"], combo)
			return

func _has_all_keywords(required: Array) -> bool:
	for kw in required:
		if not (kw in _keywords):
			return false
	return true

func get_keywords_text() -> String:
	if _keywords.is_empty():
		return "（空）"
	return ", ".join(_keywords)
