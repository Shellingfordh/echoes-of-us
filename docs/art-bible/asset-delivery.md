# 素材交付规范｜Asset Delivery

## 1. 目录

正式素材：

```text
assets/
├── characters/
├── environments/
├── props/
├── effects/
└── ui/
```

工作过程文件：

```text
_artwork/
├── ai/
├── source/
├── reference/
└── rejected/
```

正式 assets 不放：

- PSD；
- AI 原图；
- 草稿；
- 参考图；
- 废稿。

---

# 2. 命名规则

格式：

```text
category_subject_variant_state.ext
```

例如：

```text
character_mother_adult_idle.png
character_daughter_adult_walk.png
prop_yellow_umbrella.png
environment_home_background.png
effect_tieline_tense.png
```

全部使用：

> lowercase + underscore。

禁止：

```text
最终版.png
final2.png
IMG_1234.png
妈妈.png
```

---

# 3. 图片格式

默认：

> PNG。

有透明背景：

> 必须保留 Alpha。

背景图：

> 如果不需要透明，可以根据技术要求使用 PNG/JPG/WebP。

最终格式由技术根据运行性能确认。

---

# 4. 尺寸

默认最大边：

> 2048 px。

不要求所有素材都做成 2048。

原则：

> 使用满足视觉质量的最小合理尺寸。

例如小道具没有必要输出 2048×2048。

---

# 5. Sprite

角色 Sprite 必须注明：

- 单帧尺寸；
- 帧数；
- 动画速度；
- Pivot；
- 是否需要裁切。

例如：

```text
mother_walk
frames: 8
fps: 10
pivot: center-bottom
```

---

# 6. Pivot

角色默认：

> Center Bottom。

道具：

根据实际交互点设置。

例如雨伞：

> Pivot 可以设置在手柄或底部位置。

---

# 7. 九宫格

UI 如果使用 9-patch：

必须提供：

- patch margin；
- content margin；
- 最小尺寸；
- 锚点说明。

---

# 8. 动画交付

如果使用逐帧动画：

目录：

```text
assets/characters/mother/walk/
```

文件：

```text
walk_000.png
walk_001.png
...
```

如果技术使用 Sprite Sheet：

必须同时提供：

- Sheet；
- 帧数；
- 行列；
- FPS；
- Pivot。

---

# 9. 资产状态

统一：

```text
Todo
Doing
Review
Done
```

含义：

### Todo

尚未开始。

### Doing

制作中。

### Review

已提交，等待检查。

### Done

已通过并进入正式版本。

---

# 10. 交付说明

每个新资产至少说明：

```text
Asset ID:
Name:
Type:
Scene:
Source:
Size:
Transparent:
Animation:
Pivot:
Status:
Notes:
```

---

# 11. 版本管理

修改正式素材时：

不要直接提交：

```text
asset_final2.png
```

应保持同一资产 ID，并在 Git 中记录修改。

如果确实存在两个不同版本：

```text
v01
v02
```

版本信息用于开发阶段，不建议进入最终运行时文件名。

---

# 12. 验收标准

技术导入前检查：

- 文件可打开；
- Alpha 正常；
- 尺寸合理；
- 命名符合规则；
- 没有明显生成瑕疵；
- 与 Art Bible 一致；
- 不依赖原作者本地路径。
