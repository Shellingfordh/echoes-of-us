extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame

	var daughter_sprite := chapter.get_node("World/Actors/Daughter/Sprite2D") as AnimatedSprite2D
	var mother_sprite := chapter.get_node("World/Actors/Mother/Sprite2D") as AnimatedSprite2D
	assert(daughter_sprite != null and mother_sprite != null)
	assert(daughter_sprite.sprite_frames.resource_path == "res://resources/chapter3_yunian_frames.tres")
	assert(mother_sprite.sprite_frames.resource_path == "res://resources/chapter3_yuxiulan_frames.tres")
	for sprite in [daughter_sprite, mother_sprite]:
		for animation in [&"idle", &"walk", &"jump", &"fall", &"anchor", &"climb", &"special"]:
			assert(sprite.sprite_frames.has_animation(animation), "%s missing %s" % [sprite.name, animation])

	chapter.start_game()
	await physics_frame
	var daughter: Dictionary = chapter.daughter
	var mother: Dictionary = chapter.mother
	_reset_state(daughter)
	assert(chapter._character_animation(daughter) == &"idle")
	daughter["vx"] = 80.0
	assert(chapter._character_animation(daughter) == &"walk")
	daughter["on_ground"] = false
	daughter["vy"] = -100.0
	assert(chapter._character_animation(daughter) == &"jump")
	daughter["vy"] = 100.0
	assert(chapter._character_animation(daughter) == &"fall")
	daughter["climbing"] = true
	assert(chapter._character_animation(daughter) == &"climb")
	_reset_state(daughter)
	daughter["anchored"] = true
	assert(chapter._character_animation(daughter) == &"anchor")

	chapter.debug_load_level(1)
	_reset_state(daughter)
	daughter["x"] = 1800.0
	assert(chapter._character_animation(daughter) == &"special")
	_reset_state(mother)
	mother["pushing"] = true
	assert(chapter._character_animation(mother) == &"special")

	assert(not FileAccess.get_file_as_string("res://scenes/chapter3/chapter3.tscn").contains("playerGrey"))
	assert(not FileAccess.get_file_as_string("res://scripts/chapter3/chapter3.gd").contains("playerGrey"))
	print("[CHAPTER03_CHARACTER_ART] PASS distinct adult sprites and seven gameplay animation states")
	quit(0)


func _reset_state(character: Dictionary) -> void:
	character["anchored"] = false
	character["climbing"] = false
	character["pushing"] = false
	character["on_ground"] = true
	character["vx"] = 0.0
	character["vy"] = 0.0
