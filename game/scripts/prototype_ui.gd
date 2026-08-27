class_name PrototypeUI
extends CanvasLayer

signal checkpoint_shown
signal chapter_shown
signal mute_changed(muted: bool)
signal reduced_motion_changed(enabled: bool)

const SETTINGS_PATH := "user://echoes_settings.cfg"

@onready var objective_label: Label = %ObjectiveLabel
@onready var top_margin: MarginContainer = $TopMargin
@onready var phase_label: Label = %PhaseLabel
@onready var controls_label: Label = %ControlsLabel
@onready var role_label: Label = %RoleLabel
@onready var collection_label: Label = %CollectionLabel
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var prompt_label: Label = %PromptLabel
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var debug_label: Label = %DebugLabel
@onready var tension_bar: ProgressBar = %TensionBar
@onready var completion_panel: PanelContainer = %CompletionPanel
@onready var complete_title: Label = %CompleteTitle
@onready var complete_subtitle: Label = %CompleteSubtitle
@onready var complete_restart_button: Button = %CompleteRestartButton
@onready var chapter_panel: PanelContainer = %ChapterPanel
@onready var chapter_kicker: Label = %ChapterKicker
@onready var chapter_title: Label = %ChapterTitle
@onready var checkpoint_label: Label = %CheckpointLabel
@onready var fade_rect: ColorRect = %FadeRect
@onready var pause_shade: ColorRect = %PauseShade
@onready var pause_panel: PanelContainer = %PausePanel
@onready var resume_button: Button = %ResumeButton
@onready var sound_button: Button = %SoundButton
@onready var motion_button: Button = %MotionButton
@onready var restart_button: Button = %RestartButton

var _dialogue_revision := 0
var _checkpoint_revision := 0
var _controls_revision := 0
var duration_scale := 1.0
var sound_muted := false
var reduced_motion := false
var persistence_enabled := true


func _ready() -> void:
	var game := get_parent()
	if game != null and bool(game.get("test_mode")):
		persistence_enabled = false
	if persistence_enabled:
		_load_settings()
	resume_button.pressed.connect(toggle_pause)
	sound_button.pressed.connect(toggle_mute)
	motion_button.pressed.connect(toggle_reduced_motion)
	restart_button.pressed.connect(_restart_game)
	complete_restart_button.pressed.connect(_restart_game)
	_update_settings_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif pause_panel.visible and event.is_action_pressed(&"toggle_mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()
	elif pause_panel.visible and event.is_action_pressed(&"toggle_reduced_motion"):
		toggle_reduced_motion()
		get_viewport().set_input_as_handled()
	elif pause_panel.visible and event.is_action_pressed(&"restart"):
		_restart_game()
		get_viewport().set_input_as_handled()


func set_objective(text: String) -> void:
	objective_label.text = text


func set_phase(text: String) -> void:
	phase_label.text = text


func set_role(text: String) -> void:
	role_label.text = "当前控制：%s" % text


func set_collection(fragment_count: int, echo_count: int) -> void:
	collection_label.text = "记忆碎片 %d/5   回响 %d/3" % [fragment_count, echo_count]


func set_interaction_prompt(text: String, visible_now: bool) -> void:
	prompt_label.text = text
	prompt_label.visible = visible_now


func set_hud_visible(visible_now: bool) -> void:
	top_margin.visible = visible_now
	if not visible_now:
		prompt_label.visible = false
		dialogue_panel.visible = false


func set_debug_visible(visible_now: bool) -> void:
	debug_panel.visible = visible_now


func toggle_debug() -> bool:
	debug_panel.visible = not debug_panel.visible
	return debug_panel.visible


func show_controls_hint(duration := 7.0) -> void:
	_controls_revision += 1
	var revision := _controls_revision
	controls_label.visible = true
	await get_tree().create_timer(maxf(duration * duration_scale, 0.05)).timeout
	if revision == _controls_revision:
		controls_label.visible = false


func toggle_controls_hint() -> bool:
	_controls_revision += 1
	controls_label.visible = not controls_label.visible
	return controls_label.visible


func toggle_pause() -> bool:
	var next_paused := not get_tree().paused
	get_tree().paused = next_paused
	pause_shade.visible = next_paused
	pause_panel.visible = next_paused
	if next_paused:
		resume_button.grab_focus()
	return next_paused


func toggle_mute() -> bool:
	sound_muted = not sound_muted
	_update_settings_labels()
	_save_settings()
	mute_changed.emit(sound_muted)
	return sound_muted


func toggle_reduced_motion() -> bool:
	reduced_motion = not reduced_motion
	_update_settings_labels()
	_save_settings()
	reduced_motion_changed.emit(reduced_motion)
	return reduced_motion


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _update_settings_labels() -> void:
	sound_button.text = "声音：%s   [M]" % ("关闭" if sound_muted else "开启")
	motion_button.text = "动态效果：%s   [V]" % ("减少" if reduced_motion else "完整")


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	sound_muted = bool(config.get_value("accessibility", "sound_muted", false))
	reduced_motion = bool(config.get_value("accessibility", "reduced_motion", false))


func _save_settings() -> void:
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	config.set_value("accessibility", "sound_muted", sound_muted)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("[PrototypeUI] 无法保存体验设置（error %d）" % error)


func update_debug(
	player_position: Vector2,
	mother_position: Vector2,
	distance: float,
	tension: float,
	tie_state: String,
	phase: String
) -> void:
	tension_bar.value = tension * 100.0
	debug_label.text = (
		"PLAYER  %7.1f, %6.1f\n"
		+ "MOTHER  %7.1f, %6.1f\n"
		+ "DIST    %7.1f px\n"
		+ "TENSION %7.1f %%\n"
		+ "LINE    %s\n"
		+ "PHASE   %s"
	) % [
		player_position.x,
		player_position.y,
		mother_position.x,
		mother_position.y,
		distance,
		tension * 100.0,
		tie_state.to_upper(),
		phase.to_upper(),
	]


func show_dialogue(speaker: String, text: String, duration := 2.2) -> void:
	_dialogue_revision += 1
	var revision := _dialogue_revision
	speaker_label.text = speaker
	dialogue_label.text = text
	dialogue_panel.visible = true
	await get_tree().create_timer(maxf(duration * duration_scale, 0.01)).timeout
	if revision == _dialogue_revision:
		dialogue_panel.visible = false


func show_checkpoint(text := "✓ 检查点") -> void:
	checkpoint_shown.emit()
	_checkpoint_revision += 1
	var revision := _checkpoint_revision
	checkpoint_label.text = text
	checkpoint_label.visible = true
	await get_tree().create_timer(maxf(1.6 * duration_scale, 0.02)).timeout
	if revision == _checkpoint_revision:
		checkpoint_label.visible = false


func show_chapter(kicker: String, title: String) -> void:
	chapter_shown.emit()
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 1.0, 0.35 * duration_scale)
	await fade_in.finished
	chapter_kicker.text = kicker
	chapter_title.text = title
	chapter_panel.visible = true
	await get_tree().create_timer(maxf(1.15 * duration_scale, 0.02)).timeout
	chapter_panel.visible = false
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 0.0, 0.45 * duration_scale)
	await fade_out.finished
	fade_rect.visible = false


func show_completion(title := "—— 第四章 · 完 ——", subtitle := "线仍然在，远行也仍然继续。") -> void:
	complete_title.text = title
	complete_subtitle.text = subtitle
	completion_panel.visible = true
	complete_restart_button.grab_focus()


func hide_completion() -> void:
	completion_panel.visible = false
