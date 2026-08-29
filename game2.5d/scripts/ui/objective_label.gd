class_name ObjectiveLabel
extends PanelContainer

## 当前目标提示。放在画面左侧，带半透明纸纹底与金色左边框。
## level-flow.md 每个节点都有"任务提示更新为…"。
##
## 文案约定：第一行是标题（通常带进度计数），换行之后是描述。
## 只给一行时就当作标题，描述行整块隐藏。

@export var fade_time := 0.35

@onready var _title: Label = $VBox/Title
@onready var _description: Label = $VBox/Description

var _objective_text := ""


func _ready() -> void:
	add_to_group(&"objective_label")
	modulate.a = 0.0


func set_objective(objective_text: String) -> void:
	if objective_text == _objective_text and modulate.a > 0.9:
		return
	_objective_text = objective_text
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func() -> void: _apply_text(objective_text))
	tween.tween_property(self, "modulate:a", 1.0, fade_time)


## 首个换行处切开：之前是标题，之后是描述。
func _apply_text(objective_text: String) -> void:
	var split_at := objective_text.find("\n")
	if split_at < 0:
		_title.text = objective_text
		_description.text = ""
		_description.hide()
		return
	_title.text = objective_text.substr(0, split_at)
	_description.text = objective_text.substr(split_at + 1).strip_edges()
	_description.visible = not _description.text.is_empty()
