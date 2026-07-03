# forum/OptionPool.gd - 本轮选项池管理（仅本轮有效，不跨轮保留）
extends Control

var _preset_options: Array = []    # 该事件的预设选项
var _roll_pool: Array = []         # 楼主roll池（3条网友提出+玩家提的第4条）
var _your_pool: Array = []         # 你的选项池（没被选入的，仅本轮）

# TODO: 实现选项流程
# a. 从 res://data/options.json 读取该事件的预设选项
# b. 按气人/人气权重选3条加入roll池
# c. 没选入的加入你的选项池
# d. 玩家可从你的选项池提1条作第4条
# e. 骰娘按权重roll出1条
