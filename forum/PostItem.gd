# forum/PostItem.gd - 单个论坛楼层项（NGA风格）
extends HBoxContainer

@onready var avatar: TextureRect = $Avatar
@onready var floor_label: Label = $ContentVBox/VBox/FloorBar/FloorLabel
@onready var name_label: RichTextLabel = $ContentVBox/VBox/FloorBar/NameLabel
@onready var time_label: Label = $ContentVBox/VBox/FloorBar/TimeLabel
@onready var content_label: RichTextLabel = $ContentVBox/VBox/ContentLabel
@onready var bg_panel: Panel = $ContentVBox

const AVATAR_TEXTURES: Dictionary = {
	"author": preload("res://assets/forum_ui/avatar_author.png"),
	"dice": preload("res://assets/forum_ui/avatar_dice.png"),
	"user": preload("res://assets/forum_ui/avatar_user.png"),
	"hero": preload("res://assets/forum_ui/avatar_author.png"),
	"admin": preload("res://assets/forum_ui/avatar_author.png"),
	"system": preload("res://assets/forum_ui/avatar_user.png"),
	"deleted": preload("res://assets/forum_ui/avatar_user.png"),
}

const ROLE_COLORS: Dictionary = {
	"author": Color(0.7, 0.25, 0.25),
	"dice": Color(0.2, 0.6, 0.2),
	"user": Color(0.2, 0.4, 0.7),
	"admin": Color(0.75, 0.1, 0.1),
	"hero": Color(0.55, 0.3, 0.75),
	"system": Color(0.4, 0.4, 0.4),
	"deleted": Color(0.6, 0.6, 0.6)
}

const NAME_BB_COLORS: Dictionary = {
	"author": "[color=#b04040]",
	"dice": "[color=#2a8a2a]",
	"user": "[color=#3060a0]",
	"admin": "[color=#c00000]",
	"hero": "[color=#8a4ac0]",
	"system": "[color=#666666]",
	"deleted": "[color=#999999]"
}

const TITLE_BY_ROLE: Dictionary = {
	"author": "楼主",
	"dice": "骰子娘",
	"admin": "管理员",
	"hero": "勇者",
	"system": "系统",
	"deleted": "已删除"
}

func setup(floor_num: int, author: String, text: String, role: String, highlighted: bool) -> void:
	if not is_node_ready():
		await ready
	var tex = AVATAR_TEXTURES.get(role, null)
	if tex:
		avatar.texture = tex
	else:
		avatar.texture = null
	floor_label.text = str(floor_num) + "楼"
	var display_name: String = author
	if role == "user":
		display_name = author
	var title_str: String = TITLE_BY_ROLE.get(role, "")
	var name_bb: String = NAME_BB_COLORS.get(role, "[color=#3060a0]")
	if title_str != "":
		name_label.text = name_bb + "[b]" + display_name + "[/b][/color]  [color=#888888]" + title_str + "[/color]"
	else:
		name_label.text = name_bb + "[b]" + display_name + "[/b][/color]"
	time_label.text = _fake_time()
	content_label.text = name_bb + text + "[/color]"
	if highlighted:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 0.97, 0.88)
		style.border_width_left = 3
		style.border_color = Color(0.96, 0.6, 0.14)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		bg_panel.add_theme_stylebox_override("panel", style)
	else:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 1)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.9, 0.9, 0.9)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		bg_panel.add_theme_stylebox_override("panel", style)

func _fake_time() -> String:
	var h: int = randi_range(10, 23)
	var m: int = randi_range(0, 59)
	return "%02d:%02d" % [h, m]
