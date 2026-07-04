# forum/ForumUI.gd - 论坛主界面UI控制（仿NGA风格，时序驱动）
extends Control

const POST_SCENE = preload("res://forum/PostItem.tscn")

const STATE_LZ_ANJIA: int = 0        # 楼主发帖安价
const STATE_USERS_REPLY: int = 1     # 网友自然回复安价
const STATE_PLAYER_CHOICE: int = 2   # 玩家选项亮起，等待选择
const STATE_PLAYER_DONE: int = 3     # 玩家选择后，选项消失
const STATE_LZ_MERGE: int = 4        # 楼主合并选项，准备roll
const STATE_DICE_ROLL: int = 5       # 骰娘roll
const STATE_EXECUTE: int = 6         # 右侧执行，左侧滚动吐槽
const STATE_CHECK_EVENTS: int = 7    # 判定特殊事件

@onready var title_label: Label = $HeaderContainer/TitleLabel
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var posts_container: VBoxContainer = $ScrollContainer/PostsContainer
@onready var action_panel: Panel = $ActionPanel
@onready var options_container: VBoxContainer = $ActionPanel/OptionsContainer

var _current_roll_pool: Array = []
var _your_option_pool: Array = []
var _all_options: Array = []
var _post_count: int = 0
var _current_state: int = STATE_LZ_ANJIA
var _current_scene_id: String = ""
var _is_busy: bool = false

func _ready() -> void:
	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.forum_event_triggered.connect(_on_forum_event_triggered)
	EventBus.qi_ren_changed.connect(_on_qi_ren_changed)
	EventBus.ren_qi_changed.connect(_on_ren_qi_changed)
	_init_forum()

func _init_forum() -> void:
	title_label.text = "【安科】异世界勇者的一周目冒险"
	_add_post("楼主", "开帖！主角登场，一个穿越到异世界的无名勇者。", "author", false)
	_add_post("骰子娘", "D100=87 力量属性：很高！这勇者力量爆表。", "dice", false)
	_add_post("匿名A", "这么强？开局就满力量？", "user", false)
	_add_post("骰子娘", "D100=3 敏捷属性：惨不忍睹，超级笨拙。", "dice", false)
	_add_post("匿名B", "笑死，力量满敏捷负，像个乌龟。", "user", false)
	await get_tree().create_timer(2.0).timeout
	_start_new_loop("random_0")

func _start_new_loop(scene_id: String) -> void:
	_current_scene_id = scene_id
	_current_state = STATE_LZ_ANJIA
	_run_state_machine()

func _run_state_machine() -> void:
	while _current_state != STATE_CHECK_EVENTS + 1:
		if _is_busy:
			return
		_is_busy = true
		match _current_state:
			STATE_LZ_ANJIA:
				await _do_lz_anjia()
			STATE_USERS_REPLY:
				await _do_users_reply()
			STATE_PLAYER_CHOICE:
				await _do_player_choice()
				return  # 等待玩家选择，不自动推进
			STATE_PLAYER_DONE:
				await _do_player_done()
			STATE_LZ_MERGE:
				await _do_lz_merge()
			STATE_DICE_ROLL:
				await _do_dice_roll()
			STATE_EXECUTE:
				await _do_execute()
			STATE_CHECK_EVENTS:
				await _do_check_events()
				break
		_current_state += 1
		_is_busy = false
	# 循环结束，进入下一个场景
	_finish_loop()

func _finish_loop() -> void:
	_is_busy = false
	await get_tree().create_timer(1.5).timeout
	var next_scene: String = _get_next_scene()
	_start_new_loop(next_scene)

# ========== 状态实现 ==========

func _do_lz_anjia() -> void:
	var lz_text: String = _get_lz_anjia_text(_current_scene_id)
	_add_post("楼主", lz_text, "author", false)

func _do_users_reply() -> void:
	var replies: Array = _get_user_replies(_current_scene_id)
	for reply in replies:
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
		_add_post(reply["author"], reply["text"], "user", false)

