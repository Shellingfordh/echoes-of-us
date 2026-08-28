class_name InteractionHint
extends Label


func _ready() -> void:
	add_to_group(&"interaction_hint")
	hide()


func show_hint(message: String) -> void:
	text = message
	show()


func hide_hint() -> void:
	hide()
