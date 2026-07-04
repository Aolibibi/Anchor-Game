# 《安科勇者》项目协作手册 v1.2

> **本文档分四部分，各司其职，请对应角色只看自己的部分**
> - 第一部分：给程序看（含AI代码生成的强约束prompt）
> - 第二部分：给美术看（资产格式约束）
> - 第三部分：给AI代码合并看（合并检查清单）
> - 第四部分：给文案策划看（数据格式与待填内容）

---

# ═══════════════════════════════════════════
# 第一部分：给程序看
# ═══════════════════════════════════════════

## 1.1 项目背景

- 引擎：Godot 4.7
- 类型：安科主题游戏，左侧论坛UI + 右侧游戏画面
- 单局10分钟，纯鼠标操作
- 代码全部由AI生成，你负责审核、调整、合并
- **你不熟悉Godot/编程 → 所以规范必须极强，照搬模板**

## 1.2 Git仓库

```
仓库地址: https://github.com/Aolibibi/Anchor-Game.git
分支策略:
  - main: 主分支（稳定版本）
  - feature/xxx: 各功能分支
推送命令（在项目根目录执行）:
  git push -u origin main
```

## 1.3 目录结构（严格遵守，不创建其他目录）

```
AnkakeProject/
├── core/                      # 核心单例
│   ├── EventBus.gd            # 信号总线（最先做）
│   ├── GameManager.gd         # 游戏管理
│   ├── ResourceManager.gd     # 资源条
│   └── GameLoop.gd            # 七步循环
├── forum/                     # 论坛层
│   ├── ForumScene.tscn
│   ├── ForumUI.gd
│   ├── PostRenderer.gd
│   ├── DiceAnimator.gd
│   ├── OptionPool.gd
│   └── PlayerAction.gd
├── game/                      # 游戏层
│   ├── GameScene.tscn
│   ├── SceneManager.gd
│   ├── CharacterController.gd
│   └── nodes/                 # 5个节点
│       ├── NodeBase.gd
│       ├── Node1.tscn + Node1.gd
│       ├── Node2.tscn + Node2.gd
│       ├── Node3.tscn + Node3.gd
│       ├── Node4.tscn + Node4.gd
│       └── Node5.tscn + Node5.gd
├── minigames/                 # 3个小游戏
│   ├── MiniGameBase.gd
│   ├── DodgeBullets.tscn + DodgeBullets.gd
│   ├── DrawRunes.tscn + DrawRunes.gd
│   └── SlotMachine.tscn + SlotMachine.gd
├── events/                    # 论坛事件
│   └── EventManager.gd
├── data/                      # JSON配置
│   ├── events.json
│   ├── options.json
│   ├── topics.json
│   └── dialogues.json
├── ui/                        # 通用UI
│   ├── ResourceBar.tscn + ResourceBar.gd
│   └── Toast.gd
└── assets/                    # 美术音频资源
    ├── forum_ui/
    ├── scenes/
    │   ├── village/
    │   ├── forest/
    │   ├── river/
    │   ├── castle/
    │   └── final/
    ├── minigames/
    └── audio/
```

## 1.4 代码规范（强制，违反即拒绝合并）

### 命名规范
- 文件名：PascalCase（`ForumUI.gd`）
- 类名：与文件名一致，必须用 `class_name` 声明
- 函数名：snake_case（`start_game()`）
- 变量名：snake_case（`roll_value`）
- 常量：UPPER_SNAKE_CASE（`MAX_POOL_SIZE`）
- 信号名：snake_case（`dice_result`）
- 私有成员：下划线前缀（`_internal_state`）

### 通信规范（最重要）
- **模块间只用EventBus信号通信，绝不直接调用其他模块的方法或变量**
- 发信号：`EventBus.信号名.emit(参数)`
- 监听信号：`EventBus.信号名.connect(回调函数)`
- 信号只定义在 `core/EventBus.gd`

### 资源路径规范
- 所有资源用 `res://` 绝对路径
- **禁止用相对路径**（`../xxx`）
- 动态加载用 `load("res://...")`

### 数据驱动规范
- 所有文本、选项、配置放 `data/` 目录JSON
- **禁止硬编码任何文本或数值**
- 读取JSON示例：
```gdscript
var file = FileAccess.open("res://data/options.json", FileAccess.READ)
var data = JSON.parse_string(file.get_as_text())
```

