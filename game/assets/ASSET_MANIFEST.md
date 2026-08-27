# 首轮水彩素材清单

生成日期：2026-08-27

生成方式：Codex 内置图像生成（以 `_artwork/reference/character_style_anchor.png` 为统一视觉锚点）

当前状态：`Review`，已进入可玩工程，仍建议在正式发行前由美术做角色动作、细节修形与最终调色。

## 运行时素材

| Asset ID | 场景 / 用途 | 尺寸 | Alpha | Pivot | 状态 |
|---|---|---:|---|---|---|
| `character_daughter_adult_neutral` | 成年女儿，玩家/同伴 | 512×768 | 是 | Center Bottom | Review |
| `character_mother_adult_neutral` | 成年母亲，玩家/同伴 | 512×768 | 是 | Center Bottom | Review |
| `character_mother_young_neutral` | 年轻母亲，第二幕 | 512×768 | 是 | Center Bottom | Review |
| `character_daughter_child_neutral` | 小女儿，第二幕 | 512×768 | 是 | Center Bottom | Review |
| `environment_prologue_sewing_shop` | 序章，旧城缝纫铺 | 1600×720 | 否 | Full Frame | Review |
| `environment_home` | 第一幕，童年旧家 | 1600×720 | 否 | Full Frame | Review |
| `environment_memory_street` | 第二幕，雨中记忆街道 | 1600×720 | 否 | Full Frame | Review |
| `environment_corridor` | 第三幕，公寓楼道 | 1600×720 | 否 | Full Frame | Review |
| `environment_warehouse` | 第三幕，旧仓库 | 1600×720 | 否 | Full Frame | Review |
| `environment_rooftop` | 第三幕，夜晚天台 | 1600×720 | 否 | Full Frame | Review |
| `environment_apartment` | 第四幕 / 尾声，新住处 | 1600×720 | 否 | Full Frame | Review |
| `prop_yellow_umbrella` | 第一幕记忆 / 尾声关键道具 | 493×512 | 是 | Center | Review |
| `prop_moving_box` | 第一、四幕，可调查/推动纸箱 | 512×378 | 是 | Center Bottom | Review |
| `prop_suitcase` | 第一幕，可调查行李箱 | 512×335 | 是 | Center Bottom | Review |
| `prop_bicycle` | 第二幕，可推动自行车 | 512×379 | 是 | Center Bottom | Review |
| `prop_warehouse_crate` | 第三幕，可推动仓库木箱 | 512×451 | 是 | Center Bottom | Review |

角色均为单帧静态立绘；当前移动反馈仍由 Godot 节点位移、呼吸偏移和交互光环完成。环境图由 1672×941 源图居中裁切为运行时横幅。透明角色与道具已检查真实 Alpha 通道。

## 源文件

- 角色风格锚点：`_artwork/reference/character_style_anchor.png`
- 角色透明源图：`_artwork/source/character_*_transparent.png`
- 场景高分辨率源图：`_artwork/source/environment_*_full.png`
- 黄伞透明源图：`_artwork/source/prop_yellow_umbrella_transparent.png`

`_artwork/` 保存可继续修图的生成源；`game/assets/` 只保存运行时版本。

## 最终生成提示词组

所有提示词共享以下风格约束：安静的东亚绘本水彩与水粉、细铅笔轮廓、手工纸张肌理、克制怀旧色板、柔和边缘变化、无文字/标志/水印，并以角色风格锚点保持人物比例、色彩和笔触一致。

- 风格锚点：四人全身角色设定排布——成年女儿、成年母亲、年轻母亲、小女儿；正面、克制中性表情、清楚分离、统一比例与服装连续性。
- 成年女儿：单人全身中性站姿，深蓝灰针织上衣、米白长裤、低马尾，独立透明背景。
- 成年母亲：单人全身中性站姿，锈红开衫、深色长裤、短发，独立透明背景。
- 年轻母亲：单人全身中性站姿，柔和砖红衬衣、深色长裤、束发，独立透明背景。
- 小女儿：单人全身中性站姿，芥末黄色雨衣、深色短裤与雨靴，独立透明背景。
- 序章场景：旧城缝纫铺横向剖面，楼下工作台与缝纫机、楼上安静卧室，傍晚暖灯，无人物。
- 旧家场景：稍显空荡的童年旧家，床、衣柜、书桌、玄关和未收完的纸箱，傍晚冷暖交界，无人物。
- 记忆街道：雨中的旧城区街道，湿路反光、水洼、路灯、快递柜与施工断口，无人物。
- 楼道场景：老公寓长楼道，多扇门、顶灯、转折空间，蓝灰冷色，无人物。
- 仓库场景：旧仓库内部，木箱、钢梁、窄通道和尘埃光束，暗暖色，无人物。
- 天台场景：城市夜色中的公寓天台，逐级平台、远处楼群与稀疏星光，无人物。
- 新住处：尚未完全整理的新公寓，纸箱、书桌、书架、窗与门口，清晨暖灰光，无人物。
- 黄伞：一把完全撑开的旧芥末黄色折伞，正面三分之四视角，轻微磨损、深色细伞骨、暖棕弯木柄，完整居中，真实透明背景。
- 搬家纸箱：暖棕瓦楞纸箱、封闭折盖、单条无字纸胶带、轻微磨角，正面三分之四视角，真实透明背景。
- 行李箱：旧蓝灰硬壳行李箱、短提手、柔化金属包角与细微刮痕，正面三分之四视角，真实透明背景。
- 自行车：旧式实用城市自行车、炭灰车架、棕色车座与车把、细轮和小前篮，侧面三分之四视角，真实透明背景。
- 仓库木箱：暗蜂蜜棕木板、正面交叉加固条、磨损木纹和圆钝边角，正面三分之四视角，真实透明背景。

禁止项统一为：人物场景中不出现额外角色；透明素材不出现棋盘格、地面、投影或背景；任何素材都不出现文字、边框、Logo 与水印。
