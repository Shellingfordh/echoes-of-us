extends SceneTree

const REQUIRED_IMAGES := [
	{"path": "res://assets/characters/character_daughter_adult_neutral.png", "size": Vector2i(512, 768), "alpha": true},
	{"path": "res://assets/characters/character_daughter_child_neutral.png", "size": Vector2i(512, 768), "alpha": true},
	{"path": "res://assets/characters/character_mother_adult_neutral.png", "size": Vector2i(512, 768), "alpha": true},
	{"path": "res://assets/characters/character_mother_young_neutral.png", "size": Vector2i(512, 768), "alpha": true},
	{"path": "res://assets/environments/environment_apartment.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/environments/environment_corridor.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/environments/environment_home.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/environments/environment_memory_street.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/environments/environment_prologue_sewing_shop.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/environments/environment_rooftop.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/environments/environment_warehouse.png", "size": Vector2i(1600, 720), "alpha": false},
	{"path": "res://assets/props/prop_bicycle.png", "alpha": true},
	{"path": "res://assets/props/prop_moving_box.png", "alpha": true},
	{"path": "res://assets/props/prop_suitcase.png", "alpha": true},
	{"path": "res://assets/props/prop_warehouse_crate.png", "alpha": true},
	{"path": "res://assets/props/prop_yellow_umbrella.png", "alpha": true},
]

const SOURCE_FILES := [
	"res://scripts/main.gd",
	"res://scripts/graybox_world.gd",
	"res://scripts/player.gd",
	"res://scripts/mother.gd",
	"res://scripts/tie_line.gd",
	"res://scripts/prototype_ui.gd",
	"res://scripts/audio_director.gd",
]

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_audit_project_settings()
	_audit_images()
	_audit_documented_scope()
	_audit_source_hygiene()
	await _audit_runtime_surface()

	if _failures == 0:
		print("[CompletionAudit] PASS - %d checks cover runtime, assets, input, UI and documented scope" % _checks)
	else:
		push_error("[CompletionAudit] FAIL - %d of %d checks failed" % [_failures, _checks])
	quit(1 if _failures > 0 else 0)


func _audit_project_settings() -> void:
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 1280, "viewport width remains 1280")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 720, "viewport height remains 720")
	_check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) == "gl_compatibility", "Compatibility renderer remains selected")
	_check(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")


func _audit_images() -> void:
	_check(REQUIRED_IMAGES.size() == 16, "the first production pass contains all 16 required runtime images")
	for spec: Dictionary in REQUIRED_IMAGES:
		var path := str(spec.path)
		_check(FileAccess.file_exists(path), "%s exists" % path.get_file())
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_check(not image.is_empty(), "%s decodes" % path.get_file())
		if image.is_empty():
			continue
		if spec.has("size"):
			_check(image.get_size() == spec.size, "%s has the expected runtime dimensions" % path.get_file())
		var has_alpha := image.detect_alpha() != Image.ALPHA_NONE
		_check(has_alpha == bool(spec.alpha), "%s has the expected alpha behavior" % path.get_file())
		var file := FileAccess.open(path, FileAccess.READ)
		_check(file != null and file.get_length() < 8 * 1024 * 1024, "%s stays below the 8 MB runtime budget" % path.get_file())


func _audit_documented_scope() -> void:
	var implementation := FileAccess.get_file_as_string("res://../docs/level-design/CURRENT_IMPLEMENTATION.md")
	_check(implementation.count("SR-") == 16, "the current implementation index covers SR-001 through SR-016")
	for requirement_number in range(1, 17):
		_check(implementation.contains("SR-%03d" % requirement_number), "SR-%03d is documented" % requirement_number)
	var manifest := FileAccess.get_file_as_string("res://assets/ASSET_MANIFEST.md")
	for spec: Dictionary in REQUIRED_IMAGES:
		var asset_id := str(spec.path).get_file().get_basename()
		_check(manifest.contains(asset_id), "%s is recorded in the asset manifest" % asset_id)


func _audit_source_hygiene() -> void:
	for path in SOURCE_FILES:
		var source := FileAccess.get_file_as_string(path)
		_check(not source.is_empty(), "%s is readable" % path.get_file())
		_check(not source.contains("TODO") and not source.contains("FIXME"), "%s has no unresolved TODO or FIXME marker" % path.get_file())


func _audit_runtime_surface() -> void:
	var packed_scene := load("res://scenes/main/main.tscn") as PackedScene
	_check(packed_scene != null, "main scene loads for runtime inspection")
	if packed_scene == null:
		return
	var game := packed_scene.instantiate()
	game.set("test_mode", true)
	root.add_child(game)
	await process_frame
	await process_frame

	var world := game.get_node_or_null("GrayboxWorld") as FullDemoWorld
	var player := game.get_node_or_null("Player") as EchoesPlayer
	var ui := game.get_node_or_null("PrototypeUI") as PrototypeUI
	var tie_line := game.get_node_or_null("TieLine") as TieLine
	_check(world != null and world._background_textures.size() == 7, "all seven chapter layouts have integrated backgrounds")
	_check(player != null and player.has_method("set_presentation_mode"), "player supports cinematic presentation mode")
	_check(tie_line != null and TieLine.TieState.size() == 5, "the tie line exposes all five authored states")
	_check(ui != null, "runtime UI loads")
	if ui != null:
		var buttons := [ui.resume_button, ui.sound_button, ui.motion_button, ui.restart_button, ui.complete_restart_button]
		for button: Button in buttons:
			_check(button.custom_minimum_size.y >= 44.0, "%s meets the 44 px target-height baseline" % button.name)
			_check(button.focus_mode != Control.FOCUS_NONE, "%s remains keyboard focusable" % button.name)

	for action in [&"move_left", &"move_right", &"move_up", &"move_down", &"interact", &"switch_character", &"tie_control", &"restart", &"pause_menu", &"toggle_mute", &"toggle_reduced_motion"]:
		_check(InputMap.has_action(action), "%s input action is registered" % action)
	var has_mouse_interaction := false
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventMouseButton:
			has_mouse_interaction = true
	_check(has_mouse_interaction, "interaction supports mouse input as well as keyboard input")

	var audio_director := game.get_node_or_null("AudioDirector")
	if audio_director != null:
		audio_director.call("shutdown")
	game.queue_free()
	await process_frame


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("[CompletionAudit] PASS - %s" % description)
	else:
		_failures += 1
		push_error("[CompletionAudit] FAIL - %s" % description)