### 类型标注规范
- 函数参数和返回值必须标注类型
- 变量尽量标注（`var x: int = 0`）
- 数组用 `Array[类型]`（`Array[String]`）

### 继承规范
- 小游戏必须继承 `MiniGameBase`
- 节点必须继承 `NodeBase`
- **不要修改基类接口**

### 禁止事项清单
- ❌ 禁止在非core目录使用全局变量或单例
- ❌ 禁止直接 `get_node("/root/其他模块")` 访问其他模块
- ❌ 禁止硬编码文本（如 `"打败龙"`），必须从JSON读取
- ❌ 禁止用相对路径加载资源
- ❌ 禁止修改 `core/EventBus.gd` 的信号签名（除非全员同意）
- ❌ 禁止用 `assert` 做运行时检查
- ❌ 禁止在 `_ready()` 外做初始化（除非必要）
- ❌ 禁止跨模块继承（小游戏不能继承节点）

## 1.5 完整代码模板（可直接复制）

### EventBus.gd（最先做，所有人依赖）
```gdscript
# core/EventBus.gd - 全局信号总线，所有模块通过信号通信
extends Node

# === 循环流程信号 ===
signal scene_entered(scene_id: String)
signal options_ready(roll_pool: Array)
signal player_action(action_type: String, data: Dictionary)
signal dice_rolling()
signal dice_result(roll_value: int, selected_option: Dictionary)
signal minigame_start(game_type: String)
signal minigame_result(success: bool, score: int, keywords: Array)
signal loop_step_completed(step: int)

# === 资源信号 ===
signal qi_ren_changed(value: int, delta: int)
signal ren_qi_changed(value: int, delta: int)

# === 节点信号 ===
signal node_entered(node_id: int)
signal node_completed(node_id: int, outcome: String)

# === 论坛事件信号 ===
signal forum_event_triggered(event_id: String)
signal forum_event_ended(event_id: String)
```

**注册为Autoload**：项目设置 → Autoload → 添加 `EventBus`，路径 `res://core/EventBus.gd`

### ResourceManager.gd
```gdscript
# core/ResourceManager.gd - 气人值/人气值管理
extends Node

var qi_ren: int = 0    # 气人值 0-100
var ren_qi: int = 0    # 人气值 0-100

func add_qi_ren(amount: int) -> void:
    qi_ren = clamp(qi_ren + amount, 0, 100)
    EventBus.qi_ren_changed.emit(qi_ren, amount)

func add_ren_qi(amount: int) -> void:
    ren_qi = clamp(ren_qi + amount, 0, 100)
    EventBus.ren_qi_changed.emit(ren_qi, amount)

func spend_ren_qi(amount: int) -> bool:
    if ren_qi >= amount:
        ren_qi -= amount
        EventBus.ren_qi_changed.emit(ren_qi, -amount)
        return true
    return false

# 返回0-3: 0低(0-29) 1中(30-49) 2高(50-69) 3满(70-100)
func get_qi_ren_level() -> int:
    if qi_ren >= 70: return 3
    elif qi_ren >= 50: return 2
    elif qi_ren >= 30: return 1
    else: return 0

func get_ren_qi_level() -> int:
    if ren_qi >= 70: return 3
    elif ren_qi >= 50: return 2
    elif ren_qi >= 30: return 1
    else: return 0
```

### MiniGameBase.gd
```gdscript
# minigames/MiniGameBase.gd - 小游戏基类，所有小游戏继承此类
extends Node2D
class_name MiniGameBase

@export var duration: float = 15.0
var chaos_pool_ref: Array = []
var _timer: float = 0.0

func _ready() -> void:
    EventBus.minigame_start.emit(get_game_type())
    _timer = duration
    start_game()

func _process(delta: float) -> void:
    _timer -= delta
    if _timer <= 0:
        end_game(false, 0, [])
    update_game(delta)

# 子类必须实现
func get_game_type() -> String:
    return "base"

func start_game() -> void:
    pass

func update_game(delta: float) -> void:
    pass

func end_game(success: bool, score: int = 0, keywords: Array = []) -> void:
    EventBus.minigame_result.emit(success, score, keywords)
    queue_free()
```

