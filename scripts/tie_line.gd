class_name TieLine
extends Line2D

signal state_changed(state_name: String)
signal revealed
signal maximum_tension_reached

enum TieState {
	HIDDEN,
	TENSE,
	ADJUSTABLE,
	EXTENDING,
}

@export_node_path("Node2D") var source_path: NodePath
@export_node_path("Node2D") var target_path: NodePath
@export_range(80.0, 1200.0, 1.0) var reveal_distance := 360.0
@export_range(120.0, 1600.0, 1.0) var max_distance := 820.0
@export_range(0.1, 3.0, 0.05) var reveal_duration := 1.0
@export_range(4, 40, 1) var segment_count := 18

var state := TieState.HIDDEN
var distance := 0.0
var tension_value := 0.0

var _source: Node2D
var _target: Node2D
var _reveal_progress := 0.0
var _elapsed := 0.0
var _maximum_emitted := false


func _ready() -> void:
	_source = get_node_or_null(source_path) as Node2D
	_target = get_node_or_null(target_path) as Node2D
	width = 3.0
	default_color = Color.TRANSPARENT
	antialiased = true
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	joint_mode = Line2D.LINE_JOINT_ROUND
	if _source == null or _target == null:
		push_error("[TieLine] source_path and target_path must resolve to Node2D nodes")
		set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	if _source == null or _target == null:
		return

	var source_position := _source.global_position + Vector2(0.0, -8.0)
	var target_position := _target.global_position + Vector2(0.0, -8.0)
	distance = source_position.distance_to(target_position)
	tension_value = clampf(
		(distance - reveal_distance) / maxf(max_distance - reveal_distance, 1.0),
		0.0,
		1.0
	)

	if state == TieState.HIDDEN and distance >= reveal_distance:
		set_story_state(TieState.TENSE)
		revealed.emit()

	if state != TieState.HIDDEN:
		_reveal_progress = minf(_reveal_progress + delta / reveal_duration, 1.0)

	if tension_value >= 0.985 and not _maximum_emitted:
		_maximum_emitted = true
		maximum_tension_reached.emit()
	elif tension_value < 0.8:
		_maximum_emitted = false

	_update_points(source_position, target_position)
	_update_visuals()


func set_story_state(next_state: TieState) -> void:
	if state == next_state:
		return
	state = next_state
	if state == TieState.HIDDEN:
		_reveal_progress = 0.0
	state_changed.emit(get_state_name())


func get_state_name() -> String:
	match state:
		TieState.HIDDEN:
			return "Hidden"
		TieState.TENSE:
			return "Tense"
		TieState.ADJUSTABLE:
			return "Adjustable"
		TieState.EXTENDING:
			return "Extending"
	return "Unknown"


func _update_points(source_position: Vector2, target_position: Vector2) -> void:
	var local_source := to_local(source_position)
	var local_target := to_local(target_position)
	var direction := local_target - local_source
	var perpendicular := direction.normalized().orthogonal()
	var next_points := PackedVector2Array()

	for index in range(segment_count + 1):
		var ratio := float(index) / float(segment_count)
		var point := local_source.lerp(local_target, ratio)
		var envelope := sin(ratio * PI)
		var wave_strength := 0.0
		match state:
			TieState.TENSE:
				wave_strength = lerpf(5.0, 1.2, tension_value)
				wave_strength += tension_value * sin(_elapsed * 22.0 + index * 2.1) * 1.4
			TieState.ADJUSTABLE:
				wave_strength = 7.0
			TieState.EXTENDING:
				wave_strength = 2.5
		point += perpendicular * sin(_elapsed * 2.8 + ratio * TAU * 2.0) * wave_strength * envelope
		next_points.append(point)

	points = next_points


func _update_visuals() -> void:
	if state == TieState.HIDDEN:
		default_color = Color.TRANSPARENT
		return

	var color := Color("#f2e8de")
	match state:
		TieState.TENSE:
			color = Color("#d9ecf2").lerp(Color("#ff8c7a"), tension_value)
			width = lerpf(2.5, 8.0, tension_value)
		TieState.ADJUSTABLE:
			color = Color("#f2c88f")
			width = 4.0
		TieState.EXTENDING:
			color = Color("#f5d77f")
			width = 2.0

	color.a = _reveal_progress
	default_color = color
