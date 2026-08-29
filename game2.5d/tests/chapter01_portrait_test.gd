extends SceneTree


const CHAPTER_ONE_IDS := [
	"D001", "D002", "D003", "D004", "D005", "D006", "D007", "D008",
	"D009", "D010", "D011", "D012", "D013", "D014", "D015", "D016",
	"D017", "D018", "D041", "D042", "D043", "D044", "D045", "D046", "D047",
]

const FORMER_MONOLOGUE_IDS := [
	"D001", "D002", "D003", "D004", "D015", "D016", "D017",
	"D041", "D042", "D043", "D044", "D045", "D046", "D047",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame

	var database := main.get_node("DialogueDatabase") as DialogueDatabase
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	dialogue.characters_per_second = 0.0
	dialogue.fade_duration = 0.0

	for dialogue_id in CHAPTER_ONE_IDS:
		var entry := database.get_entry(dialogue_id)
		var portrait_path := str(entry.get("portrait", ""))
		assert(entry.get("mode") == "dialogue", "%s 没有使用对白框" % dialogue_id)
		assert(not portrait_path.is_empty(), "%s 缺少 portrait" % dialogue_id)
		assert(ResourceLoader.exists(portrait_path), "%s 立绘不存在：%s" % [dialogue_id, portrait_path])

	for dialogue_id in FORMER_MONOLOGUE_IDS:
		assert(not bool(database.get_entry(dialogue_id).get("blocking", true)))

	dialogue.play("D001")
	await process_frame
	var first_texture := dialogue.portrait_texture.texture
	assert(dialogue.dialogue_frame.visible and not dialogue.monologue_frame.visible)
	assert(dialogue.portrait_texture.visible and first_texture != null)

	dialogue.play("D002")
	await process_frame
	assert(dialogue.portrait_texture.texture != null)
	assert(dialogue.portrait_texture.texture != first_texture, "D001/D002 没有切换表情立绘")
	dialogue._finish_immediately(false)

	print("[CHAPTER01_PORTRAIT] PASS entries=25 former_monologues=14 expression_switch=true")
	quit(0)
