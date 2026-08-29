class_name ObjectiveLabel
extends Label

## 当前目标提示。level-flow.md 每个节点都有"任务提示更新为…"。

@export var fade_time := 0.35


func _ready() -> void:
	add_to_group(&"objective_label")
	modulate.a = 0.0


func set_objective(objective_text: String) -> void:
	if objective_text == text and modulate.a > 0.9:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func() -> void: text = objective_text)
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
