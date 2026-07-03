# core/ChaosPool.gd - 混沌池管理（关键词积累与组合）
extends Node

const MAX_POOL_SIZE: int = 8

var _keywords: Array[String] = []

func add_keyword(keyword: String) -> void:
	if _keywords.size() >= MAX_POOL_SIZE:
		_keywords.pop_front()  # FIFO淘汰
	_keywords.append(keyword)
	EventBus.keyword_added.emit(keyword)

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

# TODO: 检查搭配表触发组合
func check_combos() -> void:
	# 从 res://data/chaos_combos.json 读取搭配表
	# 检查当前关键词是否命中任何组合
	pass