### 小游戏示例：DodgeBullets.gd
```gdscript
# minigames/DodgeBullets.gd - 躲避弹幕小游戏
extends MiniGameBase
class_name DodgeBullets

@export var player_speed: float = 300.0
@onready var player: Area2D = $Player
@onready var bullet_container: Node2D = $BulletContainer

var _score: int = 0

func get_game_type() -> String:
    return "dodge_bullets"

func start_game() -> void:
    # 加载弹幕图案（从混沌池）
    _spawn_bullets()

func update_game(delta: float) -> void:
    # 鼠标控制勇者移动
    var mouse_pos: Vector2 = get_global_mouse_position()
    player.global_position = player.global_position.lerp(mouse_pos, 0.3)

func _spawn_bullets() -> void:
    # TODO: 根据混沌池关键词生成弹幕
    pass

func _on_player_hit(area: Area2D) -> void:
    end_game(false, _score, [])
```

### NodeBase.gd
```gdscript
# game/nodes/NodeBase.gd - 节点基类
extends Node2D
class_name NodeBase

@export var node_id: int = 0
var preset_options: Array = []

func _ready() -> void:
    EventBus.node_entered.emit(node_id)
    _load_options()
    enter_node()

func _load_options() -> void:
    # 从JSON读取该节点的预设选项
    var file = FileAccess.open("res://data/options.json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        if data.has(str(node_id)):
            preset_options = data[str(node_id)]

func enter_node() -> void:
    pass  # 子类实现

func complete_node(outcome: String) -> void:
    EventBus.node_completed.emit(node_id, outcome)
```

## 1.6 AI代码生成前置Prompt

**每次让AI生成代码前，复制以下prompt粘贴给AI：**

```
你正在为Godot 4.7项目编写代码。这是多人协同Game Jam项目，代码由多个AI并行生成后合并。你必须严格遵守以下规范，否则代码无法合并。

## 项目结构
- core/ 核心单例（EventBus, GameManager, ResourceManager, ChaosPool）
- forum/ 论坛层UI和逻辑
- game/ 游戏层（含nodes/节点脚本）
- minigames/ 小游戏（继承MiniGameBase）
- events/ 论坛事件
- data/ JSON配置文件
- ui/ 通用UI组件
- assets/ 美术音频资源

## 强制规范
1. 通信：模块间只用EventBus信号，绝不直接调用其他模块。发信号用EventBus.信号名.emit()，监听用EventBus.信号名.connect()
2. 命名：文件PascalCase，函数变量snake_case，常量UPPER_SNAKE_CASE，信号snake_case
3. 资源路径：只用res://绝对路径，禁止相对路径
4. 数据驱动：所有文本配置放data/目录JSON，禁止硬编码
5. 继承：小游戏继承MiniGameBase，节点继承NodeBase，不修改基类
6. 类型标注：函数参数返回值必须标注，变量尽量标注
7. 禁止：全局变量、直接访问其他模块、硬编码文本、相对路径、assert运行时检查

## EventBus已定义信号
- scene_entered(scene_id: String)
- options_ready(roll_pool: Array)
- player_action(action_type: String, data: Dictionary)
- dice_rolling()
- dice_result(roll_value: int, selected_option: Dictionary)
- minigame_start(game_type: String)
- minigame_result(success: bool, score: int, keywords: Array)
- loop_step_completed(step: int)
- qi_ren_changed(value: int, delta: int)
- ren_qi_changed(value: int, delta: int)
- node_entered(node_id: int)
- node_completed(node_id: int, outcome: String)
- forum_event_triggered(event_id: String)
- forum_event_ended(event_id: String)
- keyword_added(keyword: String)
- keyword_consumed(keyword: String)
- combo_triggered(combo_id: String, result: Dictionary)

## 你负责的模块
[在此填入：如"forum/OptionPool.gd，实现本轮选项池管理"]

## 接口约定
[在此填入：如"监听scene_entered，发送options_ready"]

请严格按规范编写，输出完整可运行的代码。
```

## 1.7 代码生成顺序

| 顺序 | 模块 | 说明 |
|------|------|------|
| 1 | core/EventBus.gd | 最先，所有人依赖 |
| 2 | core/其他单例+基类 | ResourceManager, ChaosPool, MiniGameBase, NodeBase |
| 3 | forum/全部 | ForumUI, PostRenderer, OptionPool, PlayerAction, DiceAnimator |
| 4 | minigames/3个 | DodgeBullets, DrawRunes, SlotMachine |
| 5 | game/nodes/5个 | Node1-5 |
| 6 | events/ | EventManager |
| 7 | data/配置 | JSON文件（策划填内容） |

---

# ═══════════════════════════════════════════
# 第二部分：给美术看
# ═══════════════════════════════════════════

