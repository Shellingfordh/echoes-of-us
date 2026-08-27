# Echoes of Us｜开源项目复用与技术验证方案

## 0. 使用原则

本项目开发时间极短，因此原则是：

**能直接复用成熟代码就不自己造；能只参考局部实现就不整体引入；任何开源项目必须先确认 Godot 版本、许可证和实际运行情况，再决定是否进入项目。**

本项目真正需要自己开发的部分只有：

`牵挂线核心机制 + 关卡逻辑 + 剧情触发 + 最终规则打破`

人物移动、基础 Camera、对话框等成熟基础能力优先考虑复用。

---

# 1. Godot Foundation Platformer 2D Demo

[GitHub / Godot Foundation Platformer 2D Demo](https://store.godotengine.org/asset/godot-foundation/platformer-2d-demo/?utm_source=chatgpt.com)

**优先级：★★★★★**

**建议：优先作为技术负责人学习和基础项目参考，必要时直接复制基础 Player / Level 结构。**

这是目前最适合你们的基础参考。

官方项目目前最低 Godot 版本为 4.7，使用 GDScript 和 Compatibility Renderer，MIT 许可证。项目已经包含角色移动、跳跃、坡面、物理对象、敌人等基础能力。([Godot Asset Store][2])

### 我们需要什么

不要整个游戏照搬。

重点研究：

```text
Player
CharacterBody2D
移动
跳跃
碰撞
Camera
Level
Scene
```

### 我们最终需要保留

```text
Player
 ↓
移动
 ↓
碰撞
 ↓
Camera
 ↓
Level
```

然后删除：

```text
攻击
敌人
血量
无关 UI
无关道具
```

最后变成：

```text
Player
Mother
TieLine
InteractiveObject
Trigger
Level
Camera
Dialogue
```

### 技术负责人任务

第一步：

确认当前项目 Godot 版本。

第二步：

打开官方 Demo。

第三步：

让 Demo 正常运行。

第四步：

找到 Player 对应 Scene。

第五步：

理解 Player 的移动代码。

第六步：

不要马上修改。

先复制出一个最小 Player 测试场景。

### Agent 任务

把下面内容交给 Agent：

```text
你是 Godot 技术开发 Agent。

请分析这个 Godot Platformer 2D Demo。

目标不是学习整个项目。

我们只需要从中提取：

1. Player Scene
2. CharacterBody2D
3. 玩家移动
4. 跳跃
5. Collision
6. Camera
7. Level Scene

请告诉我：

每个功能对应哪些文件。

哪些文件可以直接复制。

哪些代码存在项目耦合。

哪些内容不能直接复制。

我们的目标项目是一个三天 Game Jam 项目。

不要进行重构。

不要引入新的架构。

最后给出“最小可复用文件清单”。
```

### 风险

这个 Demo 当前版本是 Godot 4.7，技术负责人必须确认你们实际项目版本是否一致。([Godot Asset Store][2])

**不要为了迁移旧项目浪费半天。**

---

# 2. kumabotz/godot-2.5d

[GitHub / godot-2.5d](https://github.com/kumabotz/godot-2.5d?utm_source=chatgpt.com)

**优先级：★★★★☆**

**用途：研究 2.5D 真实视角方案。**

这个项目非常符合我们之前想做的方向。

它实际上是把 2D Sprite 和 3D 空间坐标结合起来。

项目使用 `Node25D`，通过 3D 坐标计算物体位置，再用 2D Sprite 显示；同时提供 top-down、front-side、45°、isometric、oblique 等视角。([GitHub][1])

### 它对我们最有价值的地方

不是直接拿它整个项目。

而是验证：

> **我们能不能用 2D AI 素材获得真正的空间感和视角切换。**

例如：

```text
正面视角
     ↓
侧面视角
     ↓
45°视角
```

同一个场景：

```text
       妈妈
        ●
        │
        │
        ● 女儿
```

切换以后：

```text
      妈妈
       ●
      /
     /
   ●
 女儿
```

玩家真正看到的是空间关系变化。

### 最大问题

这个仓库是老方案。

README 明确写的是：

`GLES 2`

而且使用旧 Godot 架构。([GitHub][1])

所以：

**不要直接把它当项目底座。**

### 技术负责人任务

只做一个验证：

> 能不能在你们当前 Godot 版本里跑起来。

如果不能：

**立即停止迁移。**

不要花时间升级整个插件。

### Agent 任务

```text
分析 github.com/kumabotz/godot-2.5d。

我们的目标是 Godot 4.x Game Jam 项目。

不要直接迁移整个项目。

请分析：

1. Node25D 的核心实现原理。
2. 2D Sprite 如何映射到 3D 坐标。
3. Camera / View Mode 如何实现。
4. 视角切换需要哪些核心代码。
5. 哪些代码依赖 Godot 3。
6. 如果只想实现“两个固定视角切换”，最少需要提取什么。

最终输出：

A. 可以直接复用的部分。
B. 只能参考的部分。
C. 不建议使用的部分。
D. 如果自己实现最小版本，需要多少代码。
```

### 验收标准

不要追求完整 2.5D。

只需要做到：

> **一个场景，两个固定视角，按一个键切换。**

如果 2 小时内做不到，放弃。

---

# 3. mikest/halyard

[GitHub / mikest/halyard](https://github.com/mikest/halyard?utm_source=chatgpt.com)

**优先级：★★☆☆☆**

**用途：研究真实 Rope / Anchor，不建议三天项目直接接入。**

这个项目目前针对 Godot 4.5+，采用 Verlet rope simulation，支持 Anchor、Attachment、Rope Length、Stiffness、碰撞和动态长度等。([GitHub][3])

理论上非常适合我们的：

> 母亲 ↔ 女儿 ↔ 牵挂线

但是有一个巨大的问题。

它不是纯 GDScript 小组件。

安装需要 clone 到 addons，并通过 SCons 或 CMake 构建库。项目 README 也明确提到 macOS 上可能需要处理动态库打开权限。([GitHub][3])

对于你们三天项目：

**风险远高于收益。**

### 不要做

不要：

```text
安装
↓
编译
↓
处理 dylib
↓
解决版本问题
↓
研究 Rope Physics
```

这非常容易把技术负责人拖死。

### 可以做

让 Agent 分析：

```text
Rope
RopeAnchor
Attachment
Rope Length
Stiffness
```

看看这些概念怎么组织。

然后你们自己用简单数学实现：

```text
distance = mother.position.distance_to(daughter.position)

if distance > max_distance:
    tension = true
```

视觉：

```text
Line2D
```

最后：

```text
Tension
 ↓
拉回
```

### Agent Prompt

```text
分析 mikest/halyard。

不要要求我安装或编译它。

只分析：

1. Rope 的数据结构。
2. Anchor 如何工作。
3. Attachment 如何工作。
4. Rope Length 如何控制。
5. Stiffness 如何影响物体。
6. 我们的游戏是否真的需要这些。

我们的游戏只有三天开发时间。

请设计一个“不依赖 Halyard”的最小牵挂线系统。

要求：

妈妈和女儿之间有一条 Line2D。

距离小于 MAX_DISTANCE：

NORMAL。

距离接近 MAX_DISTANCE：

TENSION。

超过 MAX_DISTANCE：

PULL_BACK。

最后一关允许：

EXTEND。

输出最小 Godot 实现方案。
```

---

# 4. QueenChristina/gd_dialog

[GitHub / QueenChristina/gd_dialog](https://github.com/QueenChristina/gd_dialog?utm_source=chatgpt.com)

**优先级：★★★★☆**

**建议：可以直接复用。**

这是一个 Godot 开源 Dialogue System，MIT 许可证。

它支持：

```text
Dialogue
Branching
Conditional Dialogue
Actions
Signals
Character Icons
Typewriter
Voice
RichText
JSON Dialogue Data
```

而且作者特意把对话内容和游戏逻辑分离，通过 JSON 管理对白。([GitHub][4])

这非常适合你们。

因为剧情同学可以写：

```text
D001
D002
D003
```

技术不用每次改剧情都改 GDScript。

### 我们只需要

```text
角色名
对白
下一句
触发
结束
```

不需要：

```text
复杂分支
RPG 属性
Inventory
Voice
复杂条件
```

### 推荐做法

保留：

```text
Dialogue UI
Dialogue Data
Trigger
Next
Signal
```

删除：

```text
RPG相关功能
Inventory
复杂条件
不需要的 Voice
```

### Agent Prompt

```text
分析 QueenChristina/gd_dialog。

我们的游戏是三天 Game Jam。

我们只需要：

角色名
对白
下一句
触发
结束
Signal

请找出：

1. Dialogue UI 的核心文件。
2. Dialogue 数据文件。
3. Dialogue 播放器。
4. Trigger / Signal。
5. 哪些文件和 RPG 项目强耦合。
6. 哪些内容可以直接复制。

不要安装完整 RPG Demo。

最终输出一个最小 Dialogue System 文件清单。

要求：

剧情策划只修改 JSON / 数据文件。

技术只负责：

Trigger Dialogue
Dialogue Start
Dialogue End
```

---

# 5. ufrshubham/Invert

[GitHub / Invert](https://github.com/ufrshubham/Invert?utm_source=chatgpt.com)

**优先级：★★★☆☆**

**用途：关卡设计参考，不建议直接拿代码。**

这是一个非常典型的 Game Jam 小机制设计。

核心机制只有：

> 一个控制器同时控制两个角色。

向左：

```text
A ←
B →
```

向右：

```text
A →
B ←
```

玩家必须利用这个规则完成关卡。

项目使用 Godot，MIT License。([GitHub][5])

### 我们真正应该学习的东西

不是代码。

而是：

> **一个规则可以撑起整个游戏。**

你们现在的牵挂线也应该按照这个思路：

```text
第一关
认识规则

第二关
使用规则

第三关
利用规则解决问题

第四关
改变规则

第五关
打破规则
```

这才是你们的关卡成长曲线。

### Agent Prompt

```text
分析 ufrshubham/Invert。

不要复制代码。

我要研究它的关卡设计。

请分析：

1. 玩家第一次学到什么。
2. 游戏什么时候开始要求玩家主动利用规则。
3. 同一个机制如何产生不同谜题。
4. 玩家什么时候形成固定预期。
5. 游戏如何利用预期制造变化。

然后把这种结构映射到我们的：

“母女牵挂线”。

输出：

Level 01
Level 02
Level 03
Level 04

每关只增加一个认知变化。
```

---

# 6. geegaz/A-Key-s-Path

[GitHub / A Key(s) Path](https://github.com/geegaz/A-Key-s-Path?utm_source=chatgpt.com)

**优先级：★★★☆☆**

**用途：研究“机制改变玩家能力”的设计。**

它是 GMTK Game Jam 2020 的作品。

核心设计非常漂亮：

> 玩家把自己的移动按键放进场景后，这个按键就会变成平台。

但问题是：

> 按键放进去以后，玩家暂时失去对应移动能力。

所以：

```text
能力
↔
关卡资源
```

发生了交换。

项目是 Godot 3，并采用 GPL-3.0。([GitHub][6])

### 对我们有什么启发

你们可以研究：

> **牵挂线改变玩家能力。**

例如：

正常：

```text
线 = 限制
```

某个关卡：

```text
线 = 跳跃辅助
```

最后：

```text
线 = 可以延伸
```

玩家学到的东西和能力本身发生变化。

### 注意许可证

这个仓库是 GPL-3.0。

**不要直接复制代码进你们最终项目，除非技术负责人确认你们接受 GPL 条款。**

最安全的做法：

> 只研究机制和关卡设计。

### Agent Prompt

```text
分析 geegaz/A-Key-s-Path。

不要复制代码。

只研究机制设计。

重点分析：

玩家能力如何与关卡资源发生冲突。

然后把这个设计思想转换成我们的“牵挂线”。

要求：

不增加复杂按键。

不增加复杂系统。

只允许使用：

移动
交互
聚焦

三个核心操作。

设计三个可以体现：

“线既限制玩家，又帮助玩家”

的关卡。
```

---

# 7. GDQuest Godot Platformer

[GDQuest Godot Platformer Repository](https://github.com/gdquest-demos/godot-platformer-2d?utm_source=chatgpt.com)

**优先级：★★★☆☆**

**用途：学习项目组织、Player、Camera、关卡和开发流程。**

这个项目是一个 2D Metroidvania 风格 Demo，MIT License。

它本身就强调：

> 用一个机制承担多种用途。

同时包含角色控制、Camera、Level Design、关卡切换、死亡重来等完整开发流程。([GitHub][7])

### 对你们特别有价值的是

它的项目思路本身就非常符合 Game Jam：

> **少机制，做深一点。**

它的文档甚至明确强调控制项目规模，避免 Feature Creep。([GitHub][7])

### 不建议

不要直接迁移这个项目。

因为它是较早的 Godot 项目，并且包含 GDNative 等旧技术内容。([GitHub][7])

### 建议

技术负责人只研究：

```text
Player
Camera
Level
Transition
Death
Restart
Scene organization
```

### Agent Prompt

```text
分析 gdquest-demos/godot-platformer-2d。

不要迁移整个项目。

请只分析：

Player
Camera
Level
Scene
Transition
Restart
项目目录结构

重点告诉我：

如果我们是三天 Game Jam，

哪些结构值得借鉴。

哪些结构过于复杂。

哪些内容属于旧版 Godot。

最后输出：

“Echoes of Us 最小 Godot 项目结构”。

不要增加系统。
```

---

# 8. 最终技术选型

经过上面的筛选，我建议技术负责人**不要同时安装所有项目**。

直接按照：

```text
第一优先
Godot Foundation Platformer
        ↓
人物移动 / Camera / Level

第二优先
gd_dialog
        ↓
剧情 / Dialogue / Trigger

第三优先
godot-2.5d
        ↓
只验证真实 2.5D 是否值得做

第四优先
Halyard
        ↓
只读代码，不接入

第五优先
Invert
        ↓
研究关卡

第六优先
A Key(s) Path
        ↓
研究机制

第七优先
GDQuest
        ↓
研究项目结构
```

---

# 9. agent今天的实际任务

直接给agent下面这个任务。

## 上午

### TASK-001

跑通 Godot Foundation Platformer。

验收：

```text
玩家可以移动
玩家可以跳跃
玩家可以碰撞
Camera 可以跟随
```

完成后停止。

---

## 中午

### TASK-002

跑通 / 分析 `gd_dialog`。

验收：

```text
游戏启动
 ↓
玩家移动
 ↓
进入 Trigger
 ↓
出现中文对白
 ↓
按键下一句
 ↓
对白结束
 ↓
恢复玩家控制
```

如果 2 小时还没跑通：

**不要继续折腾，自己做一个最简单 Dialogue Box。**

---

## 下午

### TASK-003

验证 `godot-2.5d`。

只回答：

> 当前 Godot 版本能不能直接运行？

如果：

```text
YES
```

再研究：

> 能不能实现两个固定视角切换。

如果：

```text
NO
```

直接停止。

不要迁移旧插件。

---

## 晚上

### TASK-004

自己做最小牵挂线。

不要使用 Halyard。

直接：

```text
Mother
Daughter
Line2D
distance
MAX_DISTANCE
```

实现：

```text
NORMAL
TENSION
PULL_BACK
EXTEND
```

这是你们真正的核心代码。

---

# 10.  Agent Prompt

以后每研究一个 Repo，就直接把这个扔给 Agent：

```text
你现在是 Echoes of Us 项目的技术顾问。

我是一个刚开始学习 Godot 的开发者。

我们正在进行一个只有三天时间的 Game Jam。

请不要把我当成熟 Godot 开发者。

我会 Python，但没有完整游戏开发经验。

现在我要研究一个 GitHub 开源项目：

[填写 Repo URL]

我们的目标不是学习整个项目，也不是迁移整个项目。

我们的目标是判断：

“这个 Repo 有没有东西可以直接帮我们节省开发时间。”

请严格按照下面格式分析。

====================

一、项目用途

这个项目解决什么问题？

====================

二、Godot 版本

它使用什么版本？

是否适合我们当前 Godot 版本？

如果版本不一致：

明确告诉我。

====================

三、许可证

许可证是什么？

能否用于 Game Jam？

是否需要署名？

是否存在 GPL 等需要特别注意的要求？

====================

四、我们能直接复用什么

只列真正值得复用的部分。

例如：

Player
Camera
Dialogue
Scene
Rope

====================

五、不能直接复用什么

指出：

版本问题。

依赖。

复杂架构。

第三方库。

旧 API。

原项目耦合。

====================

六、最小复用方案

如果我要在三天内使用它：

告诉我最少需要复制哪些文件。

不要给我完整迁移方案。

====================

七、Godot 操作

一步一步告诉我：

打开什么。

复制什么。

放到哪里。

创建什么 Node。

挂什么 Script。

====================

八、风险

按照：

低 / 中 / 高

评估。

重点考虑：

版本。

依赖。

编译。

许可证。

新手操作难度。

调试难度。

====================

九、最终建议

只能选择：

【直接复用】

【局部借鉴】

【只研究】

【放弃】

并说明原因。

====================

十、如果我决定复用

给我一个最小任务列表。

每个任务控制在：

30～60 分钟。

不要让我一次做一个大型系统。

记住：

这是三天 Game Jam。

稳定可运行 > 架构漂亮。

少功能完整 > 多功能半成品。
```

---

## 最后我给你一个非常明确的判断

你们现在**不要试图找一个“母女 + 2.5D + 解谜 + 叙事”的完整开源项目然后改成你们的游戏**。那种项目即使找到了，架构、版本和资产也很可能跟你们不匹配。

你们真正应该做的是：

**拿成熟项目解决基础能力，把开发资源全部集中到“牵挂线”这一件自己的东西上。**

尤其是 `Godot Foundation Platformer + gd_dialog`，我认为可以作为你们当前最现实的两个基础支点。官方 Platformer Demo 当前是 Godot 4.7 / MIT，`gd_dialog` 是 MIT，并且对话数据与游戏逻辑分离，很适合你们剧情同学直接参与。([Godot Asset Store][2])

而 `godot-2.5d` 我会把它当成**一个两小时的技术赌注**：如果能快速验证，就把视角切换作为你们的宣传闪光点；验证不通过，立刻砍掉，不允许技术负责人陷入迁移地狱。([GitHub][1])

**Halyard 则暂时封印。**它能力确实强，但对于你们当前的三天周期，编译和集成成本明显不划算。([GitHub][3])

这样技术路线就非常清楚了：

> **开源项目负责让游戏“跑起来”，你们自己的牵挂线负责让游戏“值得玩”。**

[1]: https://github.com/kumabotz/godot-2.5d?utm_source=chatgpt.com "GitHub - kumabotz/godot-2.5d · GitHub"
[2]: https://store.godotengine.org/asset/godot-foundation/platformer-2d-demo/?utm_source=chatgpt.com "Platformer 2D Demo - Godot Asset Store"
[3]: https://github.com/mikest/halyard?utm_source=chatgpt.com "GitHub - mikest/halyard: Rope simulation for Godot 4.5+ · GitHub"
[4]: https://github.com/QueenChristina/gd_dialog?utm_source=chatgpt.com "GitHub - QueenChristina/gd_dialog: Open source robust dialogue system in Godot. Suitable for RPGs, visual novels, interactive fiction, and other games requiring dialogue. · GitHub"
[5]: https://github.com/ufrshubham/Invert?utm_source=chatgpt.com "GitHub - ufrshubham/Invert: A 2D Puzzle Platformer made using Godot. · GitHub"
[6]: https://github.com/geegaz/A-Key-s-Path?utm_source=chatgpt.com "GitHub - geegaz/A-Key-s-Path: A short puzzle-platformer game made with Godot, running on GLES 2.0. · GitHub"
[7]: https://github.com/gdquest-demos/godot-platformer-2d?utm_source=chatgpt.com "GitHub - gdquest-demos/godot-platformer-2d: 2d Metroidvania-inspired game for the 2019 GDquest Godot Kickstarter course project. · GitHub"
