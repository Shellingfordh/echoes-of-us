class_name ChapterOnePlayer
extends CharacterBody3D

signal interaction_requested

@export var move_speed := 3.9
@export var x_bounds := Vector2(-6.7, 6.8)
@export var z_bounds := Vector2(-1.75, 1.65)

var controls_enabled := true
var movement_multiplier := 1.0
var swing_mode := false
var facing_left := false
var _visual_root: Node3D


func _ready() -> void:
	_build_prototype_visual()


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	if controls_enabled:
		input_vector = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	if absf(input_vector.x) > 0.05:
		facing_left = input_vector.x < 0.0
		_visual_root.rotation.y = PI if facing_left else 0.0

	if swing_mode:
		velocity = Vector3(input_vector.x * move_speed * 0.42, 0.0, 0.0)
	else:
		velocity = Vector3(input_vector.x, 0.0, input_vector.y).normalized() * move_speed * movement_multiplier
	move_and_slide()

	global_position.x = clampf(global_position.x, x_bounds.x, x_bounds.y)
	global_position.z = clampf(global_position.z, z_bounds.x, z_bounds.y)

	var moving_amount := clampf(Vector2(velocity.x, velocity.z).length() / maxf(move_speed, 0.01), 0.0, 1.0)
	_visual_root.position.y = sin(Time.get_ticks_msec() * 0.013) * 0.035 * moving_amount


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event.is_action_pressed(&"interact"):
		interaction_requested.emit()


func set_suspended(enabled: bool) -> void:
	swing_mode = enabled
	if not enabled:
		velocity = Vector3.ZERO


func hand_position() -> Vector3:
	return (get_node("HandAnchor") as Node3D).global_position


func _build_prototype_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "PrototypeVisual"
	add_child(_visual_root)

	var coat := _mesh_instance("Coat", CapsuleMesh.new(), Color("#73889a"))
	(coat.mesh as CapsuleMesh).radius = 0.27
	(coat.mesh as CapsuleMesh).height = 1.05
	coat.position = Vector3(0.0, 1.0, 0.0)
	_visual_root.add_child(coat)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	var head := _mesh_instance("Head", head_mesh, Color("#d8b7a1"))
	head.position = Vector3(0.0, 1.72, 0.0)
	_visual_root.add_child(head)

	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.25
	hair_mesh.height = 0.42
	var hair := _mesh_instance("Hair", hair_mesh, Color("#302d31"))
	hair.position = Vector3(-0.04, 1.81, 0.03)
	hair.scale = Vector3(1.0, 0.88, 1.0)
	_visual_root.add_child(hair)

	for side in [-1.0, 1.0]:
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.095
		leg_mesh.height = 0.82
		var leg := _mesh_instance("Leg", leg_mesh, Color("#38434d"))
		leg.position = Vector3(side * 0.12, 0.42, 0.0)
		_visual_root.add_child(leg)

	var scarf_mesh := TorusMesh.new()
	scarf_mesh.inner_radius = 0.16
	scarf_mesh.outer_radius = 0.25
	var scarf := _mesh_instance("Scarf", scarf_mesh, Color("#9aa780"))
	scarf.position = Vector3(0.0, 1.42, 0.0)
	scarf.rotation.x = PI * 0.5
	_visual_root.add_child(scarf)

	var hand_anchor := Marker3D.new()
	hand_anchor.name = "HandAnchor"
	hand_anchor.unique_name_in_owner = true
	hand_anchor.position = Vector3(0.3, 1.18, 0.02)
	add_child(hand_anchor)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.65
	collision.shape = capsule
	collision.position.y = 0.85
	add_child(collision)


func _mesh_instance(node_name: String, mesh: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance
