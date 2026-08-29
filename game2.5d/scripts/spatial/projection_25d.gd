class_name Projection25D
extends RefCounted

## 固定等距投影：隐藏的 3D X/Z 地面坐标映射到可见的 2D Canvas。
## 只借鉴 Godot 3 Node25D 的三基向量公式，不依赖旧插件。

const ORIGIN := Vector2(1050.0, 170.0)
const AXIS_X := Vector2(64.0, 32.0)
const AXIS_Y := Vector2(0.0, -64.0)
const AXIS_Z := Vector2(-64.0, 32.0)

## 排序键的缩放。只影响 z_index 的粒度，不影响先后顺序。
const DEPTH_SCALE := 32.0

## 单个房间允许的排序键上限，约束房间尺寸 x + z <= 59 米。
## 留出余量让 BAND_WALL 叠加后仍落在 Godot 的 z_index 合法区间内。
const DEPTH_LIMIT := 1900

## 深度分层：贴在墙上的物件永远排在地面物件之后。
## 地面层的排序键 >= 0，所以 BAND_WALL 必须比 -DEPTH_LIMIT 更负，
## 才能保证「最靠前的墙面物件」仍排在「最靠后的地面物件」之后；
## 背景 Node2D 的 z_index = -4000 则兜住整个墙面层。
const BAND_WALL := -2000


static func project(spatial_position: Vector3) -> Vector2:
	return (
		ORIGIN
		+ spatial_position.x * AXIS_X
		+ spatial_position.y * AXIS_Y
		+ spatial_position.z * AXIS_Z
	)


static func project_direction(spatial_direction: Vector3) -> Vector2:
	return (
		spatial_direction.x * AXIS_X
		+ spatial_direction.y * AXIS_Y
		+ spatial_direction.z * AXIS_Z
	)


## 画家算法的排序键只能来自地面深度 x + z。
## 高度 y 必须完全不参与：柜顶的相框和柜子本身站在同一格地面上，
## 它们的先后由 depth_offset 决定，而不是由谁更高决定。
static func depth_index(spatial_position: Vector3) -> int:
	var ground_depth := DEPTH_SCALE * (spatial_position.x + spatial_position.z)
	return clampi(int(roundf(ground_depth)), -DEPTH_LIMIT, DEPTH_LIMIT)


## project() 在 y = 0 平面上的逆运算：屏幕坐标还原成地面逻辑坐标。
## 推导：a = px - ORIGIN.x = 64(x - z)，b = py - ORIGIN.y = 32(x + z)。
## 用于读取编辑器里手摆的 Node2D 位置，避免在脚本里重复写死坐标。
static func unproject_ground(screen_position: Vector2) -> Vector3:
	var a := (screen_position.x - ORIGIN.x) / AXIS_X.x
	var b := (screen_position.y - ORIGIN.y) / AXIS_X.y
	return Vector3((a + b) * 0.5, 0.0, (b - a) * 0.5)


static func ground_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
