class_name DialogueCatalog
extends RefCounted

const DEFAULT_PATH := "res://data/dialogue.json"

var entries: Dictionary = {}
var load_error := ""


func _init(path := DEFAULT_PATH) -> void:
	load_from_file(path)


func load_from_file(path: String) -> bool:
	entries.clear()
	load_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_error = "无法打开对白文件：%s" % path
		push_error("[DialogueCatalog] %s" % load_error)
		return false
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		load_error = "对白 JSON 第 %d 行解析失败：%s" % [json.get_error_line(), json.get_error_message()]
		push_error("[DialogueCatalog] %s" % load_error)
		return false
	var root_data = json.data
	if not root_data is Dictionary or not root_data.has("entries") or not root_data.entries is Dictionary:
		load_error = "对白文件缺少 entries 字典"
		push_error("[DialogueCatalog] %s" % load_error)
		return false
	entries = root_data.entries.duplicate(true)
	return true


func has_entry(dialogue_id: String) -> bool:
	return entries.has(dialogue_id)


func get_entry(dialogue_id: String) -> Dictionary:
	if entries.has(dialogue_id):
		return (entries[dialogue_id] as Dictionary).duplicate(true)
	push_error("[DialogueCatalog] 未找到对白 ID：%s" % dialogue_id)
	return {
		"speaker": "",
		"text": "[%s]" % dialogue_id,
		"emotion": "",
		"blocking": false,
		"duration": 1.0,
	}


func size() -> int:
	return entries.size()