## 2.1 总体要求

- **格式**：PNG（带透明通道），UI可用JPG
- **色彩**：sRGB，8位
- **命名**：小写snake_case，如 `village_bg.png`, `hero_idle.png`
- **提交**：放对应 `assets/` 子目录

## 2.2 左侧论坛UI资产（用户AI生成，供参考）

| 资产 | 尺寸 | 格式 | 说明 |
|------|------|------|------|
| 论坛背景 | 730×1080 | PNG/JPG | 占屏幕左38%，白底复古论坛 |
| 楼层容器 | 可九宫格拉伸 | PNG | 9-slice，含正常/高亮/删除/违规4版 |
| 用户头像 | 64×64 | PNG透明 | 楼主/骰子娘/管理员/匿名A-Z |
| 骰子动画 | 128×128 sprite sheet | PNG透明 | 滚动6-8帧 |
| 资源条底 | 300×40 | PNG | 可拉伸 |
| 资源条填充 | 300×40 | PNG透明 | 气(红)/人(金) |
| 按钮 | 可九宫格 | PNG | 5种状态 |

## 2.3 右侧场景美术（重点）

### 通用规格

| 资产类型 | 尺寸 | 格式 | 说明 |
|---------|------|------|------|
| 场景背景 | 1190×1080 | PNG/JPG | 占屏幕右62%，画幅重心见下 |
| 勇者角色 | 200×300 | PNG透明 | 待机+移动2-4帧或单图 |
| 事件要素 | 300×300 | PNG透明 | 龙/河/鸡/门等主要交互物 |
| 可交互元素 | 64×64 | PNG透明 | 道具/NPC图标 |
| 特效 | 256×256 | PNG透明 | 帧动画sprite sheet |

### 画幅重心（重要）

右侧游戏画面尺寸 1190×1080，**画面重心在下方偏中**：

```
┌─────────────────────────┐
│                         │
│    背景层（天空/远景）    │  上1/3：背景氛围
│                         │
├─────────────────────────┤
│                         │
│    中景层（事件要素）     │  中1/3：主要交互区域
│    ★ 画幅重心点 ★        │  重心：(595, 650) 左右
│                         │
├─────────────────────────┤
│                         │
│    前景层（勇者站 位）    │  下1/3：勇者活动区
│                         │
└─────────────────────────┘
```

**关键**：
- 勇者始终站在下方1/3区域（y=720-900左右）
- 事件要素（龙/河/门）在中1/3偏上（y=400-650）
- 背景氛围在上1/3（y=0-350）
- **不要把重要内容放在画面边缘**，左右各留50px安全区

### 5个场景需求（风格由美术自定）

| 场景 | 节点 | 必需资产 | 备注 |
|------|------|---------|------|
| 村庄 | ① | 背景 + 勇者 + 村民NPC 2个 + 道具3个 | 教学关，明亮友好 |
| 森林 | ② | 背景 + 勇者 + 迷雾特效 + 符文6色 | 神秘感 |
| 河流 | ③ | 背景 + 勇者 + 小鸡 + 河流元素 | 招牌关，多元素交互 |
| 城堡 | ④ | 背景 + 勇者 + 大门 + 卡牌图案5种 | 紧张感 |
| 决战 | ⑤ | 背景 + 勇者 + 恶龙 + 特效 | 史诗感，多特效 |

### 勇者角色统一要求

- 尺寸：200×300 像素
- 朝向：面向右（默认）
- 待机动画：2-4帧轻微呼吸
- 移动动画：可选，无则用待机
- **5个场景的勇者风格可以不同**（契合场景化设计），但轮廓大小要一致

## 2.4 小游戏美术

### 通用小游戏模板
| 资产 | 尺寸 | 数量 |
|------|------|------|
| 倒计时UI | 100×40 | 1 |
| 成功/失败结算 | 400×300 | 2 |
| 操作提示 | 64×64 | 3 |

### 躲避弹幕
| 资产 | 尺寸 | 数量 |
|------|------|------|
| 勇者受控点 | 32×32 | 1 |
| 弹幕图案 | 32×32 | 5种（爱心/鸡/马赛克/箭头/星星） |
| 背景 | 1190×800 | 1 |

### 画线连符文
| 资产 | 尺寸 | 数量 |
|------|------|------|
| 符文图标 | 64×64 | 6色（红/橙/黄/绿/蓝/紫） |
| 连线特效 | 256×256 | 1（可拉伸） |
| 背景 | 1190×800 | 1 |

