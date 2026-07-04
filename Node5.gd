# game/nodes/Node5.gd - 节点⑤：决战恶龙（躲避弹幕）
extends NodeBase
class_name Node5

const BATTLE_TIME: float = 45.0
const PLAYER_HP_MAX: int = 100
const PLAYER_HIT_DAMAGE: int = 10
const PLAYER_SAFE_TIME: float = 0.35
const PLAYER_LERP_WEIGHT: float = 0.4
const BULLET_SIZE: Vector2 = Vector2(16, 16)
const BULLET_SPEED: float = 220.0
const AIMED_BULLET_SPEED: float = 180.0
const BULLET_SPAWN_MIN: float = 0.22
const BULLET_SPAWN_MAX: float = 0.45
const BULLET_WAVE_MIN: int = 2
const BULLET_WAVE_MAX: int = 4
const SUCCESS_REN_QI: int = 20

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var timer_label: Label = $TimerLabel
@onready var hp_label: Label = $HpLabel
@onready var hint_label: Label = $HintLabel
@onready var player: Area2D = $Player
@onready var player_sprite: ColorRect = $Player/PlayerSprite
@onready var bullet_container: Node2D = $BulletContainer

var _hp: int = PLAYER_HP_MAX
var _time_left: float = BATTLE_TIME
var _is_active: bool = false
var _is_invincible: bool = false
var _spawn_timer: float = 0.0

func _ready() -> void:
	node_id = 5
	super._ready()
	player.area_entered.connect(_on_player_hit)

func enter_node() -> void:
	title_label.text = "节点⑤ 决战恶龙"
	desc_label.text = "鼠标移动勇者躲避弹幕，存活45秒"
	hint_label.text = "不要碰到红色弹幕"
	_hp = PLAYER_HP_MAX
	_time_left = BATTLE_TIME
	_spawn_timer = 0.0
	_is_active = true
	_is_invincible = false
	_clear_bullets()
	_update_timer()
	_update_hp()

func _clear_bullets() -> void:
	for child in bullet_container.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	if not _is_active:
		return
	_time_left -= delta
	_update_timer()
	if _time_left <= 0:
		_complete_success()
		return
	_update_player_position()
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_bullet_wave()
		_spawn_timer = randf_range(BULLET_SPAWN_MIN, BULLET_SPAWN_MAX)

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	for bullet in bullet_container.get_children():
		var velocity: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
		bullet.position += velocity * delta
		if _is_bullet_outside(bullet.position):
			bullet.queue_free()

func _update_player_position() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	mouse_position.x = clamp(mouse_position.x, 70, 1120)
	mouse_position.y = clamp(mouse_position.y, 180, 930)
	player.global_position = player.global_position.lerp(mouse_position, PLAYER_LERP_WEIGHT)

func _spawn_bullet_wave() -> void:
	var pattern: int = randi() % 3
	var bullet_count: int = randi_range(BULLET_WAVE_MIN, BULLET_WAVE_MAX)
	for bullet_index in range(bullet_count):
		match pattern:
			0:
				_spawn_edge_bullet()
			1:
				_spawn_diagonal_bullet(bullet_index)
			2:
				_spawn_aimed_bullet()

func _spawn_edge_bullet() -> void:
	var side: int = randi() % 4
	match side:
		0:
			_create_bullet(Vector2(randf_range(80, 1110), 150), Vector2(randf_range(-80, 80), BULLET_SPEED))
		1:
			_create_bullet(Vector2(randf_range(80, 1110), 950), Vector2(randf_range(-80, 80), -BULLET_SPEED))
		2:
			_create_bullet(Vector2(50, randf_range(200, 920)), Vector2(BULLET_SPEED, randf_range(-80, 80)))
		3:
			_create_bullet(Vector2(1140, randf_range(200, 920)), Vector2(-BULLET_SPEED, randf_range(-80, 80)))

func _spawn_diagonal_bullet(bullet_index: int) -> void:
	var corner: int = (randi() + bullet_index) % 4
	var offset: float = randf_range(0, 180)
	match corner:
		0:
			_create_bullet(Vector2(60 + offset, 150), Vector2(BULLET_SPEED, BULLET_SPEED * 0.8))
		1:
			_create_bullet(Vector2(1130 - offset, 150), Vector2(-BULLET_SPEED, BULLET_SPEED * 0.8))
		2:
			_create_bullet(Vector2(60 + offset, 950), Vector2(BULLET_SPEED, -BULLET_SPEED * 0.8))
		3:
			_create_bullet(Vector2(1130 - offset, 950), Vector2(-BULLET_SPEED, -BULLET_SPEED * 0.8))

func _spawn_aimed_bullet() -> void:
	var spawn_position: Vector2 = _get_random_edge_position()
	var direction: Vector2 = (player.global_position - spawn_position).normalized()
	_create_bullet(spawn_position, direction * AIMED_BULLET_SPEED)

func _get_random_edge_position() -> Vector2:
	var side: int = randi() % 4
	match side:
		0:
			return Vector2(randf_range(80, 1110), 150)
		1:
			return Vector2(randf_range(80, 1110), 950)
		2:
			return Vector2(50, randf_range(200, 920))
		_:
			return Vector2(1140, randf_range(200, 920))

func _create_bullet(spawn_position: Vector2, velocity: Vector2) -> void:
	var bullet: Area2D = Area2D.new()
	var sprite: ColorRect = ColorRect.new()
	sprite.color = Color(1.0, 0.25, 0.25, 1.0)
	sprite.size = BULLET_SIZE
	sprite.position = -BULLET_SIZE * 0.5
	bullet.add_child(sprite)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = BULLET_SIZE
	collision.shape = shape
	bullet.add_child(collision)
	bullet.position = spawn_position
	bullet.set_meta("velocity", velocity)
	bullet_container.add_child(bullet)

func _is_bullet_outside(position: Vector2) -> bool:
	return position.x < -80 or position.x > 1270 or position.y < 100 or position.y > 1030

func _on_player_hit(area: Area2D) -> void:
	if not _is_active or _is_invincible:
		return
	if area:
		area.queue_free()
	_hp -= PLAYER_HIT_DAMAGE
	_hp = max(_hp, 0)
	_update_hp()
	_flash_player()
	if _hp <= 0:
		_complete_failure()

func _flash_player() -> void:
	_is_invincible = true
	player_sprite.modulate = Color(1.0, 0.35, 0.35, 1.0)
	await get_tree().create_timer(PLAYER_SAFE_TIME).timeout
	if not is_inside_tree():
		return
	player_sprite.modulate = Color(1, 1, 1, 1)
	_is_invincible = false

func _update_timer() -> void:
	timer_label.text = "时间: " + str(int(max(_time_left, 0))) + "s"

func _update_hp() -> void:
	hp_label.text = "HP: " + str(_hp)

func _complete_success() -> void:
	if not _is_active:
		return
	_is_active = false
	_clear_bullets()
	hint_label.text = "胜利！勇者击败恶龙！"
	ResourceManager.add_ren_qi(SUCCESS_REN_QI)
	complete_node("胜利")

func _complete_failure() -> void:
	if not _is_active:
		return
	_is_active = false
	_clear_bullets()
	hint_label.text = "勇者倒下了..."
	complete_node("失败")
