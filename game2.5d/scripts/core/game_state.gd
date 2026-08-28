class_name GameState
extends Node

signal flag_changed(flag_name: StringName, value: bool)
signal inventory_changed(items: Array[StringName])

var current_chapter := 1
var current_room: StringName = &"chapter_01_room_01"
var story_flags: Dictionary[StringName, bool] = {}
var inventory: Array[StringName] = []


func _ready() -> void:
	add_to_group(&"game_state")


func set_flag(flag_name: StringName, value := true) -> void:
	story_flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func has_flag(flag_name: StringName) -> bool:
	return story_flags.get(flag_name, false)


func add_item(item_id: StringName) -> void:
	if item_id in inventory:
		return
	inventory.append(item_id)
	inventory_changed.emit(inventory)


func has_item(item_id: StringName) -> bool:
	return item_id in inventory
