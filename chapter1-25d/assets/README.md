# 素材接口

当前阶段按要求只完成主体游戏，画面使用 Godot 原生 3D Mesh 与程序化材质。

后续正式素材按以下槽位替换，不改变玩法代码：

- `characters/daughter_adult.png`：成年余念，透明背景，Center Bottom Pivot。
- `characters/mother_adult.png`：余秀兰，透明背景，Center Bottom Pivot。
- `props/yellow_umbrella.png`：黄色猫咪旧雨伞。
- `environments/home_*.png`：可选的远景、中景与前景绘本纹理。
- `effects/tie_line_*.png`：可选的牵挂线噪声或辉光纹理。

程序化实现本身保持完整可玩，不依赖上述图片存在。
