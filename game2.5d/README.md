# 《余响：牵挂》Godot 游戏主工程

`game2.5d/` 是仓库当前正式 Godot 主工程目录，统一承载第一、二、三章的剧情、玩法、关卡和运行素材。工程使用 Godot 4.7；第一、二章采用 2.5D 等距表现，第三章按设计采用独立的 2D 横版关卡。

游戏默认从 `scenes/main/main.tscn` 的第一章开始，完成后依次进入第二章和第三章。`GameSession` 自动加载节点负责在场景切换时保存当前章节、已完成章节和跨章剧情标记。

## 章节状态

### 第一章 · 离家

- 五件主调查与 P1/P2/P3 顺序流程；
- 家具实体碰撞、推动木凳、站上木凳调查相框；
- 黄伞冲突、牵挂线显形、两次离门回弹和余响转场；
- 完成后自动进入第二章。

### 第二章 · 2009 年秋

- 三个大型 Block、六段顺序教学；
- 自行车、水坑、窄缝切换、断板承重、沿线爬回、路灯锚定与学校终点；
- 完成后显示“按 Enter / Space 继续第三章”，由玩家确认进入第三章。

### 第三章 · 双人牵挂

- 三个独立 2D 关卡：楼道、仓库、天台；
- 双角色切换、锚定、借力跳跃、沿线攀爬、推动箱子与双踏板机关；
- 门和闸门具有真实阻挡与解锁条件；
- 使用项目内三张完整场景背景和 11 个实际运行素材，不依赖 `game-chapter3/` 或个人下载目录。
- 天台通关后先播放剧情收束文案，再自动进入带声音的“余响：牵挂”片尾动画；Enter / Space 可跳过或重播，R 重新开始。

## 运行

```bash
godot --path game2.5d
```

第一、二章使用 WASD / 方向键移动，Enter 或空格调查，F3 显示调试信息。第三章使用 A/D 或左右键移动、Space 跳跃、W/上键在空中沿线攀爬、Tab 切换角色、E 锚定、R 返回检查点、F3 显示调试信息。

## 验证

```bash
godot --headless --path game2.5d --script res://tests/smoke_25d.gd
godot --headless --path game2.5d --script res://tests/chapter01_flow_test.gd
godot --headless --path game2.5d --script res://tests/chapter01_portrait_test.gd
godot --headless --path game2.5d --script res://tests/chapter02_flow_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_scene_structure_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_asset_integration_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_input_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_door_rules_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_playability_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_flow_test.gd
godot --headless --path game2.5d --script res://tests/chapter03_ending_test.gd
godot --headless --path game2.5d --script res://tests/game_session_test.gd
godot --headless --path game2.5d --script res://tests/chapter_progression_test.gd
```

## 素材目录

- `art/`：三章共享人物、立绘、字体、UI、第一/二章场景素材与最终片尾视频；
- `assets/environments/chapter3/`：第三章三张完整场景背景；
- `assets/props/chapter3/`：第三章机关门、踏板、木质平台、箱子和出口素材。

正式发行、演示交付或对外分发前，仍需确认所有素材的来源与授权信息。
