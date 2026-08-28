class_name ObjectiveLabel
extends Label

## 当前目标提示。level-flow.md 每个节点都有"任务提示更新为…"。

@export var fade_time := 0.35

var _objective_tween: Tween


func _ready() -> void:
	add_to_group(&"objective_label")
	modulate.a = 0.0


func set_objective(objective_text: String) -> void:
	if objective_text == text and modulate.a > 0.9:
		return
	if _objective_tween != null:
		_objective_tween.kill()
	# 目标承担即时操作引导，先更新文字再做轻微淡入，不能先黑屏半秒。
	text = objective_text
	modulate.a = 0.62
	_objective_tween = create_tween()
	_objective_tween.tween_property(self, "modulate:a", 1.0, minf(fade_time, 0.22))
