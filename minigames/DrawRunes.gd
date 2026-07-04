# minigames/DrawRunes.gd - 画线连符文小游戏
extends MiniGameBase
class_name DrawRunes

const PLAY_AREA_SIZE: Vector2 = Vector2(1190.0, 800.0)
const RUNE_SIZE: Vector2 = Vector2(64.0, 64.0)
const PROGRESS_BAR_SIZE: Vector2 = Vector2(360.0, 12.0)
const TIMER_BAR_SIZE: Vector2 = Vector2(360.0, 8.0)
const RUNE_HIT_RADIUS: float = 48.0
const SCORE_PER_RUNE: int = 18
const WRONG_RUNE_PENALTY: int = 10
const MISTAKE_COOLDOWN: float = 0.35
const TRAIL_POINT_MIN_DISTANCE: float = 7.0
const SUCCESS_KEYWORDS: Array[String] = ["rune", "line"]
const RUNE_COLORS: Array[Color] = [
	Color(0.95, 0.22, 0.24),
	Color(1.00, 0.56, 0.18),
	Color(0.96, 0.84, 0.25),
	Color(0.24, 0.76, 0.38),
	Color(0.24, 0.52, 0.95),
	Color(0.64, 0.34, 0.92)
]

@export_range(3, 8, 1) var target_count: int = 5

@onready var _completed_line: Line2D = $CompletedLine
@onready var _trail_line: Line2D = $TrailLine
@onready var _rune_container: Node2D = $RuneContainer
@onready var _progress_fill: ColorRect = $Hud/ProgressFill
@onready var _timer_fill: ColorRect = $Hud/TimerFill
@onready var _mistake_flash: ColorRect = $Hud/MistakeFlash

var _score: int = 0
var _current_index: int = 0
var _is_drawing: bool = false
var _is_finished: bool = false
var _mistake_cooldown: float = 0.0
var _rune_positions: Array[Vector2] = []
var _rune_completed: Array[bool] = []
var _rune_nodes: Array[ColorRect] = []
var _trail_points: PackedVector2Array = PackedVector2Array()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func get_game_type() -> String:
	return "draw_runes"

func start_game() -> void:
	_rng.randomize()
	_score = 0
	_current_index = 0
	_is_drawing = false
	_is_finished = false
	_mistake_cooldown = 0.0
	_trail_points = PackedVector2Array()
	_clear_runes()
	_generate_runes()
	_build_rune_blocks()
	_update_visuals()
	set_process_input(true)

func update_game(delta: float) -> void:
	if _is_finished:
		return

	if _mistake_cooldown > 0.0:
		_mistake_cooldown = maxf(0.0, _mistake_cooldown - delta)

	if _is_drawing:
		var mouse_position: Vector2 = _clamp_to_play_area(get_local_mouse_position())
		_add_trail_point(mouse_position)
		_check_rune_touch(mouse_position)

	_update_visuals()

func _input(event: InputEvent) -> void:
	if _is_finished:
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_is_drawing = mouse_button.pressed
			if _is_drawing:
				_trail_points = PackedVector2Array()
				var mouse_position: Vector2 = _clamp_to_play_area(get_local_mouse_position())
				_add_trail_point(mouse_position)
				_check_rune_touch(mouse_position)
			_update_visuals()

	elif event is InputEventMouseMotion and _is_drawing:
		var mouse_position: Vector2 = _clamp_to_play_area(get_local_mouse_position())
		_add_trail_point(mouse_position)
		_check_rune_touch(mouse_position)
		_update_visuals()

func end_game(success: bool, score: int = 0, keywords: Array = []) -> void:
	if _is_finished:
		return
	_is_finished = true
	set_process_input(false)
	super.end_game(success, score, keywords)

func _clear_runes() -> void:
	_rune_positions.clear()
	_rune_completed.clear()
	_rune_nodes.clear()

	for child in _rune_container.get_children():
		child.queue_free()

