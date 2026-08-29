# 第三章现有素材接入清单

第三章的 29 张候选 PNG 已复制或处理后保存到 `game-chapter3/assets/`，并使用英文资源名。Godot 通过当前工程内的 `res://assets/...` 直接访问，不依赖个人 Downloads 路径、仓库根素材目录或外部软链接。当前 11 张用于游戏画面，18 张仅保留为候选参考。原有 3 张楼梯/断梯图片因透视、比例和现有关卡结构不匹配，已从工程整体移除。

## 当前使用范围

| 原文件 | 仓库文件 | 运行时用途 |
|---|---|---|
| 用户提供的楼道整景图 | `environments/chapter3/stairwell/environment_ch03_stairwell_full_scene.png` | 第一关完整背景；以原始尺寸沿世界横向重复，保持随镜头滚动 |
| `wall.png` | `environments/chapter3/stairwell/environment_ch03_stairwell_wall.png` | 候选参考；已由楼道整景图替换 |
| 用户提供的地下储藏层图 | `environments/chapter3/stairwell/environment_ch03_stairwell_underfloor_storage.png` | 候选参考；已合并到楼道整景图方案 |
| `light.png` | `props/chapter3/prop_ch03_stairwell_lamp.png` | 候选参考；整景图已包含环境灯光 |
| `v.png` | `props/chapter3/platforms/prop_ch03_wood_floor_repeat.png` | 三关长路面与大型平台的连续木板结构 |
| `a.png` | `props/chapter3/platforms/prop_ch03_wood_platform_long.png` | 中型悬空木平台与短路面 |
| `w.png` | `props/chapter3/platforms/prop_ch03_wood_platform_bracket.png` | 窄平台与台阶的木质斜撑结构 |
| 用户提供的抬起踏板图 | `props/chapter3/plates/prop_ch03_pressure_plate_raised.png` | 未触发踏板状态；透明背景游戏贴图 |
| 用户提供的压下踏板图 | `props/chapter3/plates/prop_ch03_pressure_plate_pressed.png` | 已触发踏板状态；透明背景游戏贴图 |
| `door2.png` | `props/chapter3/doors/prop_ch03_mechanism_door_closed.png` | 第一、二关机关门关闭状态；踏板触发后节点与碰撞同时消失 |
| `window.png` | `props/chapter3/prop_ch03_stairwell_window.png` | 候选参考；暖夕照与当前冷灰蓝楼道冲突，运行时停用 |
| 用户提供的纺织仓库整景图 | `environments/chapter3/warehouse/environment_ch03_warehouse_full_scene.png` | 第二关完整背景；以原始尺寸沿世界横向重复，保持随镜头滚动 |
| `factory-background.png` | `environments/chapter3/warehouse/environment_ch03_warehouse_background.png` | 候选参考；已由纺织仓库整景图替换 |
| `daughter-pipe.png` | `environments/chapter3/warehouse/environment_ch03_warehouse_low_tunnel.png` | 候选参考；圆管剖面不能替代仓库梁下低洞，运行时停用 |
| `shelf.png` | `props/chapter3/prop_ch03_warehouse_shelf_wide.png` | 候选参考；细节过密且重复感明显，已由布料架替换 |
| `shelf-2.png` | `props/chapter3/prop_ch03_warehouse_shelf_narrow.png` | 候选参考；细节过密且重复感明显，已由布料架替换 |
| `wooden-box.png` | `props/chapter3/prop_ch03_warehouse_heavy_crate.png` | 两个可推动重箱 |
| 用户提供的天台整景图 | `environments/chapter3/rooftop/environment_ch03_rooftop_full_scene.png` | 第三关完整背景；以原始尺寸沿世界横向重复，保持随镜头滚动 |
| `sky.png` | `environments/chapter3/rooftop/environment_ch03_rooftop_sky.png` | 候选参考；已由天台整景图替换 |
| `rooftop-entrance.png` | `environments/chapter3/rooftop/environment_ch03_rooftop_entrance.png` | 候选参考；整景图已包含入口和水箱 |
| `hanging-clothes.png` | `environments/chapter3/rooftop/environment_ch03_rooftop_hanging_clothes.png` | 候选参考；整张构图遮挡人物与牵挂线，拆件前停用 |
| `water-tank-1.png` | `props/chapter3/prop_ch03_rooftop_water_tank_low.png` | 候选参考；整景图已包含水箱 |
| `water-tank-2.png` | `props/chapter3/prop_ch03_rooftop_water_tank_high.png` | 候选参考；会误导为可攀爬平台，运行时停用 |
| `big-iron-gate.png` | `props/chapter3/prop_ch03_rooftop_exit_gate.png` | 天台终门视觉层 |
| `1.png` | `props/chapter3/warehouse/prop_ch03_warehouse_pattern_changshan.png` | 候选参考；整景图已包含服装设计语义 |
| `3.png` | `props/chapter3/warehouse/prop_ch03_warehouse_pattern_qipao.png` | 候选参考；整景图已包含服装设计语义 |
| `5.png` | `props/chapter3/warehouse/prop_ch03_warehouse_pattern_shirt.png` | 候选参考；整景图已包含服装设计语义 |
| `7.png` | `props/chapter3/warehouse/prop_ch03_warehouse_pattern_skirt.png` | 候选参考；整景图已包含服装设计语义 |
| `架子.png` | `props/chapter3/warehouse/prop_ch03_warehouse_fabric_rack.png` | 候选参考；整景图已包含布料架与布卷 |

## 使用限制

- 当前定位为内部原型素材，不能据此认定已经取得正式发行授权。
- 原文件未发现作者、来源和许可记录；对外演示或发布前必须补齐，或替换为项目自有素材。
- Godot 中使用冷灰蓝调制和受控透明度，碰撞仍由 `.tscn` 关卡节点定义，图片透明轮廓不参与碰撞计算。
- 标记为“运行时停用”的文件仍保留在当前工程候选素材库，后续完成拆件、调色或碰撞匹配后才能重新接入。
- `._*.png` 是 macOS AppleDouble 元数据，没有复制进仓库。