func _do_player_choice() -> void:
	_all_options = _get_scene_options(_current_scene_id)
	var selected_3: Array = _select_options_by_weight(_all_options, 3)
	_current_roll_pool = selected_3.duplicate()
	_your_option_pool = []
	for opt in _all_options:
		if not (opt in selected_3):
			_your_option_pool.append(opt)
	_render_player_choices()

func _do_player_done() -> void:
	_clear_options()
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout

func _do_lz_merge() -> void:
	var merge_text: String = "好，汇总一下大家的安价选项："
	for i in range(_current_roll_pool.size()):
		merge_text += "\n" + str(i + 1) + ". " + _current_roll_pool[i].get("text", "???")
	_add_post("楼主", merge_text, "author", false)
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
	_add_post("楼主", "那么，开始roll点！", "author", true)

func _do_dice_roll() -> void:
	await get_tree().create_timer(1.0).timeout
	_add_post("骰子娘", "投骰中... D100", "dice", false)
	await get_tree().create_timer(1.5).timeout
	var roll: int = randi_range(1, 100)
	var selected: Dictionary = _weighted_select_from_pool(_current_roll_pool)
	_add_post("骰子娘", "D100=" + str(roll) + " → " + selected.get("text", "执行"), "dice", true)
	for kw in selected.get("keywords", []):
		ChaosPool.add_keyword(kw)
	var outcome: String = _get_roll_outcome(roll)
	await get_tree().create_timer(1.0).timeout
	_apply_roll_outcome(roll, outcome, selected)

func _do_execute() -> void:
	await get_tree().create_timer(1.5).timeout
	var taunts: Array = _get_post_dice_taunts()
	for taunt in taunts:
		await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
		_add_post(taunt["author"], taunt["text"], "user", false)

func _do_check_events() -> void:
	await get_tree().create_timer(1.0).timeout
	_check_forum_events()

func _finish_state_and_continue() -> void:
	_current_state += 1
	_is_busy = false
	_run_state_machine()

# ========== 玩家选择处理 ==========

func _render_player_choices() -> void:
	_clear_options()
	var section_label = Label.new()
	section_label.text = "── 安价选项（选1个加入楼主池）──"
	section_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	section_label.add_theme_font_size_override("font_size", 13)
	options_container.add_child(section_label)
	for i in range(_current_roll_pool.size()):
		var opt = _current_roll_pool[i]
		var btn = Button.new()
		btn.text = str(i + 1) + ". " + opt.get("text", "???")
		btn.custom_minimum_size = Vector2(680, 36)
		_apply_option_color(btn, opt.get("type", "serious"))
		btn.pressed.connect(_on_anjia_option_pressed.bind(i))
		options_container.add_child(btn)
	if _your_option_pool.size() > 0:
		var your_label = Label.new()
		your_label.text = "── 你的选项池（可选1条加入）──"
		your_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		your_label.add_theme_font_size_override("font_size", 13)
		options_container.add_child(your_label)
		for i in range(_your_option_pool.size()):
			var opt = _your_option_pool[i]
			var btn = Button.new()
			btn.text = "＋ " + opt.get("text", "???")
			btn.custom_minimum_size = Vector2(680, 32)
			btn.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))
			btn.pressed.connect(_on_your_option_pressed.bind(i))
			options_container.add_child(btn)
	var sep = HSeparator.new()
	options_container.add_child(sep)
	var action_label = Label.new()
	action_label.text = "── 或不做安价，改为：──"
	action_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	action_label.add_theme_font_size_override("font_size", 13)
	options_container.add_child(action_label)
	var scold_btn = Button.new()
	scold_btn.text = "骂楼主（气人+15，可能触发反思）"
	scold_btn.custom_minimum_size = Vector2(680, 32)
	scold_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	scold_btn.pressed.connect(_on_scold_pressed)
	options_container.add_child(scold_btn)
	var topic_btn = Button.new()
	topic_btn.text = "提话题（可能触发特殊节点）"
	topic_btn.custom_minimum_size = Vector2(680, 32)
	topic_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.7))
	topic_btn.pressed.connect(_on_topic_pressed)
	options_container.add_child(topic_btn)

func _on_anjia_option_pressed(idx: int) -> void:
	if _current_state != STATE_PLAYER_CHOICE:
		return
	if idx < _current_roll_pool.size():
		var opt = _current_roll_pool[idx]
		_add_post("勇者", "我选这个：" + opt.get("text", "???"), "hero", false)
		_proceed_to_merge()

func _on_your_option_pressed(idx: int) -> void:
	if _current_state != STATE_PLAYER_CHOICE:
		return
	if idx < _your_option_pool.size():
		var opt = _your_option_pool[idx]
		_current_roll_pool.append(opt)
		_your_option_pool.remove_at(idx)
		_add_post("勇者", "我觉得还可以试试：" + opt.get("text", "???"), "hero", false)
		_proceed_to_merge()

func _on_scold_pressed() -> void:
	if _current_state != STATE_PLAYER_CHOICE:
		return
	ResourceManager.add_qi_ren(15)
	_add_post("勇者", "楼主你出来！我保证不打你！", "hero", false)
	await get_tree().create_timer(1.0).timeout
	_add_post("楼主", "......我反思一下", "author", false)
	if randf() < 0.3:
		await get_tree().create_timer(1.0).timeout
		_add_post("楼主", "好吧，给大家一个有利选项", "author", true)
		_current_roll_pool.append({"id": "bonus", "text": "楼主送的特殊选项", "type": "special", "weight": 1.5, "keywords": ["福利"]})
	_proceed_to_merge()

func _on_topic_pressed() -> void:
	if _current_state != STATE_PLAYER_CHOICE:
		return
	_add_post("勇者", "我提个话题：勇者是不是太缺乏武器了？", "hero", false)
	await get_tree().create_timer(1.5).timeout
	var prob: float = 0.3 + ResourceManager.ren_qi * 0.005
	if randf() < prob:
		_add_post("匿名H", "对啊！楼主给勇者加把武器吧！", "user", false)
		await get_tree().create_timer(1.5).timeout
		_add_post("楼主", "好吧，进入装备选择剧情", "author", true)
		await get_tree().create_timer(1.0).timeout
		_clear_options()
		_is_busy = false
		_start_new_loop("node_1")
	else:
		_add_post("匿名H", "话题太冷清，没人理", "user", false)
		_proceed_to_merge()

func _proceed_to_merge() -> void:
	_clear_options()
	_current_state = STATE_PLAYER_DONE
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

# ========== 数据获取 ==========

func _get_lz_anjia_text(scene_id: String) -> String:
	if scene_id.begins_with("node_"):
		var node_num: int = scene_id.substr(5).to_int()
		match node_num:
			1: return "勇者来到村庄广场，需要挑选装备。大家觉得该选什么？"
			2: return "勇者进入森林，迷雾笼罩。需要连接符文指引方向。"
			3: return "勇者遇到一条河，没有桥。岸边有小鸡、树、石头。怎么办？"
			4: return "勇者到达城堡大门，有密码锁。需要用骰子卡牌拼出密码。"
			5: return "决战时刻！恶龙就在眼前。勇者必须一边躲避一边行动。"
	return "勇者继续冒险，遇到了新的情况。大家觉得该怎么办？"

func _get_user_replies(scene_id: String) -> Array:
	var replies: Array = []
	var pool: Array = [
		{"author": "匿名A", "text": "我觉得应该直接开打"},
		{"author": "匿名B", "text": "不如试试魅惑？"},
		{"author": "匿名C", "text": "绕过去不行吗"},
		{"author": "匿名D", "text": "千年杀啊！"},
		{"author": "匿名E", "text": "跳个舞给敌人看"},
		{"author": "匿名F", "text": "楼主你认真点写"},
		{"author": "匿名G", "text": "这剧情太搞了"},
		{"author": "匿名H", "text": "勇者加油！"},
		{"author": "匿名I", "text": "我赌大失败"},
		{"author": "匿名J", "text": "感觉要出事"}
	]
	pool.shuffle()
	var count: int = randi_range(2, 3)
	for i in range(min(count, pool.size())):
		replies.append(pool[i])
	return replies