func _generate_runes() -> void:
	var count: int = clampi(target_count, 3, 8)
	var margin: float = 90.0
	var usable_width: float = PLAY_AREA_SIZE.x - margin * 2.0
	var min_y: float = 150.0
	var max_y: float = PLAY_AREA_SIZE.y - 110.0

	for index in range(count):
		var ratio: float = (float(index) + 0.5) / float(count)
		var position: Vector2 = Vector2(
			margin + usable_width * ratio,
			_rng.randf_range(min_y, max_y)
		)
		_rune_positions.append(position)
		_rune_completed.append(false)

func _build_rune_blocks() -> void:
	for index in range(_rune_positions.size()):
		var rune_node: ColorRect = ColorRect.new()
		rune_node.name = "Rune%d" % [index + 1]
		rune_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rune_container.add_child(rune_node)
		_rune_nodes.append(rune_node)

func _add_trail_point(point: Vector2) -> void:
	if _trail_points.size() > 0 and _trail_points[-1].distance_to(point) < TRAIL_POINT_MIN_DISTANCE:
		return
	_trail_points.append(point)

func _check_rune_touch(point: Vector2) -> void:
	for index in range(_rune_positions.size()):
		if _rune_completed[index]:
			continue

		if point.distance_to(_rune_positions[index]) <= RUNE_HIT_RADIUS:
			if index == _current_index:
				_complete_current_rune()
			elif _mistake_cooldown <= 0.0:
				_apply_wrong_rune_penalty()
			return

func _complete_current_rune() -> void:
	_rune_completed[_current_index] = true
	_score += SCORE_PER_RUNE
	_current_index += 1
	_trail_points = PackedVector2Array()

	if _current_index >= _rune_positions.size():
		var time_bonus: int = int((maxf(_timer, 0.0) / duration) * 40.0)
		var final_score: int = clampi(_score + time_bonus, 0, 100)
		end_game(true, final_score, SUCCESS_KEYWORDS.duplicate())

func _apply_wrong_rune_penalty() -> void:
	_score = max(0, _score - WRONG_RUNE_PENALTY)
	_mistake_cooldown = MISTAKE_COOLDOWN
	_trail_points = PackedVector2Array()

func _update_visuals() -> void:
	_update_rune_blocks()
	_update_lines()
	_update_bars()
	_update_flash()

func _update_rune_blocks() -> void:
	for index in range(_rune_nodes.size()):
		var rune_node: ColorRect = _rune_nodes[index]
		var is_completed: bool = _rune_completed[index]
		var is_current: bool = index == _current_index
		var color: Color = RUNE_COLORS[index % RUNE_COLORS.size()]
		var size: Vector2 = RUNE_SIZE

		if is_current:
			size = RUNE_SIZE * 1.18
			color = color.lightened(0.18)
		elif is_completed:
			color = color.lightened(0.08)
		else:
			color.a = 0.42

		rune_node.size = size
		rune_node.position = _rune_positions[index] - size * 0.5
		rune_node.color = color

func _update_lines() -> void:
	var completed_points: PackedVector2Array = PackedVector2Array()
	for index in range(_current_index):
		completed_points.append(_rune_positions[index])

	_completed_line.points = completed_points
	_trail_line.points = _trail_points

func _update_bars() -> void:
	var progress_ratio: float = 0.0
	if _rune_positions.size() > 0:
		progress_ratio = float(_current_index) / float(_rune_positions.size())

	var time_ratio: float = clampf(maxf(_timer, 0.0) / duration, 0.0, 1.0)
	_progress_fill.size = Vector2(PROGRESS_BAR_SIZE.x * progress_ratio, PROGRESS_BAR_SIZE.y)
	_timer_fill.size = Vector2(TIMER_BAR_SIZE.x * time_ratio, TIMER_BAR_SIZE.y)

func _update_flash() -> void:
	var alpha: float = 0.0
	if _mistake_cooldown > 0.0:
		alpha = (_mistake_cooldown / MISTAKE_COOLDOWN) * 0.22
	_mistake_flash.color = Color(1.0, 0.08, 0.06, alpha)

func _clamp_to_play_area(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, 0.0, PLAY_AREA_SIZE.x),
		clampf(point.y, 0.0, PLAY_AREA_SIZE.y)
	)