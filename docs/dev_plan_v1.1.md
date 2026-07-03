# 《安科勇者》分工与开发计划 v1.1

> **基于 game_design_v0.9.md · 48小时Game Jam · 4美术+1作曲+AI代码**

---

## 0. 小游戏选型（3个）

| 小游戏 | 操作 | 时长 | 选型理由 |
|--------|------|------|---------|
| **躲避弹幕** | 鼠标移动 | 15-20秒 | 经典Undertale式，招牌 |
| **画线连符文** | 鼠标画线 | 15-20秒 | 解谜感强，可节点复用 |
| **拉霸** | 鼠标点击停止 | 10-15秒 | 契合安科骰子主题 |

---

## 1. 美术资产清单（精简版）

### 1.1 美术分工调整

| 角色 | 人数 | 职责 | 方式 |
|------|------|------|------|
| 左侧论坛UI | 用户自己 | UI框架/楼层样式/资源条/按钮/头像 | AI生成 |
| 右侧场景美术 | 4人 | 5个场景的背景图+元素内容 | 手绘/原创 |

**关键**：4个美术风格各不相同，正好契合右侧场景化美术的设计——每个场景风味不同。

### 1.2 左侧论坛UI（用户AI生成）

| 资产 | 数量 | 备注 |
|------|------|------|
| 论坛框架背景 | 1 | 白底复古论坛 |
| 楼层容器样式 | 1套4状态 | 正常/高亮/删除/违规 |
| 用户头像 | 8-10 | 楼主/骰子娘/管理员/匿名 |
| 骰子图标+动画 | 1套 | sprite sheet |
| 资源条UI | 2 | 气人(红)/人气(金) |
| 按钮样式 | 5种 | 投骰/回复/骂楼主/提话题/确认 |
| 选项框样式 | 3种 | 正经/离谱/骚选项 |
| 字体 | 2 | 等宽+衬线 |

### 1.3 右侧场景美术（4人，5场景）

| 场景 | 负责美术 | 风格 | 资产 |
|------|---------|------|------|
| 村庄（节点①） | 美术A | A的风格 | 背景+勇者+NPC+道具 |
| 森林（节点②） | 美术B | B的风格 | 背景+勇者+迷雾+符文 |
| 河流（节点③） | 美术C | C的风格 | 背景+勇者+小鸡+河流 |
| 城堡（节点④） | 美术D | D的风格 | 背景+勇者+大门+卡牌 |
| 决战（节点⑤） | 美术A或D | 对应风格 | 背景+勇者+恶龙+特效 |

**每个场景资产明细**（精简）：
- 场景背景 1张
- 勇者角色（待机+移动，2-4帧或单图）
- 主要事件要素精灵 1-2个
- 可交互元素图标 2-3个

### 1.4 小游戏美术（共用模板+各自素材）

| 小游戏 | 资产 | 数量 |
|--------|------|------|
| 躲避弹幕 | 勇者+弹幕图案5种+背景 | 7 |
| 画线连符文 | 符文6色+连线特效+背景 | 8 |
| 拉霸 | 拉霸机UI+滚轮图案8种+特效 | 10 |

### 1.5 论坛事件视觉特效

| 特效 | 实现 |
|------|------|
| 马赛克遮挡 | 着色器 |
| 飘屏弹幕 | UI粒子 |
| 和谐滤镜 | 全屏色调 |
| 画面撕裂 | 着色器 |
| 红色噪点 | 后处理 |

### 1.6 美术资产总量预估（精简后）

| 类别 | 预估工时 | 负责人 |
|------|---------|--------|
| 左侧论坛UI | 4-6小时（AI生成） | 用户自己 |
| 5个场景美术 | 16-24小时（4人并行，每人4-6h） | 4个美术 |
| 3个小游戏美术 | 8-12小时 | 美术兼任或用户AI辅助 |
| 论坛事件特效 | 4-6小时 | 用户AI或程序实现 |
| **总计** | **32-48小时** | **4人+用户并行** |

---

## 2. 音效需求（精简版）

### 2.1 BGM（1个旋律，2首编曲）

| 编曲 | 用途 | 风格 | 时长 |
|------|------|------|------|
| 编曲A（轻快版） | 普通循环+村庄+森林 | 轻松诙谐 | 1-2分钟循环 |
| 编曲B（紧张版） | 城堡+决战+节点 | 紧张激烈 | 1-2分钟循环 |

