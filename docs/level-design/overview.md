# 概览：基于新剧情《余响：牵挂》的关卡重设计

## 完成内容

基于用户提供的最新剧情文档（01_剧情总纲、02_剧情流程），对 `echoes-of-us` 项目的 Level 01 进行了全面重设计。

### 核心变化

| 维度 | 旧版（基于仓库原始剧情） | 新版（基于 v0.2 剧情） |
|------|--------------------------|------------------------|
| 关卡结构 | 单关卡 17 节点 | 四幕 10 节点 + 3 过渡 |
| 牵挂线系统 | 五态（Hidden→Faint→Visible→Tense→Critical） | 四态（Hidden→Tense→Adjustable→Extending） |
| 核心机制 | 连接谜题（A→B→C） | 线控制 + 锚点系统 + 视角切换 |
| 谜题设计 | 1 个核心谜题（5 对象连接） | 3 个递进式谜题（探索→操作→应用） |
| 交互类型 | 7 种 | 10 种（新增线控制/锚点/线安放/为他人的连接） |
| 玩家视角 | 单一（成年女儿） | 双视角（成年女儿 + 记忆中的年轻母亲） |

### 四幕结构

1. **Act 1: 离家** — 牵挂是束缚（房间探索 → 线显现 → 被拉回）
2. **Act 2: 第一次放手** — 牵挂可以调整（进入记忆 → 视角切换为母亲 → 控制线/锚点教学）
3. **Act 3: 外面的世界** — 牵挂属于世界（回到现实 → 安放线 → 为路人寻物）
4. **Act 4: 向外跑** — 牵挂允许远行（奔跑 → 线不断延长 → 余响）

### 修改的文件（4 个）

| 文件 | 行数变化 | 核心内容 |
|------|----------|----------|
| `level-redesign-proposal.md` | 全部重写 | 四幕总纲、五维度优化、玩家体验路径 |
| `level-flow.md` | 全部重写 | 10 节点流程定义、3 过渡空间、节奏控制表 |
| `interaction-sheet.md` | 全部重写 | 10 种交互类型、锚点系统、环境响应、三层引导 |
| `puzzle-design.md` | 全部重写 | 3 个递进式谜题（P001 房间探索/P002 记忆操作/P003 路人寻物） |

### 提交信息

- 分支：`level-redesign`
- Commit：`dbed8ea` — "Redesign levels based on v0.2 story docs"
- 状态：已提交到本地，未推送（用户自行推送）

### 推送命令

```bash
cd "C:\Users\MECHREVO\WorkBuddy\关卡设计\echoes-of-us"
git push -u origin level-redesign
```

推送后在 GitHub 创建 Pull Request：
- **标题**: `[Level Design] Redesign Level 01 based on v0.2 story`
- **Base**: `main` ← **Head**: `level-redesign`