func _get_scene_options(scene_id: String) -> Array:
	var file = FileAccess.open("res://data/options.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and data.has(scene_id):
			return data[scene_id]
	return [
		{"id": "fight", "text": "直接开打", "type": "serious", "weight": 1.0, "keywords": ["战斗"]},
		{"id": "charm", "text": "魅惑对方", "type": "serious", "weight": 1.0, "keywords": ["魅惑"]},
		{"id": "avoid", "text": "绕道而行", "type": "serious", "weight": 1.0, "keywords": ["回避"]},
		{"id": "kill", "text": "千年杀！", "type": "chaotic", "weight": 0.8, "keywords": ["千年杀"]},
		{"id": "dance", "text": "跳个舞吧", "type": "chaotic", "weight": 0.6, "keywords": ["舞蹈"]}
	]

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
		var node_num: int = _current_scene_id.substr(5).to_int()
		if node_num >= 5:
			return "ending_normal"
		return "random_" + str(randi() % 5)
	var loop_count: int = GameManager.current_node_index
	if _current_scene_id.begins_with("random_"):
		if not has_meta("loop_counter"):
			set_meta("loop_counter", 0)
		var counter: int = get_meta("loop_counter") + 1
		set_meta("loop_counter", counter)
		if counter >= randi_range(2, 3):
			set_meta("loop_counter", 0)
			GameManager.current_node_index += 1
			if GameManager.current_node_index > 5:
				return "ending_normal"
			return "node_" + str(GameManager.current_node_index)
	return "random_" + str(randi() % 5)

# ========== 权重与roll ==========

func _select_options_by_weight(options: Array, count: int) -> Array:
	var pool: Array = options.duplicate()
	var selected: Array = []
	var qi_level: int = ResourceManager.get_qi_ren_level()
	var ren_level: int = ResourceManager.get_ren_qi_level()
	for _i in range(min(count, pool.size())):
		var weights: Array = []
		for opt in pool:
			var w: float = opt.get("weight", 1.0)
			if opt.get("type") == "chaotic":
				w *= (1.0 + qi_level * 0.2)
			else:
				w *= (1.0 + ren_level * 0.2)
			weights.append(w)
		var idx: int = _weighted_random(weights)
		selected.append(pool[idx])
		pool.remove_at(idx)
	return selected

func _weighted_random(weights: Array) -> int:
	var total: float = 0.0
	for w in weights:
		total += w
	var r: float = randf() * total
	var cumulative: float = 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if r <= cumulative:
			return i
	return weights.size() - 1

func _weighted_select_from_pool(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {"id": "default", "text": "默认选项", "keywords": []}
	var weights: Array = []
	for opt in pool:
		weights.append(opt.get("weight", 1.0))
	var idx: int = _weighted_random(weights)
	return pool[idx]

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
			_add_post("匿名C", "牛逼！", "user", false)
		"大失败":
			ResourceManager.add_qi_ren(15)
			_add_post("匿名C", "笑死，这运气没谁了", "user", false)
		"成功":
			ResourceManager.add_ren_qi(5)
		"失败":
			ResourceManager.add_qi_ren(10)
	EventBus.dice_result.emit(roll, selected)

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
	elif randf() < 0.1:
		_trigger_event("deleted_post")

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
		"deleted_post":
			_add_post("系统", "[此楼已被删除]", "deleted", true)
		"gift":
			_add_post("匿名F", "送楼主一个礼物，加油！", "user", false)

func _on_forum_event_triggered(_event_id: String) -> void:
	pass

# ========== 信号回调 ==========

func _on_scene_entered(scene_id: String) -> void:
	if scene_id.begins_with("ending_"):
		_add_post("系统", "帖子状态变更：" + scene_id, "system", true)
		GameManager.game_ended = true
		GameManager.ending_type = scene_id.substr(8)

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
