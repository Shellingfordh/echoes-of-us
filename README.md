# Echoes of Us

## 《不断线》

关系驱动的叙事解谜游戏 Demo。

---

# 🚨 新成员先看这里

这个仓库是我们整个游戏项目的正式文件库。

如果你完全不会 GitHub，不用害怕。

你只需要记住：

> **文档放 `docs/`，正式游戏素材放 `assets/`，技术代码放 `scripts/`，Godot 场景放 `scenes/`。**

不要自己新建：

- 我的文件夹
- 小王文件夹
- 最终版
- 最终版2
- final
- final_final

所有文件按照项目结构放。

---

# 🎮 项目简介

**游戏类型**

关系驱动的叙事解谜游戏

**核心机制**

牵挂线 / Invisible Tie

**核心概念**

Relationship Physics / 关系物理

玩家可以看见人与人、人与物、人与记忆之间不可见的连接，并利用这些连接解决问题。

**视觉方向**

2D 绘本 + 2.5D 视差 + 少量伪 3D 镜头演出

**Demo 长度**

约 3～5 分钟

**Demo 范围**

一个完整关卡。

完整经历：

母女关系
→
发现牵挂线
→
学习机制
→
解谜
→
进入记忆
→
理解关系
→
女儿离开
→
线不断

---

# 🕹️ 当前可玩原型

仓库已经包含一个可从头到尾完成的四幕 Godot 灰盒 Demo，当前实现：

- 第一幕：离家探索、5 个可选记忆碎片、3 个环境回响、牵挂线显现与雨伞记忆；
- 第二幕：母女视角切换、自行车协作、水洼、柜子机关、路灯锚点与童年告别；
- 第三幕：双向锚定、仓库推箱/钻洞、屋顶交替协作、陌生人牵挂线与钥匙回声；
- 第四幕：长距离奔跑、牵挂线延展、母亲切镜与根据收集结果变化的结尾；
- Hidden / Tense / Adjustable / Extending 四种牵挂线状态；
- 零失败流程、章节转场、检查点反馈和可切换的实时 Debug 面板。

开发验证版本：

> Godot 4.7.2（工程保持 Godot 4.x Compatibility Renderer 配置）

运行：

```bash
godot --path .
```

操作：

```text
WASD / 方向键    移动
E / 鼠标左键      互动
Tab              切换控制角色
空格 / 鼠标左键   主动控制牵挂线
Shift            奔跑
R                重新开始
F3               显示/隐藏 Debug
```

无界面流程测试：

```bash
godot --headless --path . --script res://scripts/tests/smoke_test.gd
```

---

# 📁 仓库结构

```text
echoes-of-us/

├── README.md
├── project.godot
├── .gitignore

├── docs/
│   ├── narrative/
│   ├── level-design/
│   ├── art-bible/
│   └── technical/

├── scenes/
├── scripts/
├── assets/
├── audio/
├── ui/

└── _artwork/
```

## docs

所有策划和技术文档。

## scenes

Godot 场景。

## scripts

GDScript 代码。

## assets

已经确定进入游戏的正式图片、角色、场景、道具等素材。

## audio

BGM、音效、配音。

## ui

游戏 UI。

## _artwork

AI 原图、参考图、废稿、PSD 等工作过程文件。

---

# 👥 团队成员负责什么

| 成员 | 主要目录                        | 工作         |
| -- | --------------------------- | ---------- |
| 剧情 | `docs/narrative/`           | 故事、角色、对白   |
| 关卡 | `docs/level-design/`        | 关卡流程、交互、谜题 |
| 美术 | `assets/`、`docs/art-bible/` | 游戏素材、视觉规范  |
| 技术 | `scenes/`、`scripts/`、`ui/`  | Godot 实现   |

---

# ✍️ 剧情同学怎么提交

进入：

```text
docs/narrative/
```

文件：

```text
story.md
characters.md
dialogue.md
```

剧情文档直接使用 Markdown。

例如：

```text
docs/narrative/story.md
```

点击 GitHub 页面右上角的铅笔图标即可编辑。

修改完成后点击：

**Commit changes**

即可。

如果不确定怎么操作，先不要修改其他目录。

---

# 🧩 关卡同学怎么提交

进入：

```text
docs/level-design/
```

文件：

```text
level-flow.md
interaction-sheet.md
puzzle-design.md
```

关卡文档必须写清楚：

1. 玩家在哪里
2. 玩家看到什么
3. 玩家做什么
4. 什么条件触发
5. 触发之后发生什么
6. 玩家如何知道自己成功了

例如：

```text
玩家进入 MotherArea

↓

出现牵挂线

↓

玩家继续远离妈妈

↓

距离超过阈值

↓

牵挂线进入 Tense 状态

↓

触发母亲对白
```

---

# 🎨 美术同学怎么提交

正式进入游戏的素材：

```text
assets/
```

例如：

