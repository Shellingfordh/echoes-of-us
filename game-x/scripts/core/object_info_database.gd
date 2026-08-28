class_name ObjectInfoDatabase
extends Node

## 第一章 O-ID 客观物件信息。人物态度继续由 DialogueDatabase 的 D-ID 维护。

signal database_loaded(entry_count: int)

const DATA_PATH := "res://data/object_info.json"

var _entries: Dictionary = {}


func _ready() -> void:
	add_to_group(&"object_info_database")
	reload()


func reload() -> void:
	_entries.clear()
	if not FileAccess.file_exists(DATA_PATH):
		push_error("[ObjectInfo] 找不到物件信息文件：%s" % DATA_PATH)
		return

	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(DATA_PATH))
	if parse_error != OK:
		push_error(
			"[ObjectInfo] JSON 第 %d 行解析失败：%s"
			% [json.get_error_line(), json.get_error_message()]
		)
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("[ObjectInfo] JSON 根节点必须是对象：%s" % DATA_PATH)
		return

	for raw_key: Variant in (json.data as Dictionary).keys():
		var info_id := str(raw_key)
		if info_id.begins_with("_"):
			continue
		var raw_entry: Variant = (json.data as Dictionary)[raw_key]
		if typeof(raw_entry) != TYPE_DICTIONARY:
			push_error("[ObjectInfo] %s 必须是 JSON 对象" % info_id)
			continue
		_entries[info_id] = raw_entry

	_validate_entries()
	database_loaded.emit(_entries.size())


func has_info(info_id: String) -> bool:
	return _entries.has(info_id)


func get_entry(info_id: String) -> Dictionary:
	if not has_info(info_id):
		push_error("[ObjectInfo] 未定义的物件信息 ID：%s" % info_id)
		return {}
	return (_entries[info_id] as Dictionary).duplicate(true)


func get_title(info_id: String) -> String:
	return str(get_entry(info_id).get("title", "物件"))


func get_text(info_id: String) -> String:
	return str(get_entry(info_id).get("text", ""))


func get_dialogue_id(info_id: String) -> String:
	return str(get_entry(info_id).get("dialogue_id", ""))


func get_all_ids() -> Array:
	return _entries.keys()


func _validate_entries() -> void:
	for raw_id: Variant in _entries.keys():
		var info_id := str(raw_id)
		var entry: Dictionary = _entries[raw_id]
		if str(entry.get("title", "")).is_empty():
			push_error("[ObjectInfo] %s 缺少 title" % info_id)
		if str(entry.get("text", "")).is_empty():
			push_error("[ObjectInfo] %s 缺少 text" % info_id)
		if str(entry.get("dialogue_id", "")).is_empty():
			push_error("[ObjectInfo] %s 缺少 dialogue_id" % info_id)
