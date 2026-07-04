# forum/ForumUI.gd - 论坛主界面UI控制（NGA风格，时序推进）
extends Control

const POST_SCENE = preload("res://forum/PostItem.tscn")

# 时序状态
const ST_LZ_ASK: int = 0          # 楼主发帖询问
const ST_HERO_REPLY: int = 1      # 勇者回复（玩家选择）
const ST_USERS_FOLLOW: int = 2    # 坛友跟帖+出选项
const ST_LZ_MERGE: int = 3        # 楼主汇总选项，分配D100范围
const ST_DICE_ROLL: int = 4       # 骰娘roll点
const ST_EXECUTE: int = 5         # 执行（右侧）+坛友反应
const ST_CHECK_EVENTS: int = 6    # 判定事件

@onready var title_label: Label = $HeaderContainer/TitleLabel
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var posts_container: VBoxContainer = $ScrollContainer/PostsContainer
@onready var action_panel: Panel = $ActionPanel
@onready var options_container: VBoxContainer = $ActionPanel/OptionsContainer
@onready var waiting_label: Label = $ActionPanel/WaitingLabel

var _post_count: int = 0
var _current_state: int = ST_LZ_ASK
var _current_scene_id: String = ""
var _is_busy: bool = false
var _hero_choice: Dictionary = {}        # 勇者选择的回复
var _user_choices: Array = []            # 坛友提出的选项
var _roll_pool: Array = []               # 楼主汇总的roll池（含范围）
var _loop_counter: int = 0               # 普通循环计数

func _ready() -> void:
	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.forum_event_triggered.connect(_on_forum_event_triggered)
	EventBus.qi_ren_changed.connect(_on_qi_ren_changed)
	EventBus.ren_qi_changed.connect(_on_ren_qi_changed)
	waiting_label.text = ""
	_init_forum()

func _init_forum() -> void:
	title_label.text = "【安科】异世界勇者的一周目冒险"
	_add_post("楼主", "开帖！主角登场，一个穿越到异世界的无名勇者。这次冒险怎么走，全看大家安价。", "author", false)
	await get_tree().create_timer(2.0).timeout
	_add_post("骰子娘", "D100=87 力量属性：很高！这勇者力量爆表。", "dice", false)
	await get_tree().create_timer(2.0).timeout
	_add_post("匿名A", "这么强？开局就满力量？", "user", false)
	await get_tree().create_timer(2.5).timeout
	_add_post("骰子娘", "D100=3 敏捷属性：惨不忍睹，超级笨拙。", "dice", false)
	await get_tree().create_timer(2.0).timeout
	_add_post("匿名B", "笑死，力量满敏捷负，像个乌龟。", "user", false)
	await get_tree().create_timer(2.5).timeout
	_start_new_loop("random_0")

func _start_new_loop(scene_id: String) -> void:
	_current_scene_id = scene_id
	_current_state = ST_LZ_ASK
	_hero_choice = {}
	_user_choices = []
	_roll_pool = []
	_run_state_machine()

func _run_state_machine() -> void:
	while _current_state <= ST_CHECK_EVENTS:
		if _is_busy:
			return
		_is_busy = true
		match _current_state:
			ST_LZ_ASK:
				await _do_lz_ask()
				_current_state = ST_HERO_REPLY
			ST_HERO_REPLY:
				_do_hero_reply()
				return  # 等玩家选
			ST_USERS_FOLLOW:
				await _do_users_follow()
				_current_state = ST_LZ_MERGE
			ST_LZ_MERGE:
				await _do_lz_merge()
				_current_state = ST_DICE_ROLL
			ST_DICE_ROLL:
				await _do_dice_roll()
				_current_state = ST_EXECUTE
			ST_EXECUTE:
				await _do_execute()
				_current_state = ST_CHECK_EVENTS
			ST_CHECK_EVENTS:
				await _do_check_events()
				break
		_is_busy = false
	_finish_loop()

func _finish_loop() -> void:
	_is_busy = false
	await get_tree().create_timer(1.5).timeout
	_loop_counter += 1
	var next_scene: String = _get_next_scene()
	_start_new_loop(next_scene)

