# 对白入口｜Dialogue Source

正式对白接口文档：

> [`03_剧情对白表.md`](./03_剧情对白表.md)

Godot 运行时数据：

> [`game2.5d/data/dialogues.json`](../../game2.5d/data/dialogues.json)

## 同步规则

1. `D001`–`D040` 是稳定 ID，不因润色或演出节奏调整而重排；
2. 正式台词先在 `03_剧情对白表.md` 中确认，再同步到 `game2.5d/data/dialogues.json`；
3. 玩法代码只引用 ID，不直接写正式台词；
4. `M`、`E`、`A`、`W` 前缀分别用于记忆碎片、环境回响、关卡补充和世界事件；
5. 旧版对白提案保存在 [`dialogue-legacy.md`](./dialogue-legacy.md)，仅供追溯，不再作为实现依据。