```text
assets/characters/mother_adult.png
assets/characters/daughter_adult.png
assets/props/yellow_umbrella.png
assets/environments/home_background.png
```

AI 原图、PSD、参考图、废稿：

```text
_artwork/
```

不要把大量废稿放进 `assets/`。

正式素材命名必须清楚。

推荐：

```text
mother_adult.png
mother_young.png
daughter_adult.png
daughter_child.png
yellow_umbrella.png
```

不要：

```text
IMG_001.png
最终.png
最终最终.png
真的最终.png
```

---

# 💻 技术同学怎么开发

技术同学负责：

```text
scenes/
scripts/
ui/
```

## 第一步：创建自己的 Branch

不要直接在 `main` 开发。

Branch 名称：

```text
feature/功能名称
```

例如：

```text
feature/player-movement
feature/tie-line
feature/level01
feature/dialogue
feature/camera
```

---

## 第二步：开发功能

例如你负责：

```text
feature/tie-line
```

那么这个 Branch 主要完成：

```text
Player
+
Mother
+
TieLine
```

让：

```text
玩家移动
↓
距离变化
↓
牵挂线跟随
↓
达到阈值
↓
触发事件
```

---

## 第三步：Commit

完成一个小功能以后提交一次。

Commit 写清楚做了什么：

```text
Add basic TieLine system
```

或者：

```text
Fix TieLine tension trigger
```

不要写：

```text
update
test
final
fix
```

---

## 第四步：Push

把自己的 Branch 上传到 GitHub。

例如：

```text
feature/tie-line
```

---

## 第五步：创建 Pull Request

创建：

```text
feature/tie-line → main
```

Pull Request 标题：

```text
[Feature] Add TieLine system
```

正文：

```markdown
## 做了什么

实现基础牵挂线。

## 怎么测试

进入 Level01，让玩家远离妈妈。

确认牵挂线会跟随距离变化。

## 注意事项

目前参数仍然是 Prototype 数值。
```

---

## 第六步：等待负责人检查

负责人检查 Pull Request。

如果需要修改：

继续在原来的 Branch 修改。

不需要重新创建 Pull Request。

修改完成以后再次 Push，原来的 Pull Request 会自动更新。

确认没问题以后：

**Merge**

进入：

```text
main
```

---

# 🚫 不允许直接修改 main

`main` 是当前稳定版本。

统一流程：

```text
main
 ↓
创建自己的 Branch
 ↓
开发
 ↓
Commit
 ↓
Push
 ↓
Pull Request
 ↓
检查
 ↓
Merge
 ↓
main
```

任何人都不要直接把未经检查的代码放进 `main`。

---

# 🔧 技术开发规则

### 1. 一个 Branch 尽量只做一个功能

例如：

```text
feature/tie-line
```

就主要做牵挂线。

不要同时重构 UI、改剧情、换场景。

### 2. 不要随便删除别人正在使用的文件

如果不确定：

先问。

### 3. 不要随便重命名资源

Godot 场景可能引用资源路径。

### 4. 每次提交前自己运行游戏

至少确认：

```text
游戏可以启动
没有明显报错
自己负责的功能正常
```

### 5. main 必须始终保持可运行

---

# 📝 文档规则

所有项目文档统一放：

```text
docs/
```

剧情：

```text
docs/narrative/
```

关卡：

```text
docs/level-design/
```

美术规范：

```text
docs/art-bible/
```

技术：

```text
docs/technical/
```

聊天群里的讨论不自动成为正式需求。

正式方案必须更新到文档。

---

# 🎯 当前开发目标

第一阶段不要追求完整游戏。

先完成：

```text
Player
↓
Mother
↓
TieLine
↓
Distance
↓
Tension
↓
Trigger
```

只要这条链能够运行，核心 Prototype 就成立。

---

# ⚠️ 项目纪律

当前已经进入锁方案阶段。

不要随意增加：

* 新核心玩法
* 新战斗系统
* 新养成系统
* 新复杂技能
* 新地图系统

如果有新想法：

先记录。

是否进入 Demo，由项目负责人决定。

---

# 一句话理解这个项目

> **策划负责写清楚要做什么，美术负责做出它长什么样，技术负责把它变成可以玩的游戏，GitHub 负责保存所有正式成果。**

## 技术 Pull Request 示例

标题示例：

```
[Feature] Add TieLine system
```

PR 正文模板：

### 做了什么
- 简短说明变更要点（1-3 行）。

### 怎么测试
1. 切到 `feature/add-pr-example` 分支
2. 打开 Godot，运行 `Level01` 场景
3. 验证：牵挂线能在玩家与母亲之间可见并在距离阈值触发事件

### 注意事项
- 参数为 Prototype 数值，后续需要调参
- 影响文件：`scripts/tie_line.gd`, `scenes/level01.tscn`

复审者请检查：性能（连接数上限）、资源路径是否破坏场景引用

- [ ] 已在本地运行且通过基本测试
- [ ] 没有直接改动 `main` 场景引用
