# forum/PostItem.gd - 单个论坛楼层项
extends PanelContainer

@onready var header_label: RichTextLabel = $MarginContainer/VBoxContainer/HeaderLabel
@onready var content_label: RichTextLabel = $MarginContainer/VBoxContainer/ContentLabel

const ROLE_COLORS: Dictionary = {
	"author": "[color=#a04040]",
	"dice": "[color=#2a8a2a]",
	"user": "[color=#3060a0]",
	"admin": "[color=#c00000]",
	"hero": "[color=#8a4ac0]",
	"system": "[color=#666666]",
	"deleted": "[color=#999999]"
}

const ROLE_NAMES: Dictionary = {
	"author": "楼主",
	"dice": "骰子娘",
	"user": "",
	"admin": "管理员",
	"hero": "勇者",
	"system": "系统",
	"deleted": "已删除"
}

func setup(floor_num: int, author: String, text: String, role: String, highlighted: bool) -> void:
	if not is_node_ready():
		await ready
	var color_tag: String = ROLE_COLORS.get(role, "[color=#3060a0]")
	var display_name: String = author
	if role == "user":
		display_name = author
	var header_text: String = str(floor_num) + "F  " + color_tag + "[b]" + display_name + "[/b][/color]"
	if highlighted:
		header_text += "  [color=#ff8800]★[/color]"
	header_label.text = header_text
	content_label.text = color_tag + text + "[/color]"
	if highlighted:
		add_theme_stylebox_override("panel", _get_highlighted_style())
	else:
		add_theme_stylebox_override("panel", _get_normal_style())

func _get_normal_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.border_width_left = 3
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.8, 0.8, 0.8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style

func _get_highlighted_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.95, 0.85, 0.95)
	style.border_width_left = 3
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.7, 0.2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style