**作曲同学**：基于1个核心旋律，做2个编曲版本（变奏/配器不同）

### 2.2 音效（优先免费素材库）

| 类别 | 数量 | 来源 |
|------|------|------|
| 论坛音效（打字/提示/骰子/按钮） | 6个 | freesound.org |
| 小游戏音效（3个游戏各3-4个） | 10个 | freesound.org |
| 论坛事件音效（骂战/警告/吞楼等） | 6个 | freesound.org |
| **总计** | **22个** | **素材库** |

---

## 3. 模块化设计（针对AI代码合并优化）

### 3.1 目录结构

```
AnkakeProject/
├── core/                      # 核心系统（单例，全局唯一）
│   ├── GameManager.gd         # autoload单例
│   ├── EventBus.gd            # autoload单例，信号中心
│   ├── ResourceManager.gd     # autoload单例
│   ├── ChaosPool.gd           # autoload单例
│   └── GameLoop.gd            # 挂在主场景的节点
├── forum/                     # 论坛层（独立场景）
│   ├── ForumScene.tscn        # 论坛主场景
│   ├── ForumUI.gd
│   ├── PostRenderer.gd
│   ├── DiceAnimator.gd
│   ├── OptionPool.gd          # 本轮临时选项池
│   └── PlayerAction.gd
├── game/                      # 游戏层
│   ├── GameScene.tscn         # 游戏主场景
│   ├── SceneManager.gd        # 场景切换
│   ├── CharacterController.gd
│   └── nodes/                 # 5个节点（各自独立场景）
│       ├── Node1.tscn + .gd
│       ├── Node2.tscn + .gd
│       ├── Node3.tscn + .gd
│       ├── Node4.tscn + .gd
│       └── Node5.tscn + .gd
├── minigames/                 # 小游戏层（各自独立场景）
│   ├── MiniGameBase.gd        # 基类
│   ├── DodgeBullets.tscn + .gd
│   ├── DrawRunes.tscn + .gd
│   └── SlotMachine.tscn + .gd
├── events/                    # 论坛事件
│   └── EventManager.gd
├── data/                      # JSON配置（数据驱动）
│   ├── events.json
│   ├── options.json
│   ├── topics.json
│   ├── chaos_combos.json
│   └── dialogues.json
├── ui/                        # 通用UI组件
│   ├── ResourceBar.tscn + .gd
│   └── Toast.gd
└── assets/                    # 美术音频资源
    ├── forum_ui/              # 左侧论坛UI
    ├── scenes/                # 右侧场景美术
    │   ├── village/
    │   ├── forest/
    │   ├── river/
    │   ├── castle/
    │   └── final/
    ├── minigames/
    └── audio/
```

### 3.2 核心接口定义

#### EventBus（全局信号总线）
```gdscript
# core/EventBus.gd - autoload单例，所有模块通过信号通信
extends Node

# 循环流程信号
signal scene_entered(scene_id: String)
signal options_ready(roll_pool: Array)
signal player_action(action_type: String, data: Dictionary)
signal dice_rolling()
signal dice_result(roll_value: int, selected_option: Dictionary)
signal minigame_start(game_type: String)
signal minigame_result(success: bool, score: int, keywords: Array)
signal loop_step_completed(step: int)

# 资源信号
signal qi_ren_changed(value: int, delta: int)
signal ren_qi_changed(value: int, delta: int)

# 节点信号
signal node_entered(node_id: int)
signal node_completed(node_id: int, outcome: String)

# 论坛事件信号
signal forum_event_triggered(event_id: String)
signal forum_event_ended(event_id: String)

# 混沌池信号
signal keyword_added(keyword: String)
signal keyword_consumed(keyword: String)
signal combo_triggered(combo_id: String, result: Dictionary)
```

#### MiniGameBase（小游戏基类）
```gdscript
# minigames/MiniGameBase.gd
extends Node2D
class_name MiniGameBase

@export var duration: float = 15.0
var chaos_pool_ref: Array = []

func _ready() -> void:
    EventBus.minigame_start.emit(get_game_type())
    start_game()

func get_game_type() -> String:
    return "base"

func start_game() -> void:
    pass  # 子类实现

func end_game(success: bool, score: int = 0, keywords: Array = []) -> void:
    EventBus.minigame_result.emit(success, score, keywords)
    queue_free()
```

