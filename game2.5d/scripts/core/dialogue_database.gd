class_name DialogueDatabase
extends Node

## JSON 对白数据库。剧情同学只维护 data/dialogues.json；游戏逻辑只引用对白 ID。

signal database_loaded(entry_count: int)

const DATA_PATH := "res://data/dialogues.json"
const END_DIALOGUE_ID := "END"

var _entries: Dictionary = {}


func _ready() -> void:
	add_to_group(&"dialogue_database")
	reload()


func reload() -> void:
	_entries.clear()
	if not FileAccess.file_exists(DATA_PATH):
		push_error("[Dialogue] 找不到对白文件：%s" % DATA_PATH)
		return

	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(DATA_PATH))
	if parse_error != OK:
		push_error(
			"[Dialogue] JSON 第 %d 行解析失败：%s"
			% [json.get_error_line(), json.get_error_message()]
		)
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("[Dialogue] JSON 根节点必须是对象：%s" % DATA_PATH)
		return

	for raw_key: Variant in (json.data as Dictionary).keys():
		var dialogue_id := str(raw_key)
		if dialogue_id.begins_with("_"):
			continue
		var raw_entry: Variant = (json.data as Dictionary)[raw_key]
		if typeof(raw_entry) != TYPE_DICTIONARY:
			push_error("[Dialogue] %s 必须是 JSON 对象" % dialogue_id)
			continue
		_entries[dialogue_id] = raw_entry

	_validate_entries()
	database_loaded.emit(_entries.size())


func get_entry(dialogue_id: String) -> Dictionary:
	if not _entries.has(dialogue_id):
		push_error("[Dialogue] 未定义的对白 ID：%s" % dialogue_id)
		return {}
	return (_entries[dialogue_id] as Dictionary).duplicate(true)


func get_lines(dialogue_id: String) -> Array:
	var entry := get_entry(dialogue_id)
	if entry.is_empty():
		return []
	var lines: Variant = entry.get("lines", [])
	return lines as Array if typeof(lines) == TYPE_ARRAY else []


func get_speaker(dialogue_id: String) -> String:
	return str(get_entry(dialogue_id).get("speaker", ""))


func get_mode(dialogue_id: String) -> String:
	return str(get_entry(dialogue_id).get("mode", "dialogue"))


func get_next_id(dialogue_id: String) -> String:
	return str(get_entry(dialogue_id).get("next", END_DIALOGUE_ID))


func has_dialogue(dialogue_id: String) -> bool:
	return _entries.has(dialogue_id)


func get_all_ids() -> Array:
	return _entries.keys()


func _validate_entries() -> void:
	for raw_id: Variant in _entries.keys():
		var dialogue_id := str(raw_id)
		var entry: Dictionary = _entries[raw_id]
		var mode := str(entry.get("mode", "dialogue"))
		if mode != "dialogue" and mode != "monologue":
			push_error("[Dialogue] %s 的 mode 只能是 dialogue 或 monologue" % dialogue_id)

		var lines: Variant = entry.get("lines", [])
		if typeof(lines) != TYPE_ARRAY or (lines as Array).is_empty():
			push_error("[Dialogue] %s 至少需要一条 lines" % dialogue_id)
		elif not _all_lines_are_strings(lines as Array):
			push_error("[Dialogue] %s 的 lines 必须全部是字符串" % dialogue_id)

		var next_id := str(entry.get("next", END_DIALOGUE_ID))
		if next_id != END_DIALOGUE_ID and not _entries.has(next_id):
			push_error("[Dialogue] %s 的 next 指向不存在的 ID：%s" % [dialogue_id, next_id])


func _all_lines_are_strings(lines: Array) -> bool:
	for line: Variant in lines:
		if typeof(line) != TYPE_STRING:
			return false
	return true