# ========== 状态实现 ==========

func _do_lz_ask() -> void:
	var text: String = _get_lz_ask_text(_current_scene_id)
	_add_post("楼主", text, "author", false)
	await get_tree().create_timer(1.5).timeout

func _do_hero_reply() -> void:
	waiting_label.text = ""
	_render_hero_choices()

func _do_users_follow() -> void:
	var hero_text: String = _hero_choice.get("hero_reply", "（勇者潜水了）")
	var follows: Array = _get_user_follows(_current_scene_id, _hero_choice)
	for follow in follows:
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
		_add_post(follow["author"], follow["text"], "user", false)
		if follow.has("option"):
			_user_choices.append(follow["option"])

func _do_lz_merge() -> void:
	_roll_pool = _build_roll_pool(_hero_choice, _user_choices)
	_assign_ranges()
	await get_tree().create_timer(1.0).timeout
	var merge_text: String = "汇总一下大家的安价："
	for i in range(_roll_pool.size()):
		var opt = _roll_pool[i]
		merge_text += "\n" + str(i + 1) + ". " + opt["text"] + "  [D100: " + str(opt["range_min"]) + "-" + str(opt["range_max"]) + "]"
	_add_post("楼主", merge_text, "author", true)
	await get_tree().create_timer(1.5).timeout
	_add_post("楼主", "那么，开始roll点！", "author", false)

func _do_dice_roll() -> void:
	await get_tree().create_timer(1.0).timeout
	_add_post("骰子娘", "投骰中... D100", "dice", false)
	await get_tree().create_timer(1.5).timeout
	var roll: int = randi_range(1, 100)
	var selected: Dictionary = _pick_by_roll(roll)
	var outcome: String = _get_roll_outcome(roll)
	_add_post("骰子娘", "D100=" + str(roll) + " → " + selected.get("text", "???") + " (" + outcome + ")", "dice", true)
	await get_tree().create_timer(1.0).timeout
	_apply_roll_outcome(roll, outcome, selected)
	EventBus.dice_result.emit(roll, selected)

func _do_execute() -> void:
	await get_tree().create_timer(1.5).timeout
	var taunts: Array = _get_post_dice_taunts()
	for taunt in taunts:
		await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
		_add_post(taunt["author"], taunt["text"], "user", false)

func _do_check_events() -> void:
	await get_tree().create_timer(1.0).timeout
	_check_forum_events()

# ========== 玩家选择 ==========

func _render_hero_choices() -> void:
	_clear_options()
	var section = Label.new()
	section.text = "── 你的回复（选一个）──"
	section.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	section.add_theme_font_size_override("font_size", 12)
	options_container.add_child(section)
	var preset: Array = _get_hero_preset_choices(_current_scene_id)
	for i in range(preset.size()):
		var opt = preset[i]
		var btn = Button.new()
		btn.text = "选项" + str(i + 1) + ": " + opt.get("text", "???")
		btn.custom_minimum_size = Vector2(690, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_button_style(btn, "normal")
		_apply_option_color(btn, opt.get("type", "serious"))
		btn.pressed.connect(_on_hero_choice_pressed.bind(opt))
		options_container.add_child(btn)
	var scold_btn = Button.new()
	scold_btn.text = "破防骂楼主"
	scold_btn.custom_minimum_size = Vector2(690, 34)
	scold_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_style(scold_btn, "normal")
	scold_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	scold_btn.pressed.connect(_on_scold_pressed)
	options_container.add_child(scold_btn)
	var suggest_btn = Button.new()
	suggest_btn.text = "提出建议"
	suggest_btn.custom_minimum_size = Vector2(690, 34)
	suggest_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_style(suggest_btn, "normal")
	suggest_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.7))
	suggest_btn.pressed.connect(_on_suggest_pressed)
	options_container.add_child(suggest_btn)
	var dive_btn = Button.new()
	dive_btn.text = "潜水"
	dive_btn.custom_minimum_size = Vector2(690, 34)
	dive_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_style(dive_btn, "normal")
	dive_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	dive_btn.pressed.connect(_on_dive_pressed)
	options_container.add_child(dive_btn)

