class_name TieLine3D
extends Node3D

enum State {
	HIDDEN,
	REVEAL,
	TENSE,
}

@export_node_path("Node3D") var source_path: NodePath
@export_node_path("Node3D") var target_path: NodePath
@export_range(8, 32, 1) var segment_count := 18

var state := State.HIDDEN
var tension := 0.0
var reduced_motion := false
var _source: Node3D
var _target: Node3D
var _mesh_instance: MeshInstance3D
var _ribbon := ImmediateMesh.new()
var _material := StandardMaterial3D.new()
var _elapsed := 0.0


func _ready() -> void:
	_source = get_node_or_null(source_path) as Node3D
	_target = get_node_or_null(target_path) as Node3D
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.emission_enabled = true
	_material.no_depth_test = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TieRibbon"
	_mesh_instance.mesh = _ribbon
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_instance.visible = false
	add_child(_mesh_instance)


func _process(delta: float) -> void:
	if not reduced_motion:
		_elapsed += delta
	_update_visual()


func set_state(next_state: State) -> void:
	state = next_state
	_update_visual()


func state_name() -> String:
	match state:
		State.HIDDEN:
			return "Hidden"
		State.REVEAL:
			return "Reveal"
		State.TENSE:
			return "Tense"
	return "Unknown"


func _update_visual() -> void:
	if _source == null or _target == null:
		return
	if state == State.HIDDEN:
		_mesh_instance.visible = false
		_ribbon.clear_surfaces()
		return
	_mesh_instance.visible = true

	var source_position := _anchor_position(_source)
	var target_position := _anchor_position(_target)
	var visual_tension := clampf(tension, 0.0, 1.0)
	var sag := lerpf(0.62, 0.04, visual_tension)
	var wave := lerpf(0.08, 0.015, visual_tension)
	if state == State.REVEAL:
		sag = 0.48
		wave = 0.045
	if reduced_motion:
		wave *= 0.15

	var cool_color := Color("#c9dce2")
	var hot_color := Color("#ef6f61")
	var color := cool_color.lerp(hot_color, visual_tension)
	color.a = 0.72 if state == State.REVEAL else 0.94
	_material.albedo_color = color
	_material.emission = color
	_material.emission_energy_multiplier = lerpf(1.15, 3.2, visual_tension)

	var points: Array[Vector3] = []
	for index in range(segment_count + 1):
		var ratio := float(index) / float(segment_count)
		var point := source_position.lerp(target_position, ratio)
		point.y -= sin(ratio * PI) * sag
		point.z += sin(ratio * TAU * 1.5 + _elapsed * lerpf(1.6, 9.0, visual_tension)) * wave * sin(ratio * PI)
		points.append(point)

	var thickness := lerpf(0.028, 0.082, visual_tension)
	_ribbon.clear_surfaces()
	_ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for point in points:
		var local_point := to_local(point)
		_ribbon.surface_add_vertex(local_point + Vector3.UP * thickness)
		_ribbon.surface_add_vertex(local_point - Vector3.UP * thickness)
	_ribbon.surface_end()


func _anchor_position(node: Node3D) -> Vector3:
	if node.has_method("hand_position"):
		return node.call("hand_position") as Vector3
	var marker := node.get_node_or_null("HandAnchor") as Node3D
	return marker.global_position if marker != null else node.global_position + Vector3.UP