### 拉霸
| 资产 | 尺寸 | 数量 |
|------|------|------|
| 拉霸机框架 | 600×400 | 1 |
| 滚轮图案 | 80×80 | 8种 |
| 中奖特效 | 256×256 | 1 |

## 2.5 论坛事件视觉特效（程序实现，美术提供素材）

| 特效 | 素材需求 |
|------|---------|
| 马赛克遮挡 | 无需素材，着色器实现 |
| 飘屏弹幕 | 弹幕文字样式图（可选） |
| 和谐滤镜 | 无需素材，全屏色调 |
| 画面撕裂 | 无需素材，着色器实现 |

## 2.6 提交规范

```
assets/scenes/场景名/
  ├── 场景名_bg.png        # 背景
  ├── hero_idle.png        # 勇者待机
  ├── hero_move.png        # 勇者移动（可选）
  ├── 元素名.png            # 事件要素
  └── prop_道具名.png       # 可交互道具
```

---

# ═══════════════════════════════════════════
# 第三部分：给AI代码合并看
# ═══════════════════════════════════════════

## 3.1 合并前检查清单

每个模块的代码提交合并前，逐项检查：

- [ ] 文件在正确目录（core/forum/game/minigames/events/data/ui）
- [ ] 文件名PascalCase
- [ ] 有 `class_name` 声明
- [ ] 函数参数返回值有类型标注
- [ ] 没有直接调用其他模块（只用EventBus信号）
- [ ] 没有硬编码文本（从data/JSON读取）
- [ ] 资源路径用 `res://` 绝对路径
- [ ] 小游戏继承MiniGameBase
- [ ] 节点继承NodeBase
- [ ] 没有修改EventBus信号签名
- [ ] 没有全局变量（除core单例）
- [ ] 没有assert运行时检查

## 3.2 合并顺序

```
1. core/EventBus.gd        ← 先合并，所有人基于此
2. core/其他单例 + 基类     ← 依赖EventBus
3. ui/ResourceBar          ← 依赖ResourceManager
4. forum/全部              ← 依赖core+ui
5. minigames/3个           ← 依赖MiniGameBase
6. game/nodes/5个          ← 依赖NodeBase
7. events/EventManager     ← 依赖core
8. data/JSON配置           ← 最后填内容
```

## 3.3 常见合并冲突处理

| 冲突类型 | 处理方式 |
|---------|---------|
| EventBus信号签名不一致 | 以main分支为准，其他人调整 |
| 资源路径冲突 | 统一用 `res://assets/分类/文件名` |
| class_name重复 | 检查是否有两个文件声明同名class |
| 场景引用断裂 | 检查.tscn里的脚本路径是否正确 |
| 信号未连接 | 检查connect是否在_ready()中调用 |

## 3.4 自动化检查脚本（可选）

合并后运行以下检查：
```bash
# 检查硬编码中文（应从JSON读取）
grep -rn "[\x{4e00}-\x{9fff}]" --include="*.gd" | grep -v "data/" | grep -v "#"

# 检查相对路径
grep -rn "load(\"res://" --include="*.gd" | wc -l  # 应全部为res://
grep -rn "load(\"../" --include="*.gd"              # 应无输出

# 检查class_name声明
grep -rL "class_name" --include="*.gd" core/ forum/ game/ minigames/
```

---

# ═══════════════════════════════════════════
# 第四部分：给文案策划看（用户自己）
# ═══════════════════════════════════════════

## 4.1 你需要填写的内容

| 文档/文件 | 内容 | 优先级 |
|----------|------|--------|
| 5个固定节点剧本 | 场景/要素/玩法/选项/分支 | 最高 |
| data/options.json | 每个事件的预设选项 | 高 |
| data/dialogues.json | 论坛楼层文案（网友吐槽/骰子娘旁白/楼主补刀） | 高 |
| data/topics.json | 话题池（固定话题+解锁条件+引发节点） | 中 |
| data/events.json | 论坛事件配置 | 中 |

## 4.2 节点剧本填写模板

每个节点按以下格式写：

