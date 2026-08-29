class_name InteractionHint
extends PanelContainer

## 交互提示。放在画面上方，带半透明灰底，避免被底部对话框遮住。

@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group(&"interaction_hint")
	hide()


func show_hint(message: String) -> void:
	_label.text = message
	show()


func hide_hint() -> void:
	hide()
