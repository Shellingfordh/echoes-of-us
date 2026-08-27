class_name EchoesMother
extends Node2D

const ROLE_TEXTURES := {
	"成年女儿": preload("res://assets/characters/character_daughter_adult_neutral.png"),
	"母亲": preload("res://assets/characters/character_mother_adult_neutral.png"),
	"年轻母亲": preload("res://assets/characters/character_mother_young_neutral.png"),
	"小女儿": preload("res://assets/characters/character_daughter_child_neutral.png"),
}

@export var role_name := "母亲"

var _time := 0.0
var _body_color := Color("#9b695d")
var _outline_color := Color("#f1ddd1")
var _actor_scale := 1.0
var _role_texture: Texture2D


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _ready() -> void:
	set_role(role_name)


func set_role(next_role: String) -> void:
	role_name = next_role
	_role_texture = ROLE_TEXTURES.get(role_name, ROLE_TEXTURES["母亲"]) as Texture2D
	match role_name:
		"小女儿":
			_body_color = Color("#d5a24c")
			_outline_color = Color("#fff0b5")
			_actor_scale = 0.78
		"成年女儿":
			_body_color = Color("#607aa6")
			_outline_color = Color("#dce8f4")
			_actor_scale = 1.0
		_:
			_body_color = Color("#9b695d")
			_outline_color = Color("#f1ddd1")
			_actor_scale = 1.0
	queue_redraw()


func _draw() -> void:
	var breath := sin(_time * 1.6) * 1.2
	var outline_color := _outline_color
	var size := _actor_scale
	if _role_texture != null:
		draw_texture_rect(
			_role_texture,
			Rect2(Vector2(-34.0, -70.0 + breath * 0.15) * size, Vector2(68.0, 102.0) * size),
			false
		)
	draw_circle(Vector2.ZERO, 32.0 * size + breath, Color(0.95, 0.66, 0.51, 0.06))
	var label_position := Vector2(-52.0, -78.0 * size)
	draw_string(
		ThemeDB.fallback_font,
		label_position + Vector2(1.0, 1.0),
		role_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		104.0,
		13,
		Color(0.03, 0.025, 0.04, 0.88)
	)
	draw_string(
		ThemeDB.fallback_font,
		label_position,
		role_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		104.0,
		13,
		outline_color
	)
