# 《余响：牵挂》第三章 2D 工程

`game-chapter3/` 从 `game2.5d/` 派生，但启动场景已切换为独立的第三章横版 2D 实现。原有第一、二章文件保留用于复用字体、输入、对话和项目配置；本工程不会修改 `game2.5d/` 的主场景。

玩法与关卡结构参考 `docs/narrative/chapter3demo4.html`（Prototype v0.4）；HTML 不作为人物、场景或剧情成品依据。第三章的余念、余秀兰、黄伞、行李与红线延续第一、二章，视觉采用当下时空的冷灰蓝，具体叙事与环境依据仓库内最新剧情流程和美术设定。

## 已实现

- 三关连续流程：楼道与出口、仓库、天台；
- 女儿/母亲双角色与 `Tab` 控制切换；
- 松弛、张力、极限张力与牵挂线距离约束；
- `E` 锚定、锚定水平借跳、`W` 沿线攀爬；
- 母亲推动重箱、女儿通过低矮通道；
- 断裂木板、高低平台、箱子垫脚、双踏板闩锁门；
- 分段检查点、坠落恢复、关卡完成横幅与第三章寄语结尾；
- 复用前两章的人物、黄伞、行李和木箱素材，并补齐楼道声控灯、信箱、仓库货架与天台水箱等场景表现；
- 27 张第三章候选素材已归档到工程自己的 `game-chapter3/assets/`，其中 10 张用于运行时画面；不依赖工程目录之外的素材或软链接；
- 仓库新增四张服装设计稿和一组布料架，强化余秀兰的纺织职业经历；原有高噪声货架已停止渲染；
- 暖色楼道窗、圆管低洞、第二个高架水箱和两张旧货架因不符合当前场景或会误导玩法而停用，原文件只保留作候选参考；
- 天台不再使用晾衣绳、床单或晾晒衣物，场景节点、候选素材和整景背景中的对应元素均已移除；
- 天台整景背景已基于现有构图清理晾衣元素；现有候选图及处理后背景仍需在正式发行前补齐来源与授权。

## 场景结构

第三章不再是只有一个脚本节点的空场景。`scenes/chapter3/chapter3.tscn` 中可以直接查看双角色、碰撞形状、牵挂线、HUD 和第一关布局预览；三个关卡布局分别位于：

- `scenes/chapter3/levels/chapter3_stairwell.tscn`
- `scenes/chapter3/levels/chapter3_warehouse.tscn`
- `scenes/chapter3/levels/chapter3_rooftop.tscn`

平台和门使用 `StaticBody2D`，箱子使用 `CharacterBody2D`，踏板与出口触发区使用 `Area2D`，出生点、检查点和出口坐标使用 `Marker2D`。运行时不仅从这些场景节点读取玩法数据，还会挂载当前关卡并同步箱子、木板、踏板和门的状态，因此可以在 Godot 编辑器中直接调整布局并看到一致的运行结果。

## 运行

```bash
godot --path game-chapter3
```

操作：`A/D` 或左右方向键移动，`Space` 跳跃，空中按住 `W/↑` 爬线，`Tab` 切换角色，`E` 锚定/松开，`R` 返回最近检查点，`F3` 显示调试信息。

## 验证

新检出工程或新增/移动素材后，先让 Godot 生成资源导入缓存：

```bash
godot --headless --editor --path game-chapter3 --quit
```

然后执行回归：

```bash
godot --headless --path game-chapter3 --script res://tests/chapter03_flow_test.gd
godot --headless --path game-chapter3 --script res://tests/chapter03_input_test.gd
godot --headless --path game-chapter3 --script res://tests/chapter03_scene_structure_test.gd
godot --headless --path game-chapter3 --script res://tests/chapter03_door_rules_test.gd
godot --headless --path game-chapter3 --script res://tests/chapter03_playability_test.gd
godot --headless --path game-chapter3 --script res://tests/chapter03_asset_integration_test.gd
```

需要生成四张白盒检查图时，可运行：

```bash
godot --path game-chapter3 --script res://tests/capture_chapter3.gd
```
