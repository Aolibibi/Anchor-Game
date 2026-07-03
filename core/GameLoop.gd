# core/GameLoop.gd - 七步循环状态机
extends Node

enum Step {
	ENTER_SCENE,       # ① 进入场景
	OPTIONS_POOL,      # ② 楼主出选项池
	PLAYER_ACTION,     # ③ 玩家行动
	DICE_ROLL,         # ④ 投骰决定
	EXECUTE,           # ⑤ 执行
	COMPLETE,          # ⑥ 完成结算
	CHECK_EVENTS       # ⑦ 判定特殊事件
}

var _current_step: int = Step.ENTER_SCENE
var _loop_count: int = 0  # 当前章节的循环次数

# TODO: 实现七步循环状态机
# 每2-3个普通循环后强制进入下一个固定节点
