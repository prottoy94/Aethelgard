class_name RunStyleModifier
extends SkeletonModifier3D
## Restyles the run animation after it plays (RunStyle): upright posture, arms low with forearms and hands flared out to
## the sides, shorter steps, a head sway and a little hop. `weight` (0–1) fades it in while running. The head lift
## (head_lift_deg) applies in every pose. Arm and torso
## changes are made in the skeleton's space by turning each bone towards a direction, so they work whatever the bone axes.

var style: RunStyle
var weight := 0.0          ## current strength
var target_weight := 0.0   ## set by HumanoidVisual: 1 while running
var _time := 0.0
var _bones := {}


func setup(skeleton: Skeleton3D, run_style: RunStyle) -> void:
	style = run_style
	for bone_name: StringName in [&"Hips", &"Spine", &"Neck", &"Head", &"LeftUpperArm", &"LeftLowerArm", &"LeftHand",
			&"RightUpperArm", &"RightLowerArm", &"RightHand", &"LeftUpperLeg", &"LeftLowerLeg", &"RightUpperLeg",
			&"RightLowerLeg"]:
		_bones[bone_name] = skeleton.find_bone(bone_name)


func _process_modification_with_delta(delta: float) -> void:
	if style == null:
		return
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if style.head_lift_deg != 0.0:  # in every pose: the idle clip looks at the ground, the camera is high
		var lift := deg_to_rad(-style.head_lift_deg)
		_turn(skeleton, &"Neck", Quaternion(Vector3.RIGHT, lift * 0.4), 1.0)
		_turn(skeleton, &"Head", Quaternion(Vector3.RIGHT, lift * 0.6), 1.0)
	weight = move_toward(weight, target_weight, style.blend_speed * delta)
	if weight <= 0.001:
		return
	_time += delta
	# Shorter steps: leg swing pulled towards the rest pose.
	for leg: StringName in [&"LeftUpperLeg", &"LeftLowerLeg", &"RightUpperLeg", &"RightLowerLeg"]:
		var bone: int = _bones.get(leg, -1)
		if bone >= 0:
			var rest := skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
			var pose := skeleton.get_bone_pose_rotation(bone)
			skeleton.set_bone_pose_rotation(bone, pose.slerp(rest.slerp(pose, style.stride_scale), weight))
	# Upright: turn the spine back against the jog's forward lean (around the skeleton's X axis).
	_turn(skeleton, &"Spine", Quaternion(Vector3.RIGHT, deg_to_rad(-style.torso_upright_deg)), weight)
	# Arms low, forearms and hands flared out (mirrored for the right side).
	for side: float in [1.0, -1.0]:
		var prefix := "Left" if side > 0.0 else "Right"
		_aim(skeleton, StringName(prefix + "UpperArm"), StringName(prefix + "LowerArm"), _mirror(style.upper_arm_dir, side))
		_aim(skeleton, StringName(prefix + "LowerArm"), StringName(prefix + "Hand"), _mirror(style.forearm_dir, side))
	# A little head sway and hop with the steps.
	var phase := _time * TAU * style.step_rate
	_turn(skeleton, &"Head", Quaternion(Vector3.BACK, deg_to_rad(style.head_sway_deg) * sin(phase)), weight)
	var hips: int = _bones.get(&"Hips", -1)
	if hips >= 0:
		var hip_position := skeleton.get_bone_pose_position(hips)
		skeleton.set_bone_pose_position(hips, hip_position + Vector3(0, absf(sin(phase)) * style.bounce * weight, 0))


static func _mirror(dir: Vector3, side: float) -> Vector3:
	return Vector3(dir.x * side, dir.y, dir.z).normalized()


## Turns bone `bone_name` by `turn_by` (skeleton space) around its own origin, by `amount`.
func _turn(skeleton: Skeleton3D, bone_name: StringName, turn_by: Quaternion, amount: float) -> void:
	var bone: int = _bones.get(bone_name, -1)
	if bone < 0:
		return
	var global := skeleton.get_bone_global_pose(bone)
	var turned := Basis(Quaternion.IDENTITY.slerp(turn_by, amount)) * global.basis
	skeleton.set_bone_global_pose(bone, Transform3D(turned, global.origin))


## Turns `bone_name` so the direction to `child_name` moves towards `direction` (skeleton space).
func _aim(skeleton: Skeleton3D, bone_name: StringName, child_name: StringName, direction: Vector3) -> void:
	var bone: int = _bones.get(bone_name, -1)
	var child: int = _bones.get(child_name, -1)
	if bone < 0 or child < 0:
		return
	var global := skeleton.get_bone_global_pose(bone)
	var current := (skeleton.get_bone_global_pose(child).origin - global.origin).normalized()
	if current.length_squared() < 0.5:
		return
	var turn := Quaternion(current, direction)
	_turn(skeleton, bone_name, turn, weight * style.arm_weight)
