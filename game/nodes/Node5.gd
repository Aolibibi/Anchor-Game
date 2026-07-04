# game/nodes/Node5.gd - 节点⑤：决战恶龙（躲避弹幕+实时回帖）
extends NodeBase
class_name Node5

const BATTLE_TIME: float = 45.0

@onready var title_label: Label = $TitleLabel
@onready var timer_label: Label = $TimerLabel
@onready var hp_label: Label = $HpLabel
@onready var hint_label: Label = $HintLabel
@onready var player: Area2D = $Player
@onready var bullet_container: Node2D = $BulletContainer
@onready var player_sprite: ColorRect = $Player/ColorRect

var _hp: int = 100
var _time_left: float = BATTLE_TIME
var _is_active: bool = false
var _spawn_timer: float = 0.0
var _move_speed: float = 400.0

func _ready() -> void:
	node_id = 5
	super._ready()
	player.area_entered.connect(_on_player_hit)

func enter_node() -> void:
	title_label.text = "节点⑤ 决战恶龙"
	hint_label.text = "鼠标移动躲避弹幕，存活45秒！"
	_is_active = true
	_time_left = BATTLE_TIME
	_hp = 100
	_update_hp()

func _process(delta: float) -> void:
	if not _is_active:
		return
	_time_left -= delta
	timer_label.text = "时间: " + str(int(max(0, _time_left))) + "s"
	if _time_left <= 0:
		_battle_end(true)
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	mouse_pos.x = clamp(mouse_pos.x, 50, 1140)
	mouse_pos.y = clamp(mouse_pos.y, 200, 950)
	player.global_position = player.global_position.lerp(mouse_pos, 0.4)
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_bullet()
		_spawn_timer = randf_range(0.3, 0.8)

func _spawn_bullet() -> void:
	var bullet = Area2D.new()
	var rect = ColorRect.new()
	rect.color = Color(1, 0.3, 0.3)
	rect.size = Vector2(20, 20)
	rect.position = Vector2(-10, -10)
	bullet.add_child(rect)
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(20, 20)
	shape.shape = rect_shape
	bullet.add_child(shape)
	var side: int = randi() % 4
	match side:
		0:
			bullet.position = Vector2(randf_range(50, 1140), 150)
			bullet.set_meta("vel", Vector2(0, 250))
		1:
			bullet.position = Vector2(randf_range(50, 1140), 950)
			bullet.set_meta("vel", Vector2(0, -250))
		2:
			bullet.position = Vector2(50, randf_range(200, 950))
			bullet.set_meta("vel", Vector2(250, 0))
		3:
			bullet.position = Vector2(1140, randf_range(200, 950))
			bullet.set_meta("vel", Vector2(-250, 0))
	bullet_container.add_child(bullet)

func _physics_process(_delta: float) -> void:
	for bullet in bullet_container.get_children():
		var vel: Vector2 = bullet.get_meta("vel", Vector2.ZERO)
		bullet.position += vel * _delta
		if bullet.position.x < -50 or bullet.position.x > 1240 or bullet.position.y < 100 or bullet.position.y > 1000:
			bullet.queue_free()

func _on_player_hit(_area: Area2D) -> void:
	if not _is_active:
		return
	_hp -= 10
	_update_hp()
	player_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	player_sprite.modulate = Color(0.3, 0.8, 0.3)
	if _hp <= 0:
		_battle_end(false)

func _update_hp() -> void:
	hp_label.text = "HP: " + str(_hp)

func _battle_end(survived: bool) -> void:
	_is_active = false
	if survived and _hp > 30:
		hint_label.text = "胜利！勇者击败恶龙！"
		ResourceManager.add_ren_qi(20)
		complete_node("胜利")
	elif survived:
		hint_label.text = "惨胜...勇者重伤"
		ResourceManager.add_qi_ren(10)
		complete_node("惨胜")
	else:
		hint_label.text = "勇者倒下了..."
		ResourceManager.add_qi_ren(20)
		complete_node("失败")
