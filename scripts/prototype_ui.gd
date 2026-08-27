class_name PrototypeUI
extends CanvasLayer

@onready var objective_label: Label = %ObjectiveLabel
@onready var phase_label: Label = %PhaseLabel
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var prompt_label: Label = %PromptLabel
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var debug_label: Label = %DebugLabel
@onready var tension_bar: ProgressBar = %TensionBar
@onready var completion_panel: PanelContainer = %CompletionPanel

var _dialogue_revision := 0


func set_objective(text: String) -> void:
	objective_label.text = text


func set_phase(text: String) -> void:
	phase_label.text = text


func set_interaction_prompt(text: String, visible_now: bool) -> void:
	prompt_label.text = text
	prompt_label.visible = visible_now


func set_debug_visible(visible_now: bool) -> void:
	debug_panel.visible = visible_now


func toggle_debug() -> bool:
	debug_panel.visible = not debug_panel.visible
	return debug_panel.visible


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
	await get_tree().create_timer(duration).timeout
	if revision == _dialogue_revision:
		dialogue_panel.visible = false


func show_completion() -> void:
	completion_panel.visible = true
