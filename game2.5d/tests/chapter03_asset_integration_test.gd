extends SceneTree

const ASSET_PATHS: Array[String] = [
	"res://assets/environments/chapter3/stairwell/environment_ch03_stairwell_full_scene.png",
	"res://assets/environments/chapter3/warehouse/environment_ch03_warehouse_full_scene.png",
	"res://assets/props/chapter3/prop_ch03_warehouse_heavy_crate.png",
	"res://assets/environments/chapter3/rooftop/environment_ch03_rooftop_full_scene.png",
	"res://assets/props/chapter3/platforms/prop_ch03_wood_floor_repeat.png",
	"res://assets/props/chapter3/platforms/prop_ch03_wood_platform_long.png",
	"res://assets/props/chapter3/platforms/prop_ch03_wood_platform_bracket.png",
	"res://assets/props/chapter3/plates/prop_ch03_pressure_plate_raised.png",
	"res://assets/props/chapter3/plates/prop_ch03_pressure_plate_pressed.png",
	"res://assets/props/chapter3/doors/prop_ch03_mechanism_door_closed.png",
]

const RUNTIME_REJECTED_ASSETS: Array[String] = [
	"environment_ch03_stairwell_wall.png",
	"environment_ch03_stairwell_underfloor_storage.png",
	"prop_ch03_stairwell_lamp.png",
	"environment_ch03_warehouse_background.png",
	"prop_ch03_warehouse_fabric_rack.png",
	"prop_ch03_warehouse_pattern_changshan.png",
	"prop_ch03_warehouse_pattern_qipao.png",
	"prop_ch03_warehouse_pattern_shirt.png",
	"prop_ch03_warehouse_pattern_skirt.png",
	"environment_ch03_rooftop_sky.png",
	"environment_ch03_rooftop_entrance.png",
	"prop_ch03_rooftop_water_tank_low.png",
	"environment_ch03_stairwell_broken_stairs.png",
	"environment_ch03_stairwell_stairs.png",
	"environment_ch03_stairwell_stairs_landing.png",
	"prop_ch03_stairwell_window.png",
	"environment_ch03_warehouse_low_tunnel.png",
	"prop_ch03_rooftop_water_tank_high.png",
	"prop_ch03_rooftop_exit_gate.png",
	"prop_ch03_warehouse_shelf_wide.png",
	"prop_ch03_warehouse_shelf_narrow.png",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for asset_path in ASSET_PATHS:
		assert(ResourceLoader.exists(asset_path), "第三章素材未进入 Godot 资源路径：%s" % asset_path)
		var texture := load(asset_path) as Texture2D
		assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "第三章素材无法作为 Texture2D 加载：%s" % asset_path)

	var chapter_script := FileAccess.get_file_as_string("res://scripts/chapter3/chapter3.gd")
	var layout_item_script := FileAccess.get_file_as_string("res://scripts/chapter3/chapter3_layout_item.gd")
	var rooftop_scene := FileAccess.get_file_as_string("res://scenes/chapter3/levels/chapter3_rooftop.tscn")
	assert(not chapter_script.contains("/Users/allen/Downloads"), "运行时不能依赖个人 Downloads 路径")
	assert(not layout_item_script.contains("/Users/allen/Downloads"), "关卡组件不能依赖个人 Downloads 路径")
	assert(chapter_script.contains("res://assets/environments/chapter3/stairwell/"))
	assert(chapter_script.contains("environment_ch03_stairwell_full_scene.png"))
	assert(chapter_script.contains("res://assets/environments/chapter3/warehouse/"))
	assert(chapter_script.contains("environment_ch03_warehouse_full_scene.png"))
	assert(chapter_script.contains("res://assets/environments/chapter3/rooftop/"))
	assert(chapter_script.contains("environment_ch03_rooftop_full_scene.png"))
	assert(chapter_script.contains("res://assets/props/chapter3/prop_ch03_warehouse_heavy_crate.png"))
	assert(layout_item_script.contains("prop_ch03_wood_floor_repeat.png"))
	assert(layout_item_script.contains("prop_ch03_wood_platform_long.png"))
	assert(layout_item_script.contains("prop_ch03_wood_platform_bracket.png"))
	assert(layout_item_script.contains("prop_ch03_pressure_plate_raised.png"))
	assert(layout_item_script.contains("prop_ch03_pressure_plate_pressed.png"))
	assert(layout_item_script.contains("prop_ch03_mechanism_door_closed.png"))
	assert(not layout_item_script.contains("external_visual"), "三关门必须统一使用机关门贴图")
	assert(not rooftop_scene.contains("external_visual"), "第三关不能再跳过统一机关门贴图")
	assert(rooftop_scene.contains("metadata/plates = [0, 1]"), "第三关双踏板解锁条件必须保留")
	for rejected_asset in RUNTIME_REJECTED_ASSETS:
		assert(not chapter_script.contains(rejected_asset) and not layout_item_script.contains(rejected_asset) and not rooftop_scene.contains(rejected_asset), "不匹配当前场景的候选素材不能被运行时加载：%s" % rejected_asset)

	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame
	assert(chapter != null and chapter.levels.size() == 3)

	print("[CHAPTER03_ASSETS] PASS 10 scene-matched textures load; all doors share one mechanism texture")
	quit(0)