func _apply_button_style(btn: Button, state: String) -> void:
	var style = StyleBoxFlat.new()
	if state == "normal":
		style.bg_color = Color(1, 1, 1, 1)
		style.border_color = Color(0.85, 0.85, 0.85)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	else:
		style.bg_color = Color(1, 0.97, 0.88)
		style.border_color = Color(0.96, 0.6, 0.14)
		style.border_width_left = 3
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_top = 6
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)

func _on_hero_choice_pressed(opt: Dictionary) -> void:
	if _current_state != ST_HERO_REPLY:
		return
	_hero_choice = opt
	_hero_choice["hero_reply"] = "我选这个：" + opt.get("text", "???")
	_add_post("勇者", _hero_choice["hero_reply"], "hero", false)
	_proceed_after_hero()

func _on_scold_pressed() -> void:
	if _current_state != ST_HERO_REPLY:
		return
	ResourceManager.add_qi_ren(15)
	_hero_choice = {"id": "scold", "text": "骂楼主", "type": "special", "weight": 0.0, "hero_reply": "楼主你出来！我保证不打你！"}
	_add_post("勇者", _hero_choice["hero_reply"], "hero", false)
	await get_tree().create_timer(1.5).timeout
	_add_post("楼主", "......我反思一下", "author", false)
	if randf() < 0.3:
		await get_tree().create_timer(1.0).timeout
		_add_post("楼主", "好吧，给大家一个有利选项", "author", true)
		_user_choices.append({"id": "bonus", "text": "楼主送的特殊选项", "type": "special", "weight": 1.5})
	_proceed_after_hero()

func _on_suggest_pressed() -> void:
	if _current_state != ST_HERO_REPLY:
		return
	var suggestions: Array[String] = ["不如试试和敌人拜把子", "我觉得应该给敌人讲冷笑话", "我建议当场跳个舞", "不如假装投降", "我提议用食物诱惑", "不如数到三一起跑"]
	var picked: String = suggestions[randi() % suggestions.size()]
	_hero_choice = {"id": "suggest", "text": picked, "type": "special", "weight": 1.0, "hero_reply": "我提个建议：" + picked}
	_add_post("勇者", _hero_choice["hero_reply"], "hero", false)
	await get_tree().create_timer(1.5).timeout
	if randf() < 0.3:
		_add_post("楼主", "这个建议不错，加入选项池", "author", true)
		_user_choices.append({"id": "hero_suggest", "text": picked, "type": "special", "weight": 1.2})
	else:
		_add_post("匿名C", "这建议什么鬼", "user", false)
	_proceed_after_hero()

func _on_dive_pressed() -> void:
	if _current_state != ST_HERO_REPLY:
		return
	_hero_choice = {"id": "dive", "text": "潜水", "type": "special", "weight": 0.0, "hero_reply": "（勇者潜水了，暂不回复）"}
	_add_post("勇者", _hero_choice["hero_reply"], "hero", false)
	_proceed_after_hero()

func _proceed_after_hero() -> void:
	_clear_options()
	waiting_label.text = "坛友跟帖中..."
	_current_state = ST_USERS_FOLLOW
	_is_busy = false
	_run_state_machine()

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _apply_option_color(btn: Button, type: String) -> void:
	match type:
		"chaotic":
			btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.2))
		"special":
			btn.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8))
		_:
			btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))

# ========== 数据 ==========

func _get_lz_ask_text(scene_id: String) -> String:
	if scene_id.begins_with("node_"):
		var n: int = scene_id.substr(5).to_int()
		match n:
			1: return "勇者来到村庄广场，得先挑装备。大家觉得该选什么？"
			2: return "勇者进入森林，迷雾笼罩看不清路。怎么办？"
			3: return "勇者遇到一条河，没桥。岸边有小鸡、树、石头。怎么办？"
			4: return "勇者到了城堡大门，有密码锁。怎么开？"
			5: return "决战时刻！恶龙就在眼前。怎么办？"
	return "勇者继续冒险，遇到新情况。大家觉得该怎么办？"

