# Architecture (示例)

概述：Godot 3.x 项目。主要模块：Player、NPC、TieLine、LevelManager、DialogueSystem。

目录映射：
- scenes/: Godot 场景文件（单关一个文件夹）
- scripts/: GDScript 脚本按模块划分
- assets/: 正式素材

数据流简述：玩家输入 → Player 脚本更新位置 → TieLine 根据距离更新视觉与 tension → LevelManager 监听 tension 触发事件。

扩展点：将 TieLine 的阈值参数化为 Level 配置文件。

<!-- ponytail: 简洁架构图，详图由工程师补充 -->
