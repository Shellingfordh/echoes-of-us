extends SceneTree
func _init():
    for p in ["res://resources/daughter2_frames.tres", "res://scenes/chapter2/chapter2.tscn"]:
        var r = load(p)
        if r == null:
            print("FAIL load: ", p); quit(1); return
        print("OK load: ", p)
    var sf = load("res://resources/daughter2_frames.tres")
    var names = []
    for a in sf.get_animation_names(): names.append(a)
    print("anims: ", names)
    for need in ["idle_down","idle_up","idle_left","idle_right","walk_down","walk_up","walk_left","walk_right","climb","bounce"]:
        if not sf.has_animation(need):
            print("MISSING anim: ", need); quit(1); return
    var ps = load("res://scenes/chapter2/chapter2.tscn")
    var inst = ps.instantiate()
    var spr = inst.get_node_or_null("Characters/Child/AnimatedSprite2D")
    print("child sprite frames: ", spr.sprite_frames.resource_path if spr else "NO NODE")
    print("child anim: ", spr.animation if spr else "-")
    inst.free()
    print("ALL OK")
    quit(0)
