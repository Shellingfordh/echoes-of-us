# 对白设计与对白表｜Dialogue

## 1. 对白原则

《不断线》的对白承担三类功能：

1. 建立母女关系；
2. 推进玩家理解；
3. 在关键节点提供情绪落点。

对白不承担教程 UI 的全部功能。

玩家应该首先通过画面和行为理解机制，再通过对白获得情绪确认。

## 2. 统一字段

每条对白必须包含：

| 字段 | 说明 |
|---|---|
| ID | 唯一对白 ID |
| Scene | 所属场景 |
| Trigger | 触发条件 |
| Speaker | 说话角色 |
| Text | 正式文本 |
| Emotion | 情绪 |
| Blocking | 是否阻塞玩家 |
| Duration | 预计时长 |
| Voice | 是否需要语音 |
| Priority | 优先级 |
| Notes | 演出备注 |

ID 一旦进入技术实现，不应随意修改。

---

# 3. 开场对白

## D001

**Scene:** L01_Home

**Trigger:** 游戏开始

**Speaker:** Mother

**Text:**

> “东西都带了吗？”

**Emotion:** 自然、习惯性关心

**Blocking:** No

**Duration:** 2.0s

**Voice:** Optional

**演出：**

母亲不需要正面面对玩家。

可以一边整理物品一边说。

---

## D002

**Trigger:** 女儿开始移动

**Speaker:** Daughter

**Text:**

> “带了。”

**Emotion:** 平静，略微敷衍

**Blocking:** No

**Duration:** 1.0s

---

## D003

**Trigger:** 女儿移动一段距离

**Speaker:** Mother

**Text:**

> “慢一点。”

**Emotion:** 温柔、下意识

**Blocking:** No

**Duration:** 1.2s

---

# 4. 第一次看到牵挂线

## D010

**Trigger:** 玩家第一次满足 TieLine Reveal 条件

**Speaker:** Daughter

**Text:**

> “……这是什么？”

**Emotion:** 好奇、疑惑

**Blocking:** No

**Duration:** 1.5s

**演出要求：**

不要马上解释。

让玩家看到线、观察线的运动。

---

## D011

**Trigger:** 女儿观察牵挂线

**Speaker:** Mother

**Text:**

> “你看得见？”

**Emotion:** 意外，但并不恐惧

**Blocking:** No

**Duration:** 1.5s

**叙事目的：**

第一次暗示：

> 这根线不是所有人都能看到。

---

# 5. 第一次张力

## D020

**Trigger:** 距离达到 Tense 阈值

**Speaker:** Mother

**Text:**

> “别走太远。”

**Emotion:** 下意识担心

**Blocking:** No

**Duration:** 1.5s

---

## D021

**Trigger:** 玩家继续远离

**Speaker:** Daughter

**Text:**

> “我就在这儿。”

**Emotion:** 温和但带一点不耐烦

**Blocking:** No

**Duration:** 1.5s

---

# 6. 核心谜题

## D030

**Trigger:** 玩家第一次连接错误

**Speaker:** Daughter

**Text:**

> “不对……”

**Emotion:** 思考

**Blocking:** No

**Duration:** 0.8s

不应出现“你做错了”的系统式表达。

---

## D031

**Trigger:** 玩家第一次正确连接

**Speaker:** Daughter

**Text:**

> “原来是这样。”

**Emotion:** 理解

**Blocking:** No

**Duration:** 1.0s

---

# 7. 黄色雨伞

## D040

**Trigger:** 玩家进入黄色雨伞交互范围

**Speaker:** Daughter

**Text:**

> “这把伞……”

**Emotion:** 突然想起什么

**Blocking:** Yes

**Duration:** 1.2s

---

## D041

**Trigger:** 玩家完成黄色雨伞交互

**Speaker:** Mother

**Text:**

> “你小时候总喜欢走在雨里。”

**Emotion:** 怀念

**Blocking:** Yes

**Duration:** 2.5s

---

## D042

**Trigger:** 记忆转场开始

**Speaker:** Daughter

**Text:**

> “你那时候总跟着我。”

**Emotion:** 怀念、轻微自嘲

**Blocking:** Yes

**Duration:** 2.2s

---

# 8. 童年记忆

童年场景原则上减少对白。

环境声音承担主要叙事功能：

- 雨声；
- 伞面雨滴；
- 脚步；
- 衣物摩擦；
- 远处环境声。

必要对白：

## D050

**Speaker:** Mother_Young

**Text:**

> “伞往这边一点。”

**Emotion:** 温柔

**Duration:** 1.5s

---

## D051

**Speaker:** Child_Daughter

**Text:**

> “我看得见。”

**Emotion:** 活泼

**Duration:** 1.0s

---

# 9. 结尾

## D060

**Trigger:** 回到现实

**Speaker:** Mother

**Text:**

> “去吧。”

**Emotion:** 平静

**Blocking:** Yes

**Duration:** 1.0s

这是结尾最重要的台词之一。

不要加入：

> “妈妈永远爱你。”

因为画面已经表达了这一层含义。

---

## D061

**Trigger:** 女儿继续向前

**Speaker:** Daughter

**Text:**

> “嗯。”

**Emotion:** 释然

**Blocking:** No

**Duration:** 0.6s

---

# 10. 对白演出规范

## 语气

避免：

- 广播剧式朗诵；
- 过度哭腔；
- 过度煽情；
- 每句话都强调情绪。

应该接近日常说话。

## 停顿

关键情绪节点允许保留：

> 0.5～2 秒的空白。

沉默本身是对白设计的一部分。

## 文本长度

普通对白建议：

> 5～15 个中文字符。

情绪演出对白：

> 15～30 个中文字符。

超过 30 字需要确认是否真的必要。

## 修改规则

如果剧情修改对白：

1. 保持 ID 不变；
2. 更新 Text；
3. 更新 Duration；
4. 如果改变触发条件，同步通知关卡和技术。

---

# 11. 完成标准

玩家关闭所有 UI 后，仅通过：

> 角色动作 + 环境 + 少量对白

仍然能够理解母女关系的变化。

如果必须依赖大量文字解释剧情，则说明对白和视觉叙事之间的分工需要重新调整。
