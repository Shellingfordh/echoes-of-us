class_name AudioDirector
extends Node

const SAMPLE_RATE := 22050

var current_mood := "silent"
var last_cue := ""
var muted := false

var _ambient_player: AudioStreamPlayer
var _cue_player: AudioStreamPlayer
var _stream_cache: Dictionary = {}
var _tension := 0.0
var _playback_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_playback_enabled = DisplayServer.get_name() != "headless"
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	add_child(_ambient_player)
	_cue_player = AudioStreamPlayer.new()
	_cue_player.name = "CuePlayer"
	add_child(_cue_player)


func _process(delta: float) -> void:
	if _ambient_player == null:
		return
	var target_volume := -80.0 if muted else lerpf(-31.0, -24.0, _tension)
	_ambient_player.volume_db = move_toward(_ambient_player.volume_db, target_volume, delta * 7.0)
	_ambient_player.pitch_scale = lerpf(1.0, 1.045, _tension)


func set_mood(mood: String) -> void:
	if mood == current_mood and _ambient_player.playing:
		return
	current_mood = mood
	if mood == "silent":
		_ambient_player.stop()
		return
	if not _playback_enabled:
		return
	_ambient_player.stream = _get_stream("mood_%s" % mood, 4.0, true)
	_ambient_player.volume_db = -31.0
	_ambient_player.pitch_scale = 1.0
	_ambient_player.play()


func set_tension(value: float) -> void:
	_tension = clampf(value, 0.0, 1.0)


func play_cue(cue_name: String) -> void:
	last_cue = cue_name
	if muted or not _playback_enabled:
		return
	var duration := 0.52
	if cue_name == "transition":
		duration = 1.1
	elif cue_name == "echo":
		duration = 0.9
	elif cue_name == "tension":
		duration = 0.75
	_cue_player.stream = _get_stream("cue_%s" % cue_name, duration, false)
	_cue_player.volume_db = -13.0
	_cue_player.pitch_scale = 1.0
	_cue_player.play()


func set_muted(value: bool) -> void:
	muted = value
	if muted and _cue_player != null:
		_cue_player.stop()
	if _ambient_player != null:
		_ambient_player.volume_db = -80.0 if muted else lerpf(-31.0, -24.0, _tension)


func shutdown() -> void:
	if _ambient_player != null:
		_ambient_player.stop()
		_ambient_player.stream = null
	if _cue_player != null:
		_cue_player.stop()
		_cue_player.stream = null
	_stream_cache.clear()
	current_mood = "silent"


func _exit_tree() -> void:
	shutdown()


func _get_stream(stream_id: String, duration: float, should_loop: bool) -> AudioStreamWAV:
	if _stream_cache.has(stream_id):
		return _stream_cache[stream_id] as AudioStreamWAV
	var stream := _build_stream(stream_id, duration, should_loop)
	_stream_cache[stream_id] = stream
	return stream


func _build_stream(stream_id: String, duration: float, should_loop: bool) -> AudioStreamWAV:
	var frame_count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 4)
	var filtered_noise := 0.0
	var seed := 17041

	for frame in range(frame_count):
		var time := float(frame) / float(SAMPLE_RATE)
		seed = int((seed * 1103515245 + 12345) & 0x7fffffff)
		var white_noise := float(seed % 65536) / 32767.5 - 1.0
		filtered_noise = filtered_noise * 0.94 + white_noise * 0.06
		var sample := _sample_stream(stream_id, time, duration, filtered_noise)
		var envelope := 1.0 if should_loop else _cue_envelope(time, duration)
		var value := int(clampf(sample * envelope, -0.98, 0.98) * 32767.0)
		bytes.encode_s16(frame * 4, value)
		bytes.encode_s16(frame * 4 + 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = bytes
	if should_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frame_count
	return stream


func _sample_stream(stream_id: String, time: float, duration: float, noise: float) -> float:
	var ratio := time / maxf(duration, 0.001)
	match stream_id:
		"mood_prologue":
			return sin(TAU * 48.0 * time) * 0.035 + sin(TAU * 72.0 * time) * 0.018 + noise * 0.012
		"mood_home":
			return sin(TAU * 55.0 * time) * 0.07 + sin(TAU * 82.5 * time) * 0.035 + noise * 0.018
		"mood_memory":
			return noise * 0.16 + sin(TAU * 98.0 * time) * 0.028 + sin(TAU * 147.0 * time) * 0.018
		"mood_corridor":
			return sin(TAU * 46.0 * time) * 0.055 + noise * 0.045 + sin(TAU * 0.23 * time) * 0.02
		"mood_warehouse":
			return sin(TAU * 39.0 * time) * 0.075 + sin(TAU * 78.0 * time) * 0.025 + noise * 0.03
		"mood_rooftop":
			return noise * 0.105 + sin(TAU * 66.0 * time) * 0.026
		"mood_apartment":
			return sin(TAU * 62.0 * time) * 0.045 + sin(TAU * 93.0 * time) * 0.022 + noise * 0.025
		"mood_silence":
			return sin(TAU * 38.0 * time) * 0.012 + noise * 0.008
		"mood_epilogue":
			return sin(TAU * 58.0 * time) * 0.032 + sin(TAU * 87.0 * time) * 0.019 + noise * 0.014
		"cue_checkpoint":
			return sin(TAU * 660.0 * time) * 0.2 + sin(TAU * 880.0 * time) * 0.12
		"cue_fragment":
			return sin(TAU * (520.0 + ratio * 340.0) * time) * 0.26 + sin(TAU * 1040.0 * time) * 0.07
		"cue_reveal":
			return sin(TAU * (280.0 + ratio * 620.0) * time) * 0.24 + noise * 0.035
		"cue_anchor":
			return sin(TAU * 420.0 * time) * 0.2 + sin(TAU * 630.0 * time) * 0.14
		"cue_echo":
			return sin(TAU * 330.0 * time) * 0.11 + sin(TAU * 495.0 * time) * 0.08 + noise * 0.025
		"cue_tension":
			return sin(TAU * (125.0 + ratio * 45.0) * time) * 0.24 + sin(TAU * 250.0 * time) * 0.06
		"cue_transition":
			return noise * (0.04 + ratio * 0.13) + sin(TAU * (90.0 + ratio * 180.0) * time) * 0.12
	return sin(TAU * 440.0 * time) * 0.16


func _cue_envelope(time: float, duration: float) -> float:
	var attack := clampf(time / 0.035, 0.0, 1.0)
	var release := clampf((duration - time) / maxf(duration * 0.72, 0.05), 0.0, 1.0)
	return attack * release * release
