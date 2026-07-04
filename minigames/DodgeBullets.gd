# minigames/DodgeBullets.gd - 躲避弹幕小游戏
extends MiniGameBase
class_name DodgeBullets

const PLAY_AREA_SIZE: Vector2 = Vector2(1190.0, 800.0)
const PLAYER_SIZE: Vector2 = Vector2(32.0, 32.0)
const PLAYER_RADIUS: float = 18.0
const BULLET_SIZE: Vector2 = Vector2(32.0, 32.0)
const BULLET_RADIUS: float = 18.0
const TIMER_BAR_SIZE: Vector2 = Vector2(360.0, 12.0)
const DANGER_BAR_SIZE: Vector2 = Vector2(360.0, 8.0)
const SPAWN_PADDING: float = 48.0
const BASE_SPAWN_INTERVAL: float = 0.72
const MIN_SPAWN_INTERVAL: float = 0.22
const BULLET_SPEED_MIN: float = 170.0
const BULLET_SPEED_MAX: float = 330.0
const SCORE_PER_DODGED_BULLET: int = 3
const SUCCESS_BASE_SCORE: int = 55
const SUCCESS_KEYWORDS: Array[String] = ["dodge", "focus"]
const BULLET_COLORS: Array[Color] = [
	Color(0.95, 0.22, 0.28),
	Color(1.00, 0.62, 0.18),
	Color(0.95, 0.86, 0.22),
	Color(0.72, 0.38, 0.92),
	Color(0.22, 0.90, 0.78)
]

@export var player_speed: float = 520.0

@onready var _player: Node2D = $Player
@onready var _player_visual: ColorRect = $Player/PlayerVisual
@onready var _bullet_container: Node2D = $BulletContainer
@onready var _timer_fill: ColorRect = $Hud/TimerFill
@onready var _danger_fill: ColorRect = $Hud/DangerFill
@onready var _hit_flash: ColorRect = $Hud/HitFlash

var _score: int = 0
var _dodged_count: int = 0
var _spawn_timer: float = 0.0
var _elapsed_time: float = 0.0
var _is_finished: bool = false
var _hit_flash_timer: float = 0.0
var _bullets: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func get_game_type() -> String:
	return "dodge_bullets"

func start_game() -> void:
	_rng.randomize()
	_score = 0
	_dodged_count = 0
	_spawn_timer = 0.0
	_elapsed_time = 0.0
	_is_finished = false
	_hit_flash_timer = 0.0
	_clear_bullets()
	_player.position = PLAY_AREA_SIZE * 0.5
	_player_visual.size = PLAYER_SIZE
	_player_visual.position = -PLAYER_SIZE * 0.5
	_update_hud()
	set_process_input(true)

func _process(delta: float) -> void:
	if _is_finished:
		return

	_timer -= delta
	if _timer <= 0.0:
		var final_score: int = clampi(SUCCESS_BASE_SCORE + _dodged_count * SCORE_PER_DODGED_BULLET, 0, 100)
		end_game(true, final_score, SUCCESS_KEYWORDS.duplicate())
		return

	update_game(delta)

func update_game(delta: float) -> void:
	_elapsed_time += delta
	_update_player(delta)
	_update_spawn(delta)
	_update_bullets(delta)
	_check_player_hit()
	_update_flash(delta)
	_update_hud()

func end_game(success: bool, score: int = 0, keywords: Array = []) -> void:
	if _is_finished:
		return
	_is_finished = true
	set_process_input(false)
	super.end_game(success, score, keywords)

func _update_player(delta: float) -> void:
	var target_position: Vector2 = _clamp_to_play_area(get_local_mouse_position())
	_player.position = _player.position.move_toward(target_position, player_speed * delta)

