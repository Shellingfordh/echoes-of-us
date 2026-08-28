# 第一章等距 2.5D 主体工程

本目录从 `main` 分支的 `game2.5d` 复制而来，保留原工程作为对照，当前副本负责实现最新剧情文档中的第一章完整主体玩法。

## 已实现

- 等距 2D 画面与隐藏 3D `CharacterBody3D` / `StaticBody3D` 碰撞；
- 五件主调查、P1/P2/P3 阶段切换与 D001-D018、D041-D047 对话数据；
- 木凳解锁柜顶相框；
- 窗玻璃、床底耳机、柜顶相框的固定观察；
- 黄伞冲突、行李箱二次调查与普通线状物显色；
- 距离、情绪压力、离开意图共同决定的牵挂线张力；
- 第一次强制回弹；
- 第二次承重、悬挂和有限摆动；
- 触碰黄伞后越过余响阈值，完成第一章。

## 运行

```bash
godot --path chapter1-game2.5d
```

移动使用 WASD / 方向键，Enter 或空格调查，Esc 退出固定观察，F3 显示调试信息。

## 验证

```bash
godot --headless --path chapter1-game2.5d --script res://tests/smoke_25d.gd
godot --headless --path chapter1-game2.5d --script res://tests/chapter01_flow_test.gd
```

## 素材状态

当前没有生成新素材。`art/` 来自 `main:game2.5d` 的原型占位资源；在来源与授权确认前，仅用于内部开发验证，不作为正式发行素材。
