# minigames/SlotMachine.gd - 拉霸小游戏
extends MiniGameBase
class_name SlotMachine

const REEL_COUNT: int = 3
const SYMBOL_COUNT: int = 8
const SYMBOLS_PER_REEL: int = 3
const SYMBOL_SIZE: Vector2 = Vector2(84.0, 56.0)
const SYMBOL_X: float = 23.0
const SYMBOL_START_Y: float = 26.0
const SYMBOL_GAP: float = 72.0
const TIMER_BAR_SIZE: Vector2 = Vector2(360.0, 12.0)
const STOP_SCORE: int = 12
const PAIR_SCORE: int = 70
const JACKPOT_SCORE: int = 100
const RESULT_DELAY: float = 0.35
const SUCCESS_KEYWORDS: Array[String] = ["luck", "slot"]
const JACKPOT_KEYWORDS: Array[String] = ["luck", "jackpot"]
const SYMBOL_COLORS: Array[Color] = [
	Color(0.95, 0.22, 0.28),
	Color(1.00, 0.58, 0.18),
	Color(0.96, 0.84, 0.24),
	Color(0.24, 0.78, 0.42),
	Color(0.25, 0.54, 0.96),
	Color(0.64, 0.34, 0.92),
	Color(0.95, 0.46, 0.74),
	Color(0.70, 0.92, 0.95)
]

@export var base_spin_interval: float = 0.08

@onready var _reel_1: ColorRect = $ReelContainer/Reel1
@onready var _reel_2: ColorRect = $ReelContainer/Reel2
@onready var _reel_3: ColorRect = $ReelContainer/Reel3
@onready var _stop_1: ColorRect = $StopIndicators/Stop1
@onready var _stop_2: ColorRect = $StopIndicators/Stop2
@onready var _stop_3: ColorRect = $StopIndicators/Stop3
@onready var _timer_fill: ColorRect = $Hud/TimerFill
@onready var _result_flash: ColorRect = $Hud/ResultFlash

var _score: int = 0
var _next_reel_to_stop: int = 0
var _is_finished: bool = false
var _result_timer: float = -1.0
var _result_success: bool = false
var _result_score: int = 0
var _result_keywords: Array[String] = []
var _reel_nodes: Array[ColorRect] = []
var _stop_nodes: Array[ColorRect] = []
var _symbol_nodes: Array = []
var _reel_values: Array[int] = []
var _reel_step_timers: Array[float] = []
var _reel_intervals: Array[float] = []
var _reel_stopped: Array[bool] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func get_game_type() -> String:
	return "slot_machine"

func start_game() -> void:
	_rng.randomize()
	_score = 0
	_next_reel_to_stop = 0
	_is_finished = false
	_result_timer = -1.0
	_result_success = false
	_result_score = 0
	_result_keywords.clear()
	_reel_nodes = [_reel_1, _reel_2, _reel_3]
	_stop_nodes = [_stop_1, _stop_2, _stop_3]
	_setup_reels()
	_update_all_reel_visuals()
	_update_hud()
	set_process_input(true)

func update_game(delta: float) -> void:
	if _is_finished:
		return

	if _result_timer >= 0.0:
		_result_timer -= delta
		_update_result_flash()
		if _result_timer <= 0.0:
			end_game(_result_success, _result_score, _result_keywords.duplicate())
		return

	_spin_reels(delta)
	_update_hud()

func _input(event: InputEvent) -> void:
	if _is_finished or _result_timer >= 0.0:
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_stop_next_reel()

func end_game(success: bool, score: int = 0, keywords: Array = []) -> void:
	if _is_finished:
		return
	_is_finished = true
	set_process_input(false)
	super.end_game(success, score, keywords)

func _setup_reels() -> void:
	_symbol_nodes.clear()
	_reel_values.clear()
	_reel_step_timers.clear()
	_reel_intervals.clear()
	_reel_stopped.clear()

	for reel_index in range(REEL_COUNT):
		_clear_reel_children(_reel_nodes[reel_index])
		_symbol_nodes.append([])
		_reel_values.append(_rng.randi_range(0, SYMBOL_COUNT - 1))
		_reel_step_timers.append(0.0)
		_reel_intervals.append(base_spin_interval + float(reel_index) * 0.025)
		_reel_stopped.append(false)
		_build_reel_symbols(reel_index)
		_stop_nodes[reel_index].color = Color(0.42, 0.42, 0.48, 1)

