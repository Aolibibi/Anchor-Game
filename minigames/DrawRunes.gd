# minigames/DrawRunes.gd - 画线连符文小游戏（15-20秒）
extends MiniGameBase
class_name DrawRunes

const RUNE_PAIRS: int = 4

@onready var line_2d: Line2D = $Line2D
@onready var hint_label: Label = $HintLabel
@onready var progress_label: Label = $ProgressLabel

var _runes: Array = []
var _connected_count: int = 0
var _first_selected: int = -1
var _is_drawing: bool = false

func get_game_type() -> String:
	return "draw_runes"

func start_game() -> void:
	duration = 18.0
	_timer = duration
	_connected_count = 0
	_setup_runes()

func _setup_runes() -> void:
	var colors: Array[Color] = [Color(1,0.3,0.3), Color(0.3,0.5,1), Color(0.3,0.9,0.3), Color(1,0.9,0.2)]
	var names: Array[String] = ["红", "蓝", "绿", "黄"]
	for i in range(RUNE_PAIRS):
		for j in range(2):
			var btn = Button.new()
			btn.text = names[i] + "符文"
			btn.position = Vector2(randf_range(150, 1000), randf_range(200, 850))
			btn.size = Vector2(120, 60)
			btn.add_theme_color_override("font_color", colors[i])
			btn.add_theme_font_size_override("font_size", 18)
			btn.set_meta("color_idx", i)
			btn.pressed.connect(_on_rune_pressed.bind(len(_runes)))
			add_child(btn)
			_runes.append(btn)
	_update_progress()

func _on_rune_pressed(idx: int) -> void:
	if _first_selected == -1:
		_first_selected = idx
		_runes[idx].modulate = Color(1.5, 1.5, 1.5)
		hint_label.text = "选中，点击同色另一个连接"
	elif _first_selected == idx:
		_first_selected = -1
		_runes[idx].modulate = Color(1, 1, 1)
		hint_label.text = "取消"
	else:
		var c1: int = _runes[_first_selected].get_meta("color_idx")
		var c2: int = _runes[idx].get_meta("color_idx")
		if c1 == c2:
			_runes[_first_selected].modulate = Color(0.5, 1, 0.5)
			_runes[idx].modulate = Color(0.5, 1, 0.5)
			_runes[_first_selected].disabled = true
			_runes[idx].disabled = true
			_connected_count += 1
			_update_progress()
			hint_label.text = "连接成功！"
			if _connected_count >= RUNE_PAIRS:
				ResourceManager.add_ren_qi(15)
				end_game(true, _connected_count * 25, ["符文"])
		else:
			hint_label.text = "颜色不符！"
			_runes[_first_selected].modulate = Color(1, 1, 1)
		_first_selected = -1

func _update_progress() -> void:
	progress_label.text = "进度: " + str(_connected_count) + "/" + str(RUNE_PAIRS)

func update_game(delta: float) -> void:
	pass
