class_name CinematicPlayer
extends Control

## 序章与第四章共用的全屏视频播放器。
## 序章播放完进入第一章；第四章播放完自动从头循环，可从序章重开。

enum PlaybackState { PLAYING, COMPLETE, TRANSITIONING }

@export_range(0, 4, 1) var chapter_number := 0
@export_file("*.tscn") var next_scene_path := ""
@export_file("*.tscn") var restart_scene_path := "res://scenes/cinematics/prologue.tscn"
@export var reset_session_on_ready := false
@export var auto_replay := false
@export var skip_hint_text := "Enter / Space 跳过"
@export var complete_hint_text := "Enter / Space 重播  ·  R 从序章重新开始"
@export var fallback_title := "余响：牵挂"
@export var fallback_subtitle := ""

var playback_state := PlaybackState.PLAYING

@onready var video_player: VideoStreamPlayer = $Video
@onready var final_card: Control = $FinalCard
@onready var final_title: Label = $FinalCard/Title
@onready var final_subtitle: Label = $FinalCard/Subtitle
@onready var skip_hint: Label = $SkipHint
@onready var complete_hint: Label = $CompleteHint


func _ready() -> void:
	var session := get_node("/root/GameSession")
	if reset_session_on_ready:
		session.reset()
	if chapter_number > 0:
		session.enter_chapter(chapter_number)
	assert(video_player.stream != null, "cinematic scene requires a video stream")
	video_player.finished.connect(_on_video_finished)
	final_title.text = fallback_title
	final_subtitle.text = fallback_subtitle
	_play_video()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed(&"reset_checkpoint") and (playback_state == PlaybackState.COMPLETE or auto_replay):
		_restart_game()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"start_game"):
		return
	if playback_state == PlaybackState.PLAYING:
		if auto_replay:
			_play_video()
		else:
			_finish_cinematic(false)
	elif playback_state == PlaybackState.COMPLETE:
		_play_video()
	get_viewport().set_input_as_handled()


func _play_video() -> void:
	playback_state = PlaybackState.PLAYING
	final_card.hide()
	complete_hint.hide()
	skip_hint.text = skip_hint_text
	skip_hint.visible = not skip_hint_text.is_empty()
	video_player.stream_position = 0.0
	video_player.show()
	if DisplayServer.get_name() != "headless":
		video_player.play()


func _on_video_finished() -> void:
	if playback_state != PlaybackState.PLAYING:
		return
	if auto_replay:
		if chapter_number > 0:
			get_node("/root/GameSession").complete_chapter(chapter_number)
		_play_video()
		return
	_finish_cinematic(true)


func _finish_cinematic(preserve_last_frame: bool) -> void:
	if chapter_number > 0:
		get_node("/root/GameSession").complete_chapter(chapter_number)
	if not next_scene_path.is_empty():
		playback_state = PlaybackState.TRANSITIONING
		video_player.stop()
		video_player.hide()
		skip_hint.hide()
		var error := get_tree().change_scene_to_file(next_scene_path)
		assert(error == OK, "failed to open next cinematic scene: %s" % next_scene_path)
		return

	playback_state = PlaybackState.COMPLETE
	skip_hint.hide()
	if not preserve_last_frame:
		video_player.stop()
		video_player.hide()
		final_card.show()
	complete_hint.text = complete_hint_text
	complete_hint.show()


func _restart_game() -> void:
	if restart_scene_path.is_empty():
		return
	playback_state = PlaybackState.TRANSITIONING
	video_player.stop()
	get_node("/root/GameSession").reset()
	var error := get_tree().change_scene_to_file(restart_scene_path)
	assert(error == OK, "failed to restart from cinematic: %s" % restart_scene_path)


func get_playback_snapshot() -> Dictionary:
	return {
		"state": PlaybackState.keys()[playback_state],
		"chapter": chapter_number,
		"next_scene": next_scene_path,
		"stream_length": video_player.get_stream_length() if video_player != null else 0.0,
	}