func _clear_reel_children(reel_node: ColorRect) -> void:
	for child in reel_node.get_children():
		child.queue_free()

func _build_reel_symbols(reel_index: int) -> void:
	var reel_symbols: Array = _symbol_nodes[reel_index]
	var reel_node: ColorRect = _reel_nodes[reel_index]

	for symbol_index in range(SYMBOLS_PER_REEL):
		var symbol_node: ColorRect = ColorRect.new()
		symbol_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol_node.size = SYMBOL_SIZE
		symbol_node.position = Vector2(SYMBOL_X, SYMBOL_START_Y + float(symbol_index) * SYMBOL_GAP)
		reel_node.add_child(symbol_node)
		reel_symbols.append(symbol_node)

	_symbol_nodes[reel_index] = reel_symbols

func _spin_reels(delta: float) -> void:
	for reel_index in range(REEL_COUNT):
		if _reel_stopped[reel_index]:
			continue

		_reel_step_timers[reel_index] += delta
		if _reel_step_timers[reel_index] >= _reel_intervals[reel_index]:
			_reel_step_timers[reel_index] = 0.0
			_reel_values[reel_index] = (_reel_values[reel_index] + 1) % SYMBOL_COUNT
			_update_reel_visual(reel_index)

func _stop_next_reel() -> void:
	if _next_reel_to_stop >= REEL_COUNT:
		return

	_reel_stopped[_next_reel_to_stop] = true
	_stop_nodes[_next_reel_to_stop].color = Color(0.42, 0.9, 0.76, 1)
	_score = clampi(_score + STOP_SCORE, 0, 100)
	_update_reel_visual(_next_reel_to_stop)
	_next_reel_to_stop += 1

	if _next_reel_to_stop >= REEL_COUNT:
		_prepare_result()

func _prepare_result() -> void:
	var first_value: int = _reel_values[0]
	var second_value: int = _reel_values[1]
	var third_value: int = _reel_values[2]
	var has_jackpot: bool = first_value == second_value and second_value == third_value
	var has_pair: bool = first_value == second_value or first_value == third_value or second_value == third_value

	if has_jackpot:
		_result_success = true
		_result_score = JACKPOT_SCORE
		_result_keywords = JACKPOT_KEYWORDS.duplicate()
	elif has_pair:
		_result_success = true
		_result_score = PAIR_SCORE
		_result_keywords = SUCCESS_KEYWORDS.duplicate()
	else:
		_result_success = false
		_result_score = clampi(_score, 0, 45)
		_result_keywords = []

	_result_timer = RESULT_DELAY
	_update_result_flash()

func _update_all_reel_visuals() -> void:
	for reel_index in range(REEL_COUNT):
		_update_reel_visual(reel_index)

func _update_reel_visual(reel_index: int) -> void:
	var reel_symbols: Array = _symbol_nodes[reel_index]
	var center_value: int = _reel_values[reel_index]

	for symbol_index in range(SYMBOLS_PER_REEL):
		var symbol_node: ColorRect = reel_symbols[symbol_index]
		var symbol_value: int = (center_value + symbol_index - 1 + SYMBOL_COUNT) % SYMBOL_COUNT
		var symbol_color: Color = SYMBOL_COLORS[symbol_value]

		if symbol_index == 1:
			symbol_color = symbol_color.lightened(0.16)
		else:
			symbol_color.a = 0.58

		symbol_node.color = symbol_color

func _update_hud() -> void:
	var time_ratio: float = clampf(maxf(_timer, 0.0) / duration, 0.0, 1.0)
	_timer_fill.size = Vector2(TIMER_BAR_SIZE.x * time_ratio, TIMER_BAR_SIZE.y)

func _update_result_flash() -> void:
	var alpha: float = 0.0
	if _result_timer >= 0.0:
		alpha = clampf(_result_timer / RESULT_DELAY, 0.0, 1.0) * 0.28

	if _result_success:
		_result_flash.color = Color(0.42, 0.9, 0.76, alpha)
	else:
		_result_flash.color = Color(1.0, 0.08, 0.06, alpha)