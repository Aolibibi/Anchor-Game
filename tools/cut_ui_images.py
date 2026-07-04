#!/usr/bin/env python3
"""
切图脚本 - 从即梦生成的5张UI图中提取游戏所需组件

输入: D:/Godot/安科项目临时图片/ 下的5张png
输出: D:/Godot/AnkakeProject/assets/forum_ui/ 和 D:/Godot/AnkakeProject/assets/game_scenes/
"""
import os
from PIL import Image

SRC_DIR = "D:/Godot/安科项目临时图片"
OUT_DIR = "D:/Godot/AnkakeProject/assets"
FORUM_UI_DIR = os.path.join(OUT_DIR, "forum_ui")
GAME_SCENES_DIR = os.path.join(OUT_DIR, "game_scenes")

def ensure_dirs():
    os.makedirs(FORUM_UI_DIR, exist_ok=True)
    os.makedirs(GAME_SCENES_DIR, exist_ok=True)

def load(name):
    path = os.path.join(SRC_DIR, name)
    return Image.open(path)

def crop(img, box, out_name, out_dir=FORUM_UI_DIR):
    """box = (left, top, right, bottom)"""
    c = img.crop(box)
    c.save(os.path.join(out_dir, out_name))
    print(f"  [切] {out_name} -> {box} -> {c.size}")
    return c

def main():
    ensure_dirs()
    
    # ===== 图1: 左侧论坛面板整体 =====
    print("\n=== 图1: 左侧论坛面板整体 ===")
    img1 = load("左侧论坛面板整体.png")
    w1, h1 = img1.size
    print(f"  尺寸: {w1}x{h1}")
    
    # 整个面板（含圆角）
    # 找面板边界 - 白色背景中的灰色面板
    # 约从 x=20~430, y=20~650
    # 手动估计：面板大约占图片的左侧60%
    # 圆角卡片从约 (20,20) 到 (430,650)
    # 实际上图片显示的是一个圆角白色面板
    # 让我用大致比例估计
    
    # 论坛面板整体背景（圆角白色卡片，可做9-slice）
    # 看图片，面板约从 x=0到 x=480, y=0到 y=660
    panel_left = int(w1 * 0.0)
    panel_right = int(w1 * 0.86)  # 约到右侧留一点空白
    panel_top = int(h1 * 0.0)
    panel_bottom = int(h1 * 0.93)  # 约到底部留一点
    
    # 但为了九宫格拉伸，需要包含圆角但不含内容
    # 只切面板框架，保留上下左右圆角
    # 从图中看，面板是白色圆角，顶部是深灰标签，中间是楼层，底部是输入框
    # 最好的做法是：切出整个面板，但后面代码用代码渲染内容
    
    # 方案：不切论坛面板背景（因为内容会覆盖），而是切组件
    
    # 顶部标签"安科论坛" - 深灰色圆角
    # 约 y=25 到 y=80
    header_box = (int(w1*0.08), int(h1*0.04), int(w1*0.82), int(h1*0.12))
    crop(img1, header_box, "forum_header.png")
    
    # 1楼正常楼层（不含头像）- 取内容区域
    # 约 y=90 到 y=170
    post1_box = (int(w1*0.15), int(h1*0.14), int(w1*0.92), int(h1*0.24))
    crop(img1, post1_box, "post_normal.png")
    
    # 2楼高亮楼层（骰子娘）- 浅黄底+橙色左边框
    # 约 y=170 到 y=250
    post2_box = (int(w1*0.15), int(h1*0.24), int(w1*0.92), int(h1*0.36))
    crop(img1, post2_box, "post_highlighted.png")
    
    # 头像方块（红/绿/蓝）
    # 红色头像
    avatar_red = (int(w1*0.08), int(h1*0.15), int(w1*0.18), int(h1*0.23))
    crop(img1, avatar_red, "avatar_author.png")
    
    # 绿色头像
    avatar_green = (int(w1*0.08), int(h1*0.25), int(w1*0.18), int(h1*0.35))
    crop(img1, avatar_green, "avatar_dice.png")
    
    # 蓝色头像
    avatar_blue = (int(w1*0.08), int(h1*0.40), int(w1*0.18), int(h1*0.48))
    crop(img1, avatar_blue, "avatar_user.png")
    
    # 底部输入区域
    # 约 y=580 到 y=640
    input_box = (int(w1*0.08), int(h1*0.82), int(w1*0.92), int(h1*0.92))
    crop(img1, input_box, "input_area.png")
    
    # ===== 图2: 顶部+底部（更干净的版本） =====
    print("\n=== 图2: 顶部+底部 ===")
    img2 = load("论坛面板顶部 + 输入框底部（单独切图用）.png")
    w2, h2 = img2.size
    print(f"  尺寸: {w2}x{h2}")
    
    # 更干净的顶部标签
    header2 = (int(w2*0.05), int(h2*0.05), int(w2*0.95), int(h2*0.35))
    crop(img2, header2, "forum_header_v2.png")
    
    # 更干净的底部输入区域
    input2 = (int(w2*0.05), int(h2*0.55), int(w2*0.95), int(h2*0.95))
    crop(img2, input2, "input_area_v2.png")
    
    # ===== 图3: 选项按钮 =====
    print("\n=== 图3: 选项按钮 ===")
    img3 = load("玩家回复选项按钮（底部交互区）.png")
    w3, h3 = img3.size
    print(f"  尺寸: {w3}x{h3}")
    
    # 正常按钮 - 白色圆角
    # 按钮1 约 y=60 到 y=110
    btn_normal = (int(w3*0.15), int(h3*0.14), int(w3*0.85), int(h3*0.26))
    crop(img3, btn_normal, "button_normal.png")
    
    # 选中按钮 - 浅黄+橙色边框
    # 按钮2（选中态）约 y=110 到 y=160
    btn_selected = (int(w3*0.15), int(h3*0.26), int(w3*0.85), int(h3*0.38))
    crop(img3, btn_selected, "button_selected.png")
    
    # 红色文字按钮（破防骂楼主）
    btn_red = (int(w3*0.15), int(h3*0.50), int(w3*0.85), int(h3*0.62))
    crop(img3, btn_red, "button_red_text.png")
    
    # 紫色文字按钮（提出建议）
    btn_purple = (int(w3*0.15), int(h3*0.62), int(w3*0.85), int(h3*0.74))
    crop(img3, btn_purple, "button_purple_text.png")
    
    # ===== 图4: 右侧游戏画面+顶部状态栏 =====
    print("\n=== 图4: 右侧游戏画面+顶部状态栏 ===")
    img4 = load("右侧游戏画面 + 顶部状态栏.png")
    w4, h4 = img4.size
    print(f"  尺寸: {w4}x{h4}")
    
    # 顶部状态栏
    topbar = (0, 0, w4, int(h4*0.15))
    crop(img4, topbar, "topbar.png", GAME_SCENES_DIR)
    
    # 右侧游戏场景（不含左侧论坛占位区）
    # 右侧从约 x=w*0.35 到 x=w
    scene_right = (int(w4*0.35), int(h4*0.18), w4, int(h4*0.85))
    crop(img4, scene_right, "game_scene_bg.png", GAME_SCENES_DIR)
    
    # 左侧论坛占位区（浅灰白色圆角面板）
    # 约 x=0.05 到 x=0.35, y=0.18 到 y=0.85
    forum_bg = (int(w4*0.03), int(h4*0.18), int(w4*0.37), int(h4*0.88))
    crop(img4, forum_bg, "forum_panel_bg.png", FORUM_UI_DIR)
    
    # ===== 图5: 完整版（最丰富的资源） =====
    print("\n=== 图5: 完整版 ===")
    img5 = load("完整游戏界面（一张图搞定版，切图麻烦但能看到整体效果）.png")
    w5, h5 = img5.size
    print(f"  尺寸: {w5}x{h5}")
    
    # 顶部状态栏（更完整的版本，有红色/金色填充条）
    topbar5 = (0, 0, w5, int(h5*0.12))
    crop(img5, topbar5, "topbar_v2.png", GAME_SCENES_DIR)
    
    # 左侧论坛面板（像素风）
    forum5 = (int(w5*0.02), int(h5*0.14), int(w5*0.38), int(h5*0.88))
    crop(img5, forum5, "forum_panel_pixel.png", FORUM_UI_DIR)
    
    # 右侧游戏场景（像素风勇者vs龙）
    game5 = (int(w5*0.40), int(h5*0.14), int(w5*0.98), int(h5*0.88))
    crop(img5, game5, "game_scene_pixel.png", GAME_SCENES_DIR)
    
    # 勇者像素角色（单独切出来做占位）
    # 约 x=0.42-0.52, y=0.30-0.80
    hero5 = (int(w5*0.42), int(h5*0.30), int(w5*0.55), int(h5*0.80))
    crop(img5, hero5, "hero_sprite.png", GAME_SCENES_DIR)
    
    # 龙像素角色
    # 约 x=0.60-0.95, y=0.25-0.85
    dragon5 = (int(w5*0.58), int(h5*0.25), int(w5*0.95), int(h5*0.85))
    crop(img5, dragon5, "dragon_sprite.png", GAME_SCENES_DIR)
    
    # 像素风楼层（#1 正常态）
    # 约 y=0.20-0.30
    post_pixel1 = (int(w5*0.05), int(h5*0.18), int(w5*0.36), int(h5*0.32))
    crop(img5, post_pixel1, "post_pixel_normal.png", FORUM_UI_DIR)
    
    # 像素风楼层（#2 高亮态）
    # 约 y=0.30-0.45
    post_pixel2 = (int(w5*0.05), int(h5*0.30), int(w5*0.36), int(h5*0.45))
    crop(img5, post_pixel2, "post_pixel_highlighted.png", FORUM_UI_DIR)
    
    # 像素风头像（红/绿/蓝）
    avatar_pixel_red = (int(w5*0.05), int(h5*0.18), int(w5*0.12), int(h5*0.26))
    crop(img5, avatar_pixel_red, "avatar_pixel_author.png", FORUM_UI_DIR)
    
    avatar_pixel_green = (int(w5*0.05), int(h5*0.30), int(w5*0.12), int(h5*0.38))
    crop(img5, avatar_pixel_green, "avatar_pixel_dice.png", FORUM_UI_DIR)
    
    avatar_pixel_blue = (int(w5*0.05), int(h5*0.58), int(w5*0.12), int(h5*0.66))
    crop(img5, avatar_pixel_green, "avatar_pixel_user.png", FORUM_UI_DIR)
    
    # 底部输入区域（像素风）
    input_pixel = (int(w5*0.04), int(h5*0.78), int(w5*0.37), int(h5*0.88))
    crop(img5, input_pixel, "input_area_pixel.png", FORUM_UI_DIR)
    
    print("\n=== 切图完成！===")
    print(f"  论坛UI资源: {FORUM_UI_DIR}")
    print(f"  游戏场景资源: {GAME_SCENES_DIR}")
    
    # 列出所有输出文件
    print(f"\n  forum_ui 文件:")
    for f in sorted(os.listdir(FORUM_UI_DIR)):
        print(f"    - {f}")
    print(f"\n  game_scenes 文件:")
    for f in sorted(os.listdir(GAME_SCENES_DIR)):
        print(f"    - {f}")

if __name__ == "__main__":
    main()
