class_name DialogueUI
extends Control

## 数据驱动对白播放器。内容和节点连接全部来自 data/dialogues.json。

signal dialogue_started(dialogue_id: String)
signal dialogue_node_changed(dialogue_id: String, line_index: int, speaker: String, text: String)
signal dialogue_finished(dialogue_id: String)

const MONOLOGUE_DURATION := 3.0
const END_DIALOGUE_ID := "END"

@export_range(1.0, 120.0, 1.0) var characters_per_second := 42.0
@export_range(0.0, 10.0, 0.1) var monologue_hold_seconds := MONOLOGUE_DURATION
@export_range(0.0, 1.0, 0.01) var fade_duration := 0.18

@onready var dimmer: ColorRect = $Dimmer
@onready var dialogue_frame: MarginContainer = $DialogueFrame
@onready var dialogue_header: HBoxContainer = $DialogueFrame/Panel/Margin/VBox/Header
@onready var speaker_name: Label = $DialogueFrame/Panel/Margin/VBox/Header/SpeakerName
@onready var portrait_panel: PanelContainer = $DialogueFrame/Panel/Margin/VBox/Body/PortraitPanel
@onready var portrait_initial: Label = $DialogueFrame/Panel/Margin/VBox/Body/PortraitPanel/PortraitMargin/PortraitInitial
@onready var dialogue_text: RichTextLabel = $DialogueFrame/Panel/Margin/VBox/Body/TextColumn/DialogueText
@onready var line_status: Label = $DialogueFrame/Panel/Margin/VBox/Body/TextColumn/Footer/LineStatus
@onready var continue_hint: Label = $DialogueFrame/Panel/Margin/VBox/Body/TextColumn/Footer/ContinueHint
@onready var next_indicator: Label = $DialogueFrame/Panel/Margin/VBox/Body/TextColumn/Footer/NextIndicator
@onready var monologue_frame: MarginContainer = $MonologueFrame
@onready var monologue_speaker: Label = $MonologueFrame/Panel/Margin/VBox/SpeakerName
@onready var monologue_text: RichTextLabel = $MonologueFrame/Panel/Margin/VBox/DialogueText

var _database: DialogueDatabase
var _game_flow: GameFlow
var _return_mode := GameFlow.Mode.EXPLORE
var _control_locked := false

var _root_id := ""
var _current_id := ""
var _next_id := END_DIALOGUE_ID
var _speaker := ""
var _lines: Array = []
var _line_index := 0
var _mode := "dialogue"

var _typing := false
var _line_revealed := false
var _active_text: RichTextLabel
var _typing_tween: Tween
var _fade_tween: Tween
var _session_generation := 0
var _line_generation := 0


func _ready() -> void:
	add_to_group(&"dialogue_ui")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


## 唯一播放入口：外部只传 data/dialogues.json 中的对白 ID。
func play(dialogue_id: String) -> void:
	_database = _get_database()
	if _database == null:
		push_error("[Dialogue] 场景里没有 DialogueDatabase")
		return
	if not _database.has_dialogue(dialogue_id):
		push_error("[Dialogue] 无法播放不存在的 ID：%s" % dialogue_id)
		return

	if is_playing():
		_finish_immediately(true)

	_session_generation += 1
	_root_id = dialogue_id
	modulate.a = 0.0
	show()
	if not _begin_entry(dialogue_id):
		_finish_immediately(false)
		return

	_fade_to(1.0)
	dialogue_started.emit(_root_id)


func advance() -> void:
	if not is_playing():
		return
	if _typing:
		_complete_typewriter()
		return

	_line_index += 1
	if _line_index < _lines.size():
		_show_current_line()
	else:
		_advance_to_next_entry()


func close_message() -> void:
	if not is_playing():
		return

	_session_generation += 1
	var closing_generation := _session_generation
	var finished_id := _root_id
	_cancel_typewriter()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_to(0.0)
	if _fade_tween != null:
		await _fade_tween.finished
	if closing_generation != _session_generation:
		return
	_finalize_close(finished_id, true)


func is_playing() -> bool:
	return visible and not _root_id.is_empty()


func _begin_entry(dialogue_id: String) -> bool:
	var entry := _database.get_entry(dialogue_id)
	if entry.is_empty():
		return false

	var entry_lines: Variant = entry.get("lines", [])
	if typeof(entry_lines) != TYPE_ARRAY or (entry_lines as Array).is_empty():
		push_error("[Dialogue] %s 没有可播放的 lines" % dialogue_id)
		return false

	_current_id = dialogue_id
	_next_id = str(entry.get("next", END_DIALOGUE_ID))
	_speaker = str(entry.get("speaker", ""))
	_lines = entry_lines as Array
	_line_index = 0
	_mode = str(entry.get("mode", "dialogue"))
	_set_control_lock(_mode == "dialogue")
	_apply_mode_style()
	_show_current_line()
	return true