func _get_hero_preset_choices(scene_id: String) -> Array:
	return [
		{"id": "fight", "text": "直接开打", "type": "serious", "weight": 1.0},
		{"id": "charm", "text": "魅惑对方", "type": "serious", "weight": 1.0},
		{"id": "kill", "text": "千年杀！", "type": "chaotic", "weight": 0.8}
	]

func _get_user_follows(scene_id: String, hero_choice: Dictionary) -> Array:
	var follows: Array = []
	var pool: Array = [
		{"author": "匿名A", "text": "我也觉得该这么干", "option": {"id": "agree1", "text": "支持勇者方案", "type": "serious", "weight": 1.0}},
		{"author": "匿名B", "text": "不对吧，我觉得应该绕过去", "option": {"id": "avoid", "text": "绕道而行", "type": "serious", "weight": 1.0}},
		{"author": "匿名C", "text": "千年杀啊！这必须千年杀！", "option": {"id": "kill2", "text": "千年杀", "type": "chaotic", "weight": 0.9}},
		{"author": "匿名D", "text": "不如试试跳舞", "option": {"id": "dance", "text": "跳个舞吧", "type": "chaotic", "weight": 0.7}},
		{"author": "匿名E", "text": "我支持勇者", "option": {"id": "agree2", "text": "支持勇者方案", "type": "serious", "weight": 1.0}},
		{"author": "匿名F", "text": "这剧情太搞了，加个色诱吧", "option": {"id": "charm2", "text": "色诱", "type": "chaotic", "weight": 0.8}},
		{"author": "匿名G", "text": "我赌大失败", "option": null},
		{"author": "匿名H", "text": "勇者加油！", "option": null}
	]
	pool.shuffle()
	var count: int = randi_range(2, 3)
	for i in range(min(count, pool.size())):
		follows.append(pool[i])
	return follows

func _build_roll_pool(hero_choice: Dictionary, user_choices: Array) -> Array:
	var pool: Array = []
	if hero_choice.has("text") and hero_choice.get("weight", 0.0) > 0.0:
		pool.append(hero_choice.duplicate())
	for uc in user_choices:
		if uc.get("weight", 0.0) > 0.0:
			var exists: bool = false
			for p in pool:
				if p["text"] == uc["text"]:
					exists = true
					break
			if not exists:
				pool.append(uc.duplicate())
	while pool.size() < 3:
		var fallback: Array = [
			{"id": "fight", "text": "直接开打", "type": "serious", "weight": 1.0},
			{"id": "avoid", "text": "绕道而行", "type": "serious", "weight": 1.0},
			{"id": "dance", "text": "跳个舞吧", "type": "chaotic", "weight": 0.7}
		]
		var fb = fallback[pool.size() % fallback.size()]
		var exists: bool = false
		for p in pool:
			if p["text"] == fb["text"]:
				exists = true
				break
		if not exists:
			pool.append(fb.duplicate())
		else:
			break
	# 按气人/人气调整权重
	var qi_level: int = ResourceManager.get_qi_ren_level()
	var ren_level: int = ResourceManager.get_ren_qi_level()
	for p in pool:
		var w: float = p.get("weight", 1.0)
		if p.get("type") == "chaotic":
			w *= (1.0 + qi_level * 0.2)
		else:
			w *= (1.0 + ren_level * 0.2)
		p["weight"] = w
	return pool

func _assign_ranges() -> void:
	var total: float = 0.0
	for p in _roll_pool:
		total += p.get("weight", 1.0)
	var current: int = 1
	for p in _roll_pool:
		var w: float = p.get("weight", 1.0)
		var span: int = max(1, int(round(w / total * 100)))
		p["range_min"] = current
		p["range_max"] = current + span - 1
		if p["range_max"] > 100:
			p["range_max"] = 100
		current = p["range_max"] + 1
	if _roll_pool.size() > 0:
		_roll_pool[_roll_pool.size() - 1]["range_max"] = 100

func _pick_by_roll(roll: int) -> Dictionary:
	for p in _roll_pool:
		if roll >= p.get("range_min", 1) and roll <= p.get("range_max", 100):
			return p
	return _roll_pool[0] if _roll_pool.size() > 0 else {"text": "默认"}

