class_name ObservationDatabase
extends Node

## 第一章物件信息数据库。内容全部来自 data/observations.json。

signal database_loaded(entry_count: int)

const DATA_PATH := "res://data/observations.json"

var _entries: Dictionary = {}


func _ready() -> void:
	add_to_group(&"observation_database")
	reload()


func reload() -> void:
	_entries.clear()
	if not FileAccess.file_exists(DATA_PATH):
		push_error("[Observation] 找不到物件信息文件：%s" % DATA_PATH)
		return
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(DATA_PATH))
	if parse_error != OK:
		push_error("[Observation] JSON 第 %d 行解析失败：%s" % [json.get_error_line(), json.get_error_message()])
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("[Observation] JSON 根节点必须是对象")
		return
	for raw_key: Variant in (json.data as Dictionary).keys():
		var observation_id := str(raw_key)
		if observation_id.begins_with("_"):
			continue
		var raw_entry: Variant = (json.data as Dictionary)[raw_key]
		if typeof(raw_entry) != TYPE_DICTIONARY:
			push_error("[Observation] %s 必须是 JSON 对象" % observation_id)
			continue
		_entries[observation_id] = raw_entry
	_validate_entries()
	database_loaded.emit(_entries.size())


func get_entry(observation_id: String) -> Dictionary:
	if not _entries.has(observation_id):
		push_error("[Observation] 未定义的物件信息 ID：%s" % observation_id)
		return {}
	return (_entries[observation_id] as Dictionary).duplicate(true)


func has_observation(observation_id: String) -> bool:
	return _entries.has(observation_id)


func get_all_ids() -> Array:
	return _entries.keys()


func _validate_entries() -> void:
	var dialogue_database := get_tree().get_first_node_in_group(&"dialogue_database") as DialogueDatabase
	for raw_id: Variant in _entries.keys():
		var observation_id := str(raw_id)
		var entry: Dictionary = _entries[raw_id]
		for field: String in ["title", "body", "dialogue_id"]:
			if typeof(entry.get(field, null)) != TYPE_STRING or str(entry.get(field, "")).is_empty():
				push_error("[Observation] %s 的 %s 必须是非空字符串" % [observation_id, field])
		var dialogue_id := str(entry.get("dialogue_id", ""))
		if dialogue_database != null and not dialogue_id.is_empty() and not dialogue_database.has_dialogue(dialogue_id):
			push_error("[Observation] %s 指向不存在的对白 ID：%s" % [observation_id, dialogue_id])
