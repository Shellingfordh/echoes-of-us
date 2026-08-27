# 技术架构｜Architecture

## 1. 技术栈

项目使用：

> Godot 4.x

核心语言：

> GDScript

项目目标是快速完成一个 3～5 分钟的可运行 Demo，因此架构以：

> 简单、可调、可复用、易调试

为第一优先级。

不为了“未来可能扩展”引入复杂框架。

---

# 2. 核心模块

```text
Game
├── GameState
├── LevelManager
├── Player
├── Mother
├── TieLine
├── InteractionSystem
├── PuzzleSystem
├── DialogueSystem
├── CameraController
└── Debug
```

---

# 3. Player

负责：

- 输入；
- 移动；
- 动画状态；
- 当前交互对象；
- 玩家控制权。

Player 不负责：

- 剧情；
- 谜题规则；
- 对白内容；
- 记忆场景逻辑。

---

# 4. Mother / NPC

负责：

- NPC 位置；
- NPC 动画；
- NPC 基础状态；
- 与玩家之间的空间关系。

Mother 不应该直接控制整个关卡。

---

# 5. TieLine

TieLine 是核心玩法系统。

输入：

```text
source_position
target_position
distance
```

输出：

```text
state
visual_parameters
tension_value
```

建议状态：

```text
Hidden
Reveal
Normal
Tense
Stable
```

Prototype 不要求真正物理绳索。

优先使用：

> 距离计算 + Line2D + 状态机。

---

# 6. Tension

可以定义：

```text
distance / max_distance
```

形成一个 0～1 的归一化值。

例如：

```text
0.0 ～ 0.6
Normal

0.6 ～ 0.9
Tense

0.9 ～ 1.0
Critical
```

具体阈值必须可配置。

不要把数值硬编码在视觉脚本中。

---

# 7. LevelManager

负责：

- 当前关卡状态；
- 节点触发；
- 场景流程；
- Puzzle 状态；
- Memory 状态；
- Ending。

LevelManager 不负责角色移动。

---

# 8. InteractionSystem

统一管理：

```text
Inspectable
Connectable
Movable
MemoryTrigger
```

建议每个交互对象暴露统一的交互接口。

技术实现可以自行决定使用：

- Area2D；
- Signal；
- Interface；
- Component。

策划文档不限制具体实现。

---

# 9. DialogueSystem

负责：

- Dialogue ID；
- 文本；
- Speaker；
- Duration；
- Blocking；
- Trigger。

剧情文件是对白的 Source of Truth。

技术不要复制多份台词文本。

---

# 10. PuzzleSystem

负责：

- 当前连接；
- 正确顺序；
- 错误次数；
- 成功判定；
- Reset。

Puzzle 数据最好与具体视觉节点解耦。

---

# 11. CameraController

负责：

- Follow；
- Focus；
- Transition；
- Memory Transition；
- Ending。

Camera 不应由每个剧情节点直接修改大量参数。

最好提供统一接口：

```text
focus(target)
transition_to(target)
reset()
```

---

# 12. Game State

建议至少：

```text
NORMAL
DIALOGUE
PUZZLE
MEMORY_TRANSITION
MEMORY
ENDING
```

Player 是否可移动由 Game State 统一决定。

避免在多个脚本里分别写：

```text
player.can_move = false
```

造成状态互相覆盖。

---

# 13. 数据流

```text
Player Input
      ↓
Player
      ↓
Position
      ↓
TieLine
      ↓
Tension Value
      ↓
LevelManager
      ↓
Event
      ↓
Dialogue / Puzzle / Camera
```

---

# 14. 场景结构建议

```text
game/scenes/
├── main/
│   └── main.tscn
├── levels/
│   └── level_01/
│       └── level_01.tscn
├── characters/
├── props/
└── ui/
```

具体 Node 层级可以由技术负责人调整。

---

# 15. 参数配置

以下参数必须可调：

```text
tie_line.reveal_distance
tie_line.tension_distance
tie_line.max_distance
tie_line.visual_width
puzzle.max_errors
puzzle.success_hold_time
interaction.range
dialogue.default_duration
```

不要为了 Prototype 参数化所有东西。

只参数化：

> 需要频繁调试的数值。

---

# 16. Debug

Debug 模式至少能看到：

```text
player position
mother position
distance
tension
tie_line_state
puzzle_state
game_state
last_event_id
```

这样当策划说：

> “我刚才走到这里为什么没触发？”

技术可以直接定位。

---

# 17. 技术边界

剧情不规定：

- Node 结构；
- Script 名称；
- API；
- Signal 组织方式；
- SceneManager 实现方式。

关卡只规定：

> 输入条件、行为、结果。

技术负责选择最合理实现。

---

# 18. Prototype 优先级

P0：

```text
Player Movement
TieLine
Distance/Tension
Interaction
Puzzle
Dialogue
Memory Transition
Ending
```

P1：

```text
更好的动画
更好的 Camera
更完整 Debug
```

P2：

```text
复杂优化
扩展系统
工具链
```

如果时间不足，优先保证 P0 完整可玩。
