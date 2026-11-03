class_name HumanoidVisual
extends Node3D
## Animated humanoid model for a character: Aurelia's VRoid model (Phase 2b), or the CC0 mannequin as a stand-in.
## Plays the HumanoidAnimSet's animations on the model's skeleton (renamed to the unique "GeneralSkeleton",
## the name the retargeted animations address). Same interface as the placeholder (update_motion), plus play_action().

const STAND_IN_OUTLINE := 0.01

@export var model_scene: PackedScene
@export var anim_set: HumanoidAnimSet
@export var target_height := 1.6        ## m; the model is scaled to this height
@export var yaw_offset_deg := 180.0     ## glTF/VRM models face +Z; our characters face -Z
## If alpha > 0, the model's materials are replaced with this toon colour (for the grey stand-in mannequin).
@export var stand_in_tint := Color(0, 0, 0, 0)
@export var attach_staff := true
@export var staff_bone := &"RightHand"
## Staff pose relative to the hand bone. The hand bone's +Y points along the fingers (down when the arm hangs),
## so the staff is flipped to run upwards through the fist, parallel to the forearm.
@export var staff_offset := Transform3D(Basis.from_euler(Vector3(0, 0, PI)), Vector3(0, 0.07, 0.03))

var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var current_animation := &""
var _model: Node3D
var _scale := 1.0
var _action_time := 0.0
var _staff: AureliaStaff


func _ready() -> void:
	_model = model_scene.instantiate()
	add_child(_model)
	_model.rotation_degrees.y = yaw_offset_deg
	skeleton = _find_skeleton(_model)
	assert(skeleton != null, "HumanoidVisual: the model has no Skeleton3D")
	skeleton.name = &"GeneralSkeleton"
	skeleton.unique_name_in_owner = true
	_scale_to_height()
	if stand_in_tint.a > 0.0:
		_apply_tint(_model)
	_setup_animation_player()
	if attach_staff:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = staff_bone
		skeleton.add_child(attachment)
		_staff = AureliaStaff.new()
		_staff.transform = staff_offset
		attachment.add_child(_staff)
	_play(anim_set.idle, 1.0)


## Called every frame by the Player. speed = horizontal speed in m/s.
func update_motion(speed_ratio: float, dashing: bool, delta: float, speed := 0.0) -> void:
	if _staff:
		_staff.set_swing(speed_ratio)
	if _action_time > 0.0:
		_action_time -= delta
		if not dashing:
			return
	if dashing:
		_play(anim_set.dash, anim_set.dash_speed_scale)
	elif speed < 0.15:
		_play(anim_set.idle, 1.0)
	elif speed < anim_set.run_threshold:
		_play(anim_set.walk, playback_scale(speed, anim_set.walk_native_speed))
	else:
		_play(anim_set.run, playback_scale(speed, anim_set.run_native_speed))


## Plays a one-shot animation (cast, strike, hurt, interact...) over the locomotion. Returns its length in s.
func play_action(anim_name: StringName) -> float:
	if not animation_player.has_animation(anim_name):
		push_warning("HumanoidVisual: no animation %s" % anim_name)
		return 0.0
	current_animation = &""
	animation_player.play(anim_name, anim_set.blend_time)
	animation_player.speed_scale = 1.0
	_action_time = animation_player.get_animation(anim_name).length
	return _action_time


## Playback speed so the feet match the movement speed, clamped to keep the motion natural.
func playback_scale(speed: float, native_speed: float) -> float:
	# Retargeted strides scale with the character's size; the source speeds were measured at source_height.
	var native := native_speed * target_height / anim_set.source_height
	return clampf(speed / native, anim_set.min_speed_scale, anim_set.max_speed_scale)


func _play(anim_name: StringName, speed_scale: float) -> void:
	animation_player.speed_scale = speed_scale
	if anim_name == current_animation:
		return
	current_animation = anim_name
	animation_player.play(anim_name, anim_set.blend_time)


func _setup_animation_player() -> void:
	animation_player = _find_child_of_class(_model, "AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		_model.add_child(animation_player)
	if animation_player.has_animation(anim_set.idle):
		return  # the model already carries the library (e.g. the stand-in mannequin)
	var source := anim_set.library_scene.instantiate()
	var source_player := _find_child_of_class(source, "AnimationPlayer") as AnimationPlayer
	var library := source_player.get_animation_library(&"")
	source.free()
	if animation_player.has_animation_library(&""):
		animation_player.remove_animation_library(&"")
	animation_player.add_animation_library(&"", library)


func _scale_to_height() -> void:
	var head := skeleton.find_bone(&"Head")
	var head_height := skeleton.get_bone_global_rest(head).origin.y if head >= 0 else 0.0
	# Head bone sits ~85% of total height up (measured on the 1.83 m mannequin: 1.56 m).
	var model_height := head_height / 0.852 if head_height > 0.0 else anim_set.source_height
	_scale = target_height / model_height
	_model.scale = Vector3.ONE * _scale


func _apply_tint(node: Node) -> void:
	var mesh := node as MeshInstance3D
	if mesh:
		mesh.material_override = ToonMaterials.toon(stand_in_tint, 0.35, STAND_IN_OUTLINE)
	for child in node.get_children():
		_apply_tint(child)


func _find_skeleton(node: Node) -> Skeleton3D:
	return _find_child_of_class(node, "Skeleton3D") as Skeleton3D


func _find_child_of_class(node: Node, cls: String) -> Node:
	if node.is_class(cls):
		return node
	for child in node.get_children():
		var found := _find_child_of_class(child, cls)
		if found:
			return found
	return null