#### NodeBase（节点基类）
```gdscript
# game/nodes/NodeBase.gd
extends Node2D
class_name NodeBase

@export var node_id: int = 0
var preset_options: Array = []

func _ready() -> void:
    EventBus.node_entered.emit(node_id)
    enter_node()

func enter_node() -> void:
    pass  # 子类实现

func complete_node(outcome: String) -> void:
    EventBus.node_completed.emit(node_id, outcome)
```

### 3.3 瀑布式开发阶段

| 阶段 | 时长 | 任务 |
|------|------|------|
| ①基础框架 | 8-10h | core/全部 + EventBus + 基类 + 数据格式 + UI骨架 |
| ②核心系统 | 12-14h | GameLoop + 资源条 + 选项池 + 3个小游戏 + 论坛UI |
| ③内容实现 | 10-12h | 5个节点 + 论坛事件 + 话题池 + 搭配表 + 文案 |
| ④整合调试 | 8-10h | 合并 + 调参 + 修bug + 打包 |

---

## 4. AI代码生成前置Prompt

**将以下prompt提供给每个写代码的AI，确保代码规范统一，方便后期合并：**

```
你正在为一个Godot 4.7项目编写代码。这是一个多人协同的Game Jam项目，代码由多个AI并行生成后合并。你必须严格遵守以下规范，否则代码将无法与其他模块集成。

## 项目结构

项目采用模块化设计，目录结构如下（不要创建已有目录外的文件）：
- core/     核心单例（GameManager, EventBus, ResourceManager, ChaosPool）
- forum/    论坛层UI和逻辑
- game/     游戏层（场景管理、勇者控制、nodes/节点脚本）
- minigames/ 小游戏（继承MiniGameBase）
- events/   论坛事件
- data/     JSON配置文件
- ui/       通用UI组件
- assets/   美术音频资源

## 核心规范

### 1. 通信规范（最重要）
- 模块间通信**只用EventBus信号**，绝不直接调用其他模块的方法或访问其内部变量
- EventBus是autoload单例，全局可通过 `EventBus.信号名` 访问
- 发信号用 `EventBus.信号名.emit(参数)`，监听用 `EventBus.信号名.connect(回调)`
- 信号定义在 core/EventBus.gd，不要在其他地方定义跨模块信号

### 2. 单例规范
- 只有 core/ 下的文件可以注册为autoload单例
- 单例命名：GameManager, EventBus, ResourceManager, ChaosPool
- 其他模块不要使用全局状态，通过信号通信

### 3. 命名规范
- 文件名：PascalCase（如 ForumUI.gd, DodgeBullets.gd）
- 类名：与文件名一致，用 class_name 声明
- 函数名：snake_case（如 start_game, end_game）
- 变量名：snake_case（如 roll_value, chaos_pool）
- 常量：UPPER_SNAKE_CASE（如 MAX_POOL_SIZE）
- 信号名：snake_case（如 dice_result, minigame_result）
- 私有成员：下划线前缀（如 _internal_state）

### 4. 资源路径规范
- 所有资源引用用 `res://` 绝对路径
- 资源路径结构：res://assets/分类/文件名
- 不要用相对路径（如 `../xxx`），合并时会出错
- 动态加载用 `load("res://...")` 或 `ResourceLoader.load`

### 5. 场景组织规范
- 每个独立功能是一个场景文件（.tscn）
- 场景根节点用 class_name 声明类型
- 场景切换用 `get_tree().change_scene_to_file("res://...")` 或 `change_scene_to_packed()`
- 不要用 `get_tree().reload_current_scene()` 跨模块

### 6. 数据驱动规范
- 所有文本、选项、配置放 data/ 目录的JSON文件
- 不要硬编码任何文本或数值
- 读取JSON用标准方式：
  ```gdscript
  var file = FileAccess.open("res://data/xxx.json", FileAccess.READ)
  var data = JSON.parse_string(file.get_as_text())
  ```

### 7. 继承规范
- 小游戏必须继承 MiniGameBase（class_name MiniGameBase）
- 节点脚本必须继承 NodeBase（class_name NodeBase）
- 基类定义在各自目录，不要修改基类接口

