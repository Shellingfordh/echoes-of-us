class_name PrototypeUI
extends CanvasLayer

signal checkpoint_shown
signal chapter_shown

@onready var objective_label: Label = %ObjectiveLabel
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
@onready var chapter_panel: PanelContainer = %ChapterPanel
@onready var chapter_kicker: Label = %ChapterKicker
@onready var chapter_title: Label = %ChapterTitle
@onready var checkpoint_label: Label = %CheckpointLabel
@onready var fade_rect: ColorRect = %FadeRect

var _dialogue_revision := 0
var _checkpoint_revision := 0
var _controls_revision := 0
var duration_scale := 1.0


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


func hide_completion() -> void:
	completion_panel.visible = false
