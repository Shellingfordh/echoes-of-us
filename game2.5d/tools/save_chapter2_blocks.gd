extends SceneTree

## 把 Chapter 2 运行时生成的白盒地图保存成编辑器可见的静态场景。
## 当前只生成快照，不替换 chapter2.tscn 的运行逻辑。

const SOURCE_SCENE := "res://scenes/chapter2/chapter2.tscn"
const OUTPUT_SCENE := "res://scenes/chapter2/chapter2_blocks.tscn"


func _initialize() -> void:
	call_deferred("_save_snapshot")


func _save_snapshot() -> void:
	var source := (load(SOURCE_SCENE) as PackedScene).instantiate()
	source.debug_skip_intro = true
	root.add_child(source)
	await process_frame

	var snapshot := Node2D.new()
	snapshot.name = "Chapter2Blocks"
	var blocks := {
		"A": _make_block(snapshot, "BlockA"),
		"B": _make_block(snapshot, "BlockB"),
		"C": _make_block(snapshot, "BlockC"),
	}

	var generated_map := source.get_node("World/GeneratedMap") as Node2D
	for generated_child in generated_map.get_children():
		var block_key := _classify_visual(generated_child)
		var visual_parent := (blocks[block_key] as Node).get_node("Visuals")
		visual_parent.add_child(generated_child.duplicate(), true)

	var generated_physics := source.get_node("World/SpatialPhysics") as Node3D
	for physics_child in generated_physics.get_children():
		var block_key := _classify_name(physics_child.name)
		var physics_parent := (blocks[block_key] as Node).get_node("SpatialPhysics")
		physics_parent.add_child(physics_child.duplicate(), true)

	_assign_owner(snapshot, snapshot)
	var packed := PackedScene.new()
	var pack_error := packed.pack(snapshot)
	assert(pack_error == OK, "无法打包第二章静态节点：%s" % error_string(pack_error))
	var save_error := ResourceSaver.save(packed, OUTPUT_SCENE)
	assert(save_error == OK, "无法保存第二章静态节点：%s" % error_string(save_error))

	print(
		"[CHAPTER2_SNAPSHOT] SAVED %s visuals=%d physics=%d"
		% [OUTPUT_SCENE, generated_map.get_child_count(), generated_physics.get_child_count()]
	)
	snapshot.free()
	source.free()
	await process_frame
	quit(0)


func _make_block(snapshot: Node2D, block_name: String) -> Node2D:
	var block := Node2D.new()
	block.name = block_name
	snapshot.add_child(block)

	var visuals := Node2D.new()
	visuals.name = "Visuals"
	block.add_child(visuals)

	var physics := Node3D.new()
	physics.name = "SpatialPhysics"
	block.add_child(physics)
	return block


func _classify_visual(node: Node) -> String:
	if node is Label:
		var label_text := (node as Label).text
		if "BLOCK C" in label_text:
			return "C"
		if "BLOCK B" in label_text:
			return "B"
	return _classify_name(node.name)


func _classify_name(node_name: StringName) -> String:
	var value := str(node_name)
	if (
		value.begins_with("BlockC")
		or value.begins_with("C_")
		or "School" in value
		or "Lamppost" in value
	):
		return "C"
	if (
		value.begins_with("BlockB")
		or value.begins_with("B_")
		or value.begins_with("Narrow")
		or value.begins_with("Pit")
		or value in ["BreakablePlank", "BrokenPlank", "UpperStableEndpoint"]
	):
		return "B"
	return "A"


func _assign_owner(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_assign_owner(child, scene_owner)
