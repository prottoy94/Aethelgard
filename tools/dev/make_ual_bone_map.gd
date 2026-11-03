extends SceneTree
## Dev tool: writes the BoneMap that maps the Quaternius Universal Animation Library rig (Rigify "DEF-" bones)
## onto Godot's standard humanoid skeleton, so its animations can drive any humanoid (e.g. the VRoid Aurelia).
## Usage: godot --headless --path . --script res://tools/dev/make_ual_bone_map.gd

const OUT := "res://assets/animations/quaternius_ual/ual_bone_map.tres"
const SIDES := {"Left": "L", "Right": "R"}
const FINGERS := {"Thumb": "thumb", "Index": "f_index", "Middle": "f_middle", "Ring": "f_ring", "Little": "f_pinky"}


func _init() -> void:
	var map := {
		"Root": "root", "Hips": "DEF-hips", "Spine": "DEF-spine.001", "Chest": "DEF-spine.002",
		"UpperChest": "DEF-spine.003", "Neck": "DEF-neck", "Head": "DEF-head",
	}
	for side: String in SIDES:
		var s: String = SIDES[side]
		map[side + "Shoulder"] = "DEF-shoulder.%s" % s
		map[side + "UpperArm"] = "DEF-upper_arm.%s" % s
		map[side + "LowerArm"] = "DEF-forearm.%s" % s
		map[side + "Hand"] = "DEF-hand.%s" % s
		map[side + "UpperLeg"] = "DEF-thigh.%s" % s
		map[side + "LowerLeg"] = "DEF-shin.%s" % s
		map[side + "Foot"] = "DEF-foot.%s" % s
		map[side + "Toes"] = "DEF-toe.%s" % s
		for finger: String in FINGERS:
			var f: String = FINGERS[finger]
			var parts: Array = ["Metacarpal", "Proximal", "Distal"] if finger == "Thumb" else ["Proximal", "Intermediate", "Distal"]
			for i in 3:
				map["%s%s%s" % [side, finger, parts[i]]] = "DEF-%s.0%d.%s" % [f, i + 1, s]
	var bone_map := BoneMap.new()
	bone_map.profile = SkeletonProfileHumanoid.new()
	var missing: Array[String] = []
	for profile_bone: String in map:
		if bone_map.profile.find_bone(profile_bone) == -1:
			missing.append(profile_bone)
		bone_map.set_skeleton_bone_name(profile_bone, map[profile_bone])
	print("mapped %d bones; not in profile: %s" % [map.size(), missing])
	print("save: ", error_string(ResourceSaver.save(bone_map, OUT)))
	quit()
