# minigames/DodgeBullets.gd - 躲避弹幕小游戏（15-20秒）
extends MiniGameBase
class_name DodgeBullets

@export var spawn_interval: float = 0.4

@onready var player: Area2D = $Player
@onready var player_sprite: ColorRect = $Player/ColorRect
@onready var bullet_container: Node2D = $BulletContainer
@onready var score_label: Label = $ScoreLabel

var _score: int = 0
var _spawn_timer: float = 0.0
var _is_hit: bool = false

func get_game_type() -> String:
	return "dodge_bullets"

func start_game() -> void:
	duration = 18.0
	_timer = duration
	_score = 0
	_is_hit = false
	player.area_entered.connect(_on_player_hit)

func update_game(delta: float) -> void:
	if _is_hit:
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	mouse_pos.x = clamp(mouse_pos.x, 50, 1140)
	mouse_pos.y = clamp(mouse_pos.y, 200, 950)
	player.global_position = player.global_position.lerp(mouse_pos, 0.5)
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_bullet()
		_spawn_timer = spawn_interval
	_score += int(delta * 10)
	score_label.text = "得分: " + str(_score)

func _spawn_bullet() -> void:
	var bullet = Area2D.new()
	var rect = ColorRect.new()
	rect.color = Color(1, 0.4, 0.4)
	rect.size = Vector2(16, 16)
	rect.position = Vector2(-8, -8)
	bullet.add_child(rect)
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(16, 16)
	shape.shape = rect_shape
	bullet.add_child(shape)
	var side: int = randi() % 4
	match side:
		0:
			bullet.position = Vector2(randf_range(50, 1140), 150)
			bullet.set_meta("vel", Vector2(0, 300))
		1:
			bullet.position = Vector2(randf_range(50, 1140), 950)
			bullet.set_meta("vel", Vector2(0, -300))
		2:
			bullet.position = Vector2(50, randf_range(200, 950))
			bullet.set_meta("vel", Vector2(300, 0))
		3:
			bullet.position = Vector2(1140, randf_range(200, 950))
			bullet.set_meta("vel", Vector2(-300, 0))
	bullet_container.add_child(bullet)

	for b in bullet_container.get_children():
		var vel: Vector2 = b.get_meta("vel", Vector2.ZERO)
		b.position += vel * delta
		if b.position.x < -50 or b.position.x > 1240 or b.position.y < 100 or b.position.y > 1000:
			b.queue_free()

func _on_player_hit(_area: Area2D) -> void:
	_is_hit = true
	player_sprite.modulate = Color(1, 0.2, 0.2)
	var keywords: Array = []
	if _score >= 150:
		ResourceManager.add_ren_qi(15)
		keywords = ["闪避"]
	elif _score >= 80:
		ResourceManager.add_ren_qi(5)
	else:
		ResourceManager.add_qi_ren(10)
	end_game(_score >= 100, _score, keywords)