func _update_spawn(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	_spawn_bullet()
	_spawn_timer = _get_spawn_interval()

func _spawn_bullet() -> void:
	var side: int = _rng.randi_range(0, 3)
	var position: Vector2 = Vector2.ZERO

	if side == 0:
		position = Vector2(_rng.randf_range(0.0, PLAY_AREA_SIZE.x), -SPAWN_PADDING)
	elif side == 1:
		position = Vector2(PLAY_AREA_SIZE.x + SPAWN_PADDING, _rng.randf_range(0.0, PLAY_AREA_SIZE.y))
	elif side == 2:
		position = Vector2(_rng.randf_range(0.0, PLAY_AREA_SIZE.x), PLAY_AREA_SIZE.y + SPAWN_PADDING)
	else:
		position = Vector2(-SPAWN_PADDING, _rng.randf_range(0.0, PLAY_AREA_SIZE.y))

	var target: Vector2 = Vector2(
		_rng.randf_range(PLAY_AREA_SIZE.x * 0.25, PLAY_AREA_SIZE.x * 0.75),
		_rng.randf_range(PLAY_AREA_SIZE.y * 0.22, PLAY_AREA_SIZE.y * 0.82)
	)
	var direction: Vector2 = position.direction_to(target)
	var speed: float = _rng.randf_range(BULLET_SPEED_MIN, BULLET_SPEED_MAX)

	var bullet_node: ColorRect = ColorRect.new()
	bullet_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bullet_node.size = BULLET_SIZE
	bullet_node.position = position - BULLET_SIZE * 0.5
	bullet_node.color = BULLET_COLORS[_rng.randi_range(0, BULLET_COLORS.size() - 1)]
	_bullet_container.add_child(bullet_node)

	_bullets.append({
		"node": bullet_node,
		"position": position,
		"velocity": direction * speed
	})

func _update_bullets(delta: float) -> void:
	for index in range(_bullets.size() - 1, -1, -1):
		var bullet: Dictionary = _bullets[index]
		var bullet_node: ColorRect = bullet["node"]
		var position: Vector2 = bullet["position"]
		var velocity: Vector2 = bullet["velocity"]

		position += velocity * delta
		bullet["position"] = position
		_bullets[index] = bullet

		if is_instance_valid(bullet_node):
			bullet_node.position = position - BULLET_SIZE * 0.5

		if _is_bullet_outside(position):
			if is_instance_valid(bullet_node):
				bullet_node.queue_free()
			_bullets.remove_at(index)
			_dodged_count += 1
			_score = clampi(_score + SCORE_PER_DODGED_BULLET, 0, 100)

func _check_player_hit() -> void:
	for bullet in _bullets:
		var position: Vector2 = bullet["position"]
		if position.distance_to(_player.position) <= PLAYER_RADIUS + BULLET_RADIUS:
			_hit_flash_timer = 0.25
			end_game(false, clampi(_score, 0, 100), [])
			return

func _update_hud() -> void:
	var time_ratio: float = clampf(maxf(_timer, 0.0) / duration, 0.0, 1.0)
	var danger_ratio: float = clampf(1.0 - _get_spawn_interval() / BASE_SPAWN_INTERVAL, 0.0, 1.0)

	_timer_fill.size = Vector2(TIMER_BAR_SIZE.x * time_ratio, TIMER_BAR_SIZE.y)
	_danger_fill.size = Vector2(DANGER_BAR_SIZE.x * danger_ratio, DANGER_BAR_SIZE.y)

func _update_flash(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)

	var alpha: float = 0.0
	if _hit_flash_timer > 0.0:
		alpha = (_hit_flash_timer / 0.25) * 0.3
	_hit_flash.color = Color(1.0, 0.08, 0.06, alpha)

func _clear_bullets() -> void:
	_bullets.clear()
	for child in _bullet_container.get_children():
		child.queue_free()

func _get_spawn_interval() -> float:
	var progress: float = clampf(_elapsed_time / duration, 0.0, 1.0)
	return lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, progress)

func _is_bullet_outside(position: Vector2) -> bool:
	return (
		position.x < -SPAWN_PADDING
		or position.x > PLAY_AREA_SIZE.x + SPAWN_PADDING
		or position.y < -SPAWN_PADDING
		or position.y > PLAY_AREA_SIZE.y + SPAWN_PADDING
	)

func _clamp_to_play_area(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, PLAYER_RADIUS, PLAY_AREA_SIZE.x - PLAYER_RADIUS),
		clampf(point.y, PLAYER_RADIUS, PLAY_AREA_SIZE.y - PLAYER_RADIUS)
	)