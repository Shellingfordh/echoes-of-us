class_name MemoryUmbrella
extends Area2D

signal inspected

const UMBRELLA_TEXTURE := preload("res://assets/props/prop_yellow_umbrella.png")

@export_node_path("Node2D") var player_path: NodePath
@export var interaction_distance := 92.0

var interaction_enabled := false
var _player: Node2D
var _elapsed := 0.0
var _is_near := false


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	_is_near = can_interact()
	queue_redraw()


func can_interact() -> bool:
	return (
		interaction_enabled
		and _player != null
		and global_position.distance_to(_player.global_position) <= interaction_distance
	)


func try_inspect() -> bool:
	if not can_interact():
		return false
	inspected.emit()
	return true


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled
	queue_redraw()


func _draw() -> void:
	var pulse := (sin(_elapsed * 2.4) + 1.0) * 0.5
	var glow_alpha := 0.10 + pulse * (0.17 if interaction_enabled else 0.05)
	if _is_near:
		glow_alpha += 0.18

	draw_circle(Vector2(0.0, -5.0), 42.0 + pulse * 5.0, Color(1.0, 0.73, 0.24, glow_alpha))
	draw_texture_rect(UMBRELLA_TEXTURE, Rect2(-39.0, -49.0, 78.0, 81.0), false)

	if _is_near:
		draw_arc(Vector2(0.0, 8.0), 48.0, 0.0, TAU, 48, Color("#ffe49a"), 2.0, true)
