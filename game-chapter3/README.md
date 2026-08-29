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
- 复用前两章的人物、黄伞、行李和木箱素材，并补齐楼道声控灯、信箱、仓库货架、天台水箱与晾晒物等场景表现；
- 不依赖新生成素材。

## 运行

```bash
godot --path game-chapter3
```

操作：`A/D` 或左右方向键移动，`Space/W/↑` 跳跃，空中按住 `W/↑` 爬线（空格不会误触攀线），`Tab` 切换角色，`E` 锚定/松开，`R` 返回最近检查点，`F3` 显示调试信息。

## 验证

```bash
godot --headless --path game-chapter3 --script res://tests/chapter03_flow_test.gd
godot --headless --path game-chapter3 --script res://tests/chapter03_input_test.gd
```

需要生成四张白盒检查图时，可运行：

```bash
godot --path game-chapter3 --script res://tests/capture_chapter3.gd
```