func _show_current_line() -> void:
	_cancel_typewriter()
	_line_generation += 1
	_line_revealed = false

	var text := str(_lines[_line_index])
	var has_speaker := not _speaker.is_empty()
	if _mode == "dialogue":
		dialogue_header.visible = has_speaker
		portrait_panel.visible = has_speaker
		speaker_name.text = _speaker
		portrait_initial.text = _speaker.left(1) if has_speaker else ""
		line_status.text = "%d / %d" % [_line_index + 1, _lines.size()]
		line_status.visible = _lines.size() > 1
		continue_hint.hide()
		next_indicator.hide()
		_active_text = dialogue_text
	else:
		monologue_speaker.text = _speaker
		monologue_speaker.visible = has_speaker
		_active_text = monologue_text

	_start_typewriter(_active_text, text, _line_generation)
	dialogue_node_changed.emit(_current_id, _line_index, _speaker, text)


func _start_typewriter(label: RichTextLabel, text: String, generation: int) -> void:
	label.text = text
	label.visible_characters = 0
	var character_count := text.length()
	if character_count == 0 or characters_per_second <= 0.0:
		label.visible_characters = -1
		_on_typewriter_finished(generation)
		return

	_typing = true
	_typing_tween = create_tween()
	_typing_tween.tween_property(
		label,
		"visible_characters",
		character_count,
		maxf(float(character_count) / characters_per_second, 0.05)
	)
	_typing_tween.finished.connect(_on_typewriter_finished.bind(generation))


func _on_typewriter_finished(generation: int) -> void:
	if generation != _line_generation or not is_playing():
		return
	_typing = false
	if is_instance_valid(_active_text):
		_active_text.visible_characters = -1
	_after_line_revealed(generation)


func _complete_typewriter() -> void:
	if not _typing:
		return
	if _typing_tween != null:
		_typing_tween.kill()
	_typing = false
	if is_instance_valid(_active_text):
		_active_text.visible_characters = -1
	_after_line_revealed(_line_generation)


func _after_line_revealed(generation: int) -> void:
	if _line_revealed or generation != _line_generation:
		return
	_line_revealed = true
	if _mode == "monologue":
		_wait_then_advance_monologue(generation)
	else:
		continue_hint.show()
		next_indicator.show()


func _wait_then_advance_monologue(generation: int) -> void:
	await get_tree().create_timer(monologue_hold_seconds).timeout
	if generation != _line_generation or not is_playing() or _mode != "monologue":
		return
	advance()


func _advance_to_next_entry() -> void:
	if _next_id.is_empty() or _next_id == END_DIALOGUE_ID:
		close_message()
		return
	if not _database.has_dialogue(_next_id):
		push_error("[Dialogue] %s 指向不存在的 next：%s" % [_current_id, _next_id])
		close_message()
		return
	_begin_entry(_next_id)


func _apply_mode_style() -> void:
	var is_dialogue := _mode == "dialogue"
	dimmer.visible = is_dialogue
	dialogue_frame.visible = is_dialogue
	monologue_frame.visible = not is_dialogue
	mouse_filter = Control.MOUSE_FILTER_STOP if is_dialogue else Control.MOUSE_FILTER_IGNORE


func _set_control_lock(should_lock: bool) -> void:
	_game_flow = _get_game_flow()
	if should_lock and not _control_locked:
		if _game_flow != null:
			_return_mode = _game_flow.current_mode
			_game_flow.set_mode(GameFlow.Mode.DIALOGUE)
		_control_locked = true
	elif not should_lock and _control_locked:
		_restore_player_control()


func _restore_player_control() -> void:
	if _control_locked and _game_flow != null:
		_game_flow.set_mode(_return_mode)
	_control_locked = false


func _fade_to(alpha: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	if fade_duration <= 0.0:
		modulate.a = alpha
		_fade_tween = null
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", alpha, fade_duration)


func _cancel_typewriter() -> void:
	_line_generation += 1
	if _typing_tween != null:
		_typing_tween.kill()
	_typing_tween = null
	_typing = false
	_line_revealed = false


func _finish_immediately(emit_finished_signal: bool) -> void:
	var finished_id := _root_id
	_session_generation += 1
	_cancel_typewriter()
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = null
	_finalize_close(finished_id, emit_finished_signal)


func _finalize_close(finished_id: String, emit_finished_signal: bool) -> void:
	_restore_player_control()
	hide()
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_id = ""
	_current_id = ""
	_next_id = END_DIALOGUE_ID
	_speaker = ""
	_lines = []
	_line_index = 0
	if emit_finished_signal and not finished_id.is_empty():
		dialogue_finished.emit(finished_id)


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing() or _mode != "dialogue":
		return
	if event.is_action_pressed(&"interact"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		close_message()
		get_viewport().set_input_as_handled()


func _get_game_flow() -> GameFlow:
	if is_instance_valid(_game_flow):
		return _game_flow
	return get_tree().get_first_node_in_group(&"game_flow") as GameFlow


func _get_database() -> DialogueDatabase:
	if is_instance_valid(_database):
		return _database
	return get_tree().get_first_node_in_group(&"dialogue_database") as DialogueDatabase
