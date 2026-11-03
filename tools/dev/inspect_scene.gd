extends SceneTree
## Dev tool: prints the node tree, skeleton bones and animations of an imported model.
## Usage: godot --headless --path . --script res://tools/dev/inspect_scene.gd -- res://path/to/model.glb


func _init() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var scene: Node = (load(path) as PackedScene).instantiate()
	_print_tree(scene, 0)
	scene.free()
	quit()


func _print_tree(node: Node, depth: int) -> void:
	var line := "%s%s (%s)" % ["  ".repeat(depth), node.name, node.get_class()]
	if node is Skeleton3D:
		var sk := node as Skeleton3D
		var names: Array[String] = []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		line += " %d bones: %s" % [sk.get_bone_count(), ", ".join(names)]
	elif node is MeshInstance3D:
		line += " surfaces=%d" % (node as MeshInstance3D).mesh.get_surface_count()
	elif node is AnimationPlayer:
		var ap := node as AnimationPlayer
		var anims: Array[String] = []
		for anim_name in ap.get_animation_list():
			anims.append("%s(%.2fs)" % [anim_name, ap.get_animation(anim_name).length])
		line += " %d animations: %s" % [anims.size(), ", ".join(anims)]
	print(line)
	if depth < 6:
		for child in node.get_children():
			_print_tree(child, depth + 1)
