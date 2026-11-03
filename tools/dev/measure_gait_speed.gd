extends SceneTree
## Dev tool: estimates how fast a looping in-place walk/run animation moves its feet (m/s), so the game can
## scale playback to the character's real speed and avoid foot sliding.
## Method: sample the foot bones; the speed of a planted foot moving backwards equals the walking speed.
## Usage: godot --headless --path . --script res://tools/dev/measure_gait_speed.gd -- <scene.glb> <anim> [<anim>...]

const SAMPLES := 120


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: Node = (load(args[0]) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame  # let the AnimationPlayer and skeleton finish setting up
	var player := _find(scene, "AnimationPlayer") as AnimationPlayer
	var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
	for anim_name in args.slice(1):
		var anim := player.get_animation(anim_name)
		player.play(anim_name)
		var speeds: Array[float] = []
		for foot_name: String in ["LeftFoot", "RightFoot"]:
			var foot := skeleton.find_bone(foot_name)
			var prev := Vector3.ZERO
			var min_y := INF
			var points: Array[Vector3] = []
			for i in SAMPLES + 1:
				player.seek(anim.length * i / SAMPLES, true)
				player.advance(0.0)
				skeleton.force_update_all_bone_transforms()
				var p := skeleton.get_bone_global_pose(foot).origin
				points.append(p)
				min_y = minf(min_y, p.y)
			var zs := points.map(func(v: Vector3) -> float: return v.z)
			print("  %s %s: stride (foot z range) %.2f m" % [anim_name, foot_name, zs.max() - zs.min()])
			for i in range(1, points.size()):
				var p := points[i]
				prev = points[i - 1]
				if p.y < min_y + 0.03:  # foot planted
					speeds.append(Vector2(p.x - prev.x, p.z - prev.z).length() / (anim.length / SAMPLES))
		speeds.sort()
		var median := speeds[speeds.size() / 2] if not speeds.is_empty() else 0.0
		print("%s: length %.2fs, planted-foot speed ~%.2f m/s (from %d samples)" % [anim_name, anim.length, median, speeds.size()])
	scene.queue_free()
	quit()


func _find(node: Node, cls: String) -> Node:
	if node.is_class(cls):
		return node
	for child in node.get_children():
		var found := _find(child, cls)
		if found:
			return found
	return null
