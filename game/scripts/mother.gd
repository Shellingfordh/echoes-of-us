class_name EchoesMother
extends Node2D

const ROLE_NEUTRAL_TEXTURES := {
	"成年女儿": preload("res://assets/characters/character_daughter_adult_neutral.png"),
	"母亲": preload("res://assets/characters/character_mother_adult_neutral.png"),
	"年轻母亲": preload("res://assets/characters/character_mother_young_neutral.png"),
	"小女儿": preload("res://assets/characters/character_daughter_child_neutral.png"),
}
const ROLE_WALK_TEXTURES := {
	"成年女儿": preload("res://assets/characters/character_daughter_adult_walk.png"),
	"母亲": preload("res://assets/characters/character_mother_adult_walk.png"),
	"年轻母亲": preload("res://assets/characters/character_mother_young_walk.png"),
	"小女儿": preload("res://assets/characters/character_daughter_child_walk.png"),
}
const ROLE_EMOTION_TEXTURES := {
	"成年女儿": {
		"concern": preload("res://assets/characters/character_daughter_adult_concern.png"),
		"relieved": preload("res://assets/characters/character_daughter_adult_relieved.png"),
	},
	"母亲": {
		"concern": preload("res://assets/characters/character_mother_adult_concern.png"),
		"relieved": preload("res://assets/characters/character_mother_adult_relieved.png"),
	},
}

@export var role_name := "母亲"

var _time := 0.0
var visual_emotion := "neutral"
var _body_color := Color("#9b695d")
var _outline_color := Color("#f1ddd1")
var _actor_scale := 1.0
var _neutral_texture: Texture2D
var _walk_texture: Texture2D
var _walk_time := 0.0
var _is_moving := false
var _facing_left := false
var _last_global_position := Vector2.ZERO


func _process(delta: float) -> void:
	_time += delta
	var motion_delta := global_position - _last_global_position
	_is_moving = motion_delta.length_squared() > 0.25
	if _is_moving:
		_walk_time += delta
		if absf(motion_delta.x) > 0.5:
			_facing_left = motion_delta.x < 0.0
	_last_global_position = global_position
	queue_redraw()


func _ready() -> void:
	set_role(role_name)
	_last_global_position = global_position


func set_role(next_role: String) -> void:
	role_name = next_role
	_neutral_texture = ROLE_NEUTRAL_TEXTURES.get(role_name, ROLE_NEUTRAL_TEXTURES["母亲"]) as Texture2D
	_walk_texture = ROLE_WALK_TEXTURES.get(role_name, _neutral_texture) as Texture2D
	visual_emotion = "neutral"
	_walk_time = 0.0
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


func set_emotion(next_emotion: String) -> void:
	visual_emotion = next_emotion if next_emotion in ["neutral", "concern", "relieved"] else "neutral"
	queue_redraw()


func _draw() -> void:
	var breath := sin(_time * 1.6) * 1.2
	var outline_color := _outline_color
	var size := _actor_scale
	var role_texture := _texture_for_draw()
	if role_texture != null:
		if _facing_left:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(
			role_texture,
			Rect2(Vector2(-34.0, -70.0 + breath * 0.15) * size, Vector2(68.0, 102.0) * size),
			false
		)
		if _facing_left:
			draw_set_transform(Vector2.ZERO)
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


func _texture_for_draw() -> Texture2D:
	if visual_emotion != "neutral":
		var role_emotions := ROLE_EMOTION_TEXTURES.get(role_name, {}) as Dictionary
		var emotion_texture := role_emotions.get(visual_emotion) as Texture2D
		if emotion_texture != null:
			return emotion_texture
	if _is_moving and int(_walk_time / 0.18) % 2 == 1 and _walk_texture != null:
		return _walk_texture
	return _neutral_texture