### 8. 类型标注规范
- 函数参数和返回值必须标注类型
- 变量尽量用类型标注（var x: int = 0）
- 数组用 Array[类型] 标注（如 Array[String]）
- 用 @export 暴露需要编辑器配置的变量

### 9. 错误处理规范
- 资源加载失败要检查null
- 信号连接要检查是否成功
- 不要用 assert 做运行时检查，用 if 判断

### 10. 注释规范
- 每个文件顶部写一行注释说明用途
- 复杂逻辑写简短注释
- 不要写无意义的注释（如 `# 设置x为0`）

## 你负责的模块

[此处填入该AI负责的具体模块和任务]

## 接口约定

你负责的模块需要监听和发送以下信号：

[此处填入该模块需要用到的信号列表]

请严格按以上规范编写代码，确保与其他模块无缝合并。
```

### 4.1 使用方法

1. **每个AI任务前**，复制上面的前置prompt
2. **填入"你负责的模块"**：如"你负责 forum/OptionPool.gd，实现本轮选项池管理"
3. **填入"接口约定"**：如"监听 EventBus.scene_entered，发送 EventBus.options_ready"
4. **生成代码后**，检查是否符合规范（特别是信号通信、命名、资源路径）

### 4.2 模块任务分配示例

| AI任务 | 负责模块 | 监听信号 | 发送信号 |
|--------|---------|---------|---------|
| AI-1 | core/全部 | - | 所有信号定义 |
| AI-2 | forum/ForumUI | scene_entered, dice_result, forum_event_triggered | player_action |
| AI-3 | forum/OptionPool | scene_entered | options_ready |
| AI-4 | minigames/DodgeBullets | minigame_start | minigame_result |
| AI-5 | minigames/DrawRunes | minigame_start | minigame_result |
| AI-6 | minigames/SlotMachine | minigame_start | minigame_result |
| AI-7 | game/nodes/Node1 | node_entered | node_completed |
| ... | ... | ... | ... |

---

## 5. 人员分工（最终版）

| 角色 | 人数 | 职责 |
|------|------|------|
| 用户（策划+AI代码） | 1 | 策划文档+节点剧本+AI生成代码+整合 |
| 美术 | 4 | 右侧5个场景美术（每人1-2场景） |
| 作曲 | 1 | 1个旋律2首编曲 |
| 代码生成 | AI | 按模块生成，用户审核合并 |

### 5.1 美术分工建议

| 美术 | 负责场景 | 资产 |
|------|---------|------|
| 美术A | 村庄(节点①) + 决战(节点⑤) | 2场景 |
| 美术B | 森林(节点②) | 1场景 |
| 美术C | 河流(节点③) | 1场景 |
| 美术D | 城堡(节点④) | 1场景 |

### 5.2 代码生成顺序（AI）

| 顺序 | 模块 | 依赖 | 优先级 |
|------|------|------|--------|
| 1 | core/EventBus.gd | 无 | 最高（所有人依赖） |
| 2 | core/其他单例 + 基类 | EventBus | 高 |
| 3 | forum/全部 | core | 高 |
| 4 | minigames/3个 | MiniGameBase | 中 |
| 5 | game/nodes/5个 | NodeBase | 中 |
| 6 | events/ | core | 中 |
| 7 | data/配置文件 | 数据格式定义 | 低（可后填） |

---

## 6. 风险与应对

| 风险 | 应对 |
|------|------|
| AI代码合并冲突 | 严格遵循前置prompt规范，信号通信解耦 |
| 接口定义不清晰 | EventBus先完成，所有人基于已定义信号开发 |
| 美术风格不统一 | 右侧场景化本就要求风格不同，是特色不是bug |
| 5个节点做不完 | 优先①③⑤，②④简化 |
| 曲解演出工作量大 | 每选项1个通用曲解模板 |

---

## 7. 待确认

1. 4个美术各自擅长什么风格？（影响场景分配）
2. 用户是否熟悉Godot？（影响AI代码审核难度）
3. 是否使用Git版本管理？
4. Demo范围：48小时做完整10分钟，还是先做5-7分钟核心？

---

*v1.1 — 针对4美术+1作曲+AI代码的精简版, 含代码规范前置prompt*
