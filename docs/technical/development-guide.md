# 开发规范｜Development Guide

## 1. 开发环境

项目：

> Godot 4.x

启动方式：

1. 打开项目；
2. 确认 `project.godot`；
3. 运行 Main Scene；
4. 确认 Level 01 可以进入。

---

# 2. Git 分支

禁止直接在 main 开发。

格式：

```text
feature/<feature-name>
fix/<bug-name>
refactor/<module-name>
```

示例：

```text
feature/player-movement
feature/tie-line
feature/dialogue-system
fix/tie-line-trigger
```

---

# 3. Commit

Commit 应描述实际变化。

推荐：

```text
Add basic player movement
Add TieLine tension states
Add Memory Lock puzzle
Fix dialogue trigger timing
```

避免：

```text
update
test
aaa
final
final2
```

一个 Commit 尽量对应一个逻辑变化。

---

# 4. Pull Request

标题：

```text
[Feature] Add TieLine system
```

正文：

```markdown
## What

实现基础牵挂线系统。

## Test

进入 Level01，让玩家远离 Mother。

检查：

- 线是否跟随；
- tension 是否变化；
- Tense 是否触发。

## Notes

当前参数为 Prototype 值。
```

---

# 5. PR 检查

合并前至少确认：

- 能启动；
- 没有新增明显错误；
- 自己负责的流程完整；
- 没有无关文件；
- 没有提交本地临时文件；
- 没有修改不相关系统。

---

# 6. GDScript 规范

变量：

```gdscript
var player_distance: float
```

函数：

```gdscript
func update_tension() -> void:
    pass
```

常量：

```gdscript
const MAX_DISTANCE := 300.0
```

使用 snake_case。

类和节点命名：

> PascalCase。

---

# 7. 信号

Signal 名称建议：

```text
tension_changed
interaction_started
interaction_finished
puzzle_completed
dialogue_finished
memory_started
memory_finished
```

Signal 表达：

> “发生了什么”。

不要使用：

```text
do_something
```

这种无法表达事件语义的名称。

---

# 8. 场景与脚本职责

避免一个脚本同时处理：

- 玩家移动；
- 对白；
- 谜题；
- Camera；
- UI。

推荐职责单一。

例如：

```text
Player.gd
TieLine.gd
PuzzleManager.gd
DialogueManager.gd
CameraController.gd
```

---

# 9. 调试

Debug 输出必须带事件 ID。

例如：

```text
[TieLine] state=TENSE distance=284.2
[Puzzle] connect A -> B result=SUCCESS
[Dialogue] trigger=D040
[Memory] state=TRANSITION
```

不要大量输出：

```text
update
update
update
```

高频数据应允许 Debug 开关控制。

---

# 10. Bug 报告

每个 Bug 至少写：

```text
Title:
Environment:
Steps:
Expected:
Actual:
Repro:
Severity:
Screenshot/Video:
```

示例：

```text
Title:
TieLine does not enter Tense state

Steps:
1. Start Level01
2. Walk away from Mother
3. Reach approximately 300px

Expected:
TieLine becomes Tense

Actual:
Line remains Normal

Repro:
5/5

Severity:
High
```

---

# 11. 技术与策划变更

如果发现策划要求无法合理实现：

不要自行改变剧情。

应记录：

```text
Original Requirement
Technical Constraint
Proposed Alternative
Impact
```

例如：

```text
Requirement:
牵挂线实时物理摆动

Constraint:
当前 Prototype 时间不足

Alternative:
距离驱动 Line2D + 轻微 Shader/Animation

Impact:
玩家仍然可以感受到张力，但不是真实物理
```

交给负责人确认。

---

# 12. 性能原则

Demo 不需要过早优化。

优先避免：

- 每帧大量实例化；
- 不必要的节点创建销毁；
- 无限 Debug Log；
- 超大纹理；
- 无限制粒子；
- 不必要的物理计算。

如果没有性能问题：

> 不为了“看起来专业”增加复杂优化。

---

# 13. 发布前检查

### 功能

- [ ] 游戏能启动
- [ ] Level01 能进入
- [ ] Player 可移动
- [ ] TieLine 正常
- [ ] Puzzle 可完成
- [ ] Dialogue 正常
- [ ] Memory Transition 正常
- [ ] Ending 正常

### 内容

- [ ] 没有占位文字
- [ ] 没有调试 UI
- [ ] 没有明显报错
- [ ] 所有正式素材已替换

### Git

- [ ] main 可运行
- [ ] 无临时文件
- [ ] PR 已合并
- [ ] 版本号已确认

---

# 14. 最重要的开发原则

这个项目不是为了证明架构多复杂。

目标是：

> 在有限时间内完成一个能够让玩家真正理解“不断线”这个概念的完整 Demo。

所以：

> **先完成体验闭环，再追求工程优雅。**