```markdown
### 节点①
- 场景：村庄广场
- 事件要素：装备商人/宝箱/训练假人
- 解谜玩法：拖拽配装，30秒内配齐3件装备
- 预设选项（5-6条）：
  1. 选剑（正经，+攻击）
  2. 选盾（正经，+防御）
  3. 选弓（正经，+远程）
  4. 选魔法书（正经，+魔法）
  5. 选面包（离谱，+饱腹度无用）
  6. 全都要（离谱，触发商人发火）
- 分支与关键词产出：
  - 选剑 → 关键词"剑"入池
  - 全都要 → 关键词"贪心"入池，气人+10
- 可被提话题触发引入：是（话题"勇者缺武器"→引入此节点）
```

## 4.3 JSON数据格式

### data/options.json
```json
{
  "node_1": [
    {"id": "sword", "text": "选剑", "type": "serious", "weight": 1.0, "keywords": ["剑"]},
    {"id": "shield", "text": "选盾", "type": "serious", "weight": 1.0, "keywords": ["盾"]},
    {"id": "bread", "text": "选面包", "type": "chaotic", "weight": 0.8, "keywords": ["面包"]}
  ],
  "node_2": [
    ...
  ]
}
```

字段说明：
- `id`：唯一标识
- `text`：选项显示文本
- `type`：`serious`(正经) / `chaotic`(离谱) / `special`(骚选项)
- `weight`：基础权重，气人/人气会调整

### data/dialogues.json
```json
{
  "forum_reactions": {
    "big_success": [
      "骰子娘: D100=95 大成功！",
      "回复A: 牛逼！",
      "回复B: 这运气没谁了"
    ],
    "big_failure": [
      "骰子娘: D100=5 大失败...",
      "回复A: 笑死",
      "回复B: 楼主快出来挨打"
    ]
  },
  "node_transitions": {
    "1_to_2": [
      "楼主: 勇者整备完毕，向森林出发",
      "回复A: 终于要出门了"
    ]
  }
}
```

### data/topics.json
```json
{
  "topics": [
    {
      "id": "lack_weapon",
      "text": "勇者是不是太缺乏武器了",
      "unlock_condition": "initial",
      "trigger_node": 1,
      "base_probability": 0.3
    },
    {
      "id": "hungry",
      "text": "勇者好像饿了",
      "unlock_condition": "node_1_completed",
      "trigger_node": null,
      "base_probability": 0.3
    }
  ]
}
```

### data/events.json
```json
{
  "forum_events": [
    {
      "id": "flame_war",
      "name": "网友骂战",
      "trigger_condition": {"type": "qi_ren", "value": 50},
      "trigger_probability": 0.5,
      "duration": 30,
      "effects": ["bullet_screen_obscure"],
      "leads_to_node": null
    },
    {
      "id": "add_more",
      "name": "加更事件",
      "trigger_condition": {"type": "ren_qi", "value": 50},
      "trigger_probability": 0.3,
      "duration": 30,
      "effects": ["gift_item"],
      "leads_to_node": 1
    }
  ]
}
```

## 4.4 文案写作建议

### 论坛楼层风格
- 楼主：推动剧情，正经但偶尔搞笑
- 骰子娘：公布骰子结果，机械但偶尔吐槽
- 网友A-Z：吐槽/拱火/出馊主意，语气各异
- 管理员：红字公告，严肃

### 选项文本
- 正经选项：简洁明确（"打败龙"）
- 离谱选项：搞笑但有逻辑（"千年杀龙"）
- 骚选项：出人意料但有趣（"和龙拜把子"）

### 节点间文案（不超过5句）
- 推进剧情1句
- 网友吐槽2-3句
- 楼主补刀1句

## 4.5 优先填写顺序

1. 5个节点的剧本（最重要，决定整个游戏骨架）
2. data/options.json（每个节点的预设选项）
3. data/dialogues.json（论坛文案）
4. data/topics.json（话题池）
5. data/events.json（论坛事件配置）

---

## 附：项目当前状态

- ✅ 策划文档完成（game_design_v1.0.md）
- ✅ 开发计划完成（dev_plan_v1.1.md）
- ✅ Git仓库已配置（https://github.com/Aolibibi/Anchor-Game.git）
- ⏳ 待填：5个节点剧本
- ⏳ 待填：data/ JSON配置
- ⏳ 待开发：代码骨架（core/EventBus 优先）
- ⏳ 待制作：美术资产
- ⏳ 待创作：BGM（1旋律2编曲）

### Git推送命令（网络恢复后执行）
```bash
cd D:\Godot\AnkakeProject
git push -u origin main
```

---

*v1.2 - 协作手册, 四部分分工, 待执行*