func _get_roll_outcome(roll: int) -> String:
	if roll >= 90:
		return "大成功"
	elif roll >= 70:
		return "成功"
	elif roll >= 30:
		return "普通"
	elif roll >= 10:
		return "失败"
	else:
		return "大失败"

func _apply_roll_outcome(roll: int, outcome: String, selected: Dictionary) -> void:
	_add_post("楼主", "结果：" + outcome + "！勇者执行了【" + selected.get("text", "???") + "】", "author", false)
	match outcome:
		"大成功":
			ResourceManager.add_ren_qi(15)
		"大失败":
			ResourceManager.add_qi_ren(15)
		"成功":
			ResourceManager.add_ren_qi(5)
		"失败":
			ResourceManager.add_qi_ren(10)

func _get_post_dice_taunts() -> Array:
	var pool: Array = [
		{"author": "匿名K", "text": "哈哈哈哈这结果"},
		{"author": "匿名L", "text": "楼主你故意的吧"},
		{"author": "匿名M", "text": "勇者太惨了"},
		{"author": "匿名N", "text": "笑死，这操作"},
		{"author": "匿名O", "text": "不愧是安科"},
		{"author": "匿名P", "text": "我猜到会这样"},
		{"author": "匿名Q", "text": "这剧情走向离谱"}
	]
	pool.shuffle()
	return pool.slice(0, randi_range(2, 3))

func _get_next_scene() -> String:
	if _current_scene_id.begins_with("node_"):
		var n: int = _current_scene_id.substr(5).to_int()
		if n >= 5:
			return "ending_normal"
		_loop_counter = 0
		GameManager.current_node_index = n + 1
		return "random_" + str(randi() % 3)
	if _current_scene_id.begins_with("ending_"):
		return _current_scene_id
	if _loop_counter >= randi_range(2, 3):
		_loop_counter = 0
		GameManager.current_node_index += 1
		if GameManager.current_node_index > 5:
			return "ending_normal"
		return "node_" + str(GameManager.current_node_index)
	return "random_" + str(randi() % 3)

# ========== 论坛事件 ==========

func _check_forum_events() -> void:
	var qi: int = ResourceManager.qi_ren
	var ren: int = ResourceManager.ren_qi
	if qi >= 70 and randf() < 0.8:
		_trigger_event("admin_warning")
	elif qi >= 50 and randf() < 0.5:
		_trigger_event("flame_war")
	elif ren >= 70 and randf() < 0.4:
		_trigger_event("gift")
	elif ren >= 50 and randf() < 0.3:
		_trigger_event("add_more")

func _trigger_event(event_id: String) -> void:
	EventBus.forum_event_triggered.emit(event_id)
	match event_id:
		"flame_war":
			_add_post("匿名D", "楼主写得什么垃圾，我上我也行！", "user", false)
			await get_tree().create_timer(1.5).timeout
			_add_post("匿名E", "你行你上啊，别光说不练", "user", false)
		"add_more":
			_add_post("楼主", "感谢大家支持，我加更一段！", "author", true)
		"admin_warning":
			_add_post("管理员", "请文明发言，否则封号处理。", "admin", true)
		"gift":
			_add_post("匿名F", "送楼主一个礼物，加油！", "user", false)

# ========== 信号回调 ==========

func _on_scene_entered(scene_id: String) -> void:
	if scene_id.begins_with("ending_"):
		_add_post("系统", "帖子状态变更：" + scene_id, "system", true)
		GameManager.game_ended = true
		GameManager.ending_type = scene_id.substr(8)

func _on_forum_event_triggered(_event_id: String) -> void:
	pass

func _on_qi_ren_changed(_value: int, _delta: int) -> void:
	pass

func _on_ren_qi_changed(_value: int, _delta: int) -> void:
	pass

# ========== 工具 ==========

func _add_post(author: String, text: String, role: String, highlighted: bool) -> void:
	_post_count += 1
	var post_item = POST_SCENE.instantiate()
	posts_container.add_child(post_item)
	post_item.setup(_post_count, author, text, role, highlighted)
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
