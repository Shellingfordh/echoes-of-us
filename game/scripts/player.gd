class_name EchoesPlayer
extends CharacterBody2D

signal interaction_requested

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

@export var move_speed: float = 250.0
@export var world_bounds := Rect2(96.0, 258.0, 1350.0, 350.0)
@export var role_name := "成年女儿"

var controls_enabled := true
var movement_multiplier := 1.0
var presentation_mode := false
var visual_emotion := "neutral"
var _facing_left := false
var _body_color := Color("#607aa6")
var _accent_color := Color("#dce8f4")
var _actor_scale := 1.0
var _neutral_texture: Texture2D
var _walk_texture: Texture2D
var _walk_time := 0.0
var _is_moving := false
var _last_global_position := Vector2.ZERO


func _ready() -> void:
	set_role(role_name)
	_last_global_position = global_position
	queue_redraw()


func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	if controls_enabled:
		input_direction = Input.get_vector(
			&"move_left",
			&"move_right",
			&"move_up",
			&"move_down"
		)

	if absf(input_direction.x) > 0.05:
		_facing_left = input_direction.x < 0.0

	velocity = input_direction * move_speed * movement_multiplier
	move_and_slide()

	global_position.x = clampf(
		global_position.x,
		world_bounds.position.x,
		world_bounds.end.x
	)
	global_position.y = clampf(
		global_position.y,
		world_bounds.position.y,
		world_bounds.end.y
	)
	var motion_delta := global_position - _last_global_position
	var next_is_moving := input_direction.length_squared() > 0.01 or motion_delta.length_squared() > 0.25
	if absf(motion_delta.x) > 0.5:
		_facing_left = motion_delta.x < 0.0
	if next_is_moving:
		_walk_time += delta
	if next_is_moving != _is_moving or next_is_moving:
		_is_moving = next_is_moving
		queue_redraw()
	_last_global_position = global_position


func set_role(next_role: String) -> void:
	role_name = next_role
	_neutral_texture = ROLE_NEUTRAL_TEXTURES.get(role_name, ROLE_NEUTRAL_TEXTURES["成年女儿"]) as Texture2D
	_walk_texture = ROLE_WALK_TEXTURES.get(role_name, _neutral_texture) as Texture2D
	visual_emotion = "neutral"
	_walk_time = 0.0
	match role_name:
		"母亲", "年轻母亲":
			_body_color = Color("#9b695d")
			_accent_color = Color("#f1ddd1")
			_actor_scale = 1.0
			move_speed = 235.0
		"小女儿":
			_body_color = Color("#d5a24c")
			_accent_color = Color("#fff0b5")
			_actor_scale = 0.78
			move_speed = 260.0
		_:
			_body_color = Color("#607aa6")
			_accent_color = Color("#dce8f4")
			_actor_scale = 1.0
			move_speed = 250.0
	queue_redraw()


func set_emotion(next_emotion: String) -> void:
	visual_emotion = next_emotion if next_emotion in ["neutral", "concern", "relieved"] else "neutral"
	queue_redraw()


func set_world_bounds(next_bounds: Rect2) -> void:
	world_bounds = next_bounds
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = int(next_bounds.position.x - 96.0)
	camera.limit_top = 0
	camera.limit_right = int(next_bounds.end.x + 96.0)
	camera.limit_bottom = 720


func set_presentation_mode(enabled: bool) -> void:
	presentation_mode = enabled
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if controls_enabled and event.is_action_pressed(&"interact"):
		interaction_requested.emit()


func _draw() -> void:
	var outline_color := _accent_color
	var size := _actor_scale
	var role_texture := _texture_for_draw()
	if role_texture != null:
		if _facing_left:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(
			role_texture,
			Rect2(Vector2(-34.0, -70.0) * size, Vector2(68.0, 102.0) * size),
			false
		)
		if _facing_left:
			draw_set_transform(Vector2.ZERO)
	if not presentation_mode:
		draw_arc(Vector2.ZERO, 31.0 * size, 0.0, TAU, 32, Color(0.43, 0.76, 1.0, 0.46), 2.0, true)
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
