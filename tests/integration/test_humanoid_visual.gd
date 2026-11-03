extends GutTest
## HumanoidVisual with the CC0 stand-in mannequin: picks idle/walk/run/dash from movement, scales playback to
## the movement speed, plays one-shot actions, holds the staff, and is scaled to Aurelia's height.
## The animation library is a git-ignored asset, so these tests are skipped if it isn't on this machine.

const ANIM_SET_PATH := "res://data/animations/humanoid_default.tres"
const LIBRARY_PATH := "res://assets/animations/quaternius_ual/AnimationLibrary_Godot_Standard.glb"

var visual: HumanoidVisual
var anim_set: HumanoidAnimSet


func before_each() -> void:
	if not ResourceLoader.exists(LIBRARY_PATH):
		return
	anim_set = load(ANIM_SET_PATH)
	visual = HumanoidVisual.new()
	visual.anim_set = anim_set
	visual.model_scene = anim_set.library_scene
	visual.stand_in_tint = Color.PLUM
	add_child_autofree(visual)


func _skip_if_missing() -> bool:
	if visual == null:
		pending("Animation library not installed (git-ignored asset): " + LIBRARY_PATH)
		return true
	return false


func test_starts_idle_and_uses_general_skeleton() -> void:
	if _skip_if_missing():
		return
	assert_eq(visual.current_animation, anim_set.idle)
	assert_eq(visual.skeleton.name, &"GeneralSkeleton")
	assert_true(visual.skeleton.unique_name_in_owner)


func test_movement_picks_walk_run_and_dash() -> void:
	if _skip_if_missing():
		return
	visual.update_motion(0.3, false, 0.016, 1.5)
	assert_eq(visual.current_animation, anim_set.walk)
	visual.update_motion(1.0, false, 0.016, 5.0)
	assert_eq(visual.current_animation, anim_set.run)
	visual.update_motion(1.0, true, 0.016, 15.0)
	assert_eq(visual.current_animation, anim_set.dash)
	visual.update_motion(0.0, false, 0.016, 0.0)
	assert_eq(visual.current_animation, anim_set.idle)


func test_playback_scale_matches_speed_within_limits() -> void:
	if _skip_if_missing():
		return
	var native := anim_set.run_native_speed * visual.target_height / anim_set.source_height
	assert_almost_eq(visual.playback_scale(native, anim_set.run_native_speed), 1.0, 0.001)
	assert_eq(visual.playback_scale(100.0, anim_set.run_native_speed), anim_set.max_speed_scale)
	assert_eq(visual.playback_scale(0.01, anim_set.run_native_speed), anim_set.min_speed_scale)


func test_action_plays_and_holds_over_locomotion() -> void:
	if _skip_if_missing():
		return
	var length := visual.play_action(anim_set.cast)
	assert_gt(length, 0.0)
	visual.update_motion(1.0, false, 0.016, 5.0)
	assert_eq(visual.animation_player.current_animation, String(anim_set.cast), "locomotion waits for the action")
	assert_eq(visual.play_action(&"NoSuchAnimation"), 0.0)


func test_scaled_to_target_height_and_holds_staff() -> void:
	if _skip_if_missing():
		return
	var head := visual.skeleton.find_bone(&"Head")
	var head_y := (visual.skeleton.global_transform * visual.skeleton.get_bone_global_rest(head)).origin.y
	assert_almost_eq(head_y / 0.852, visual.target_height, 0.05, "about 1.6 m tall")
	var staffs := visual.find_children("*", "AureliaStaff", true, false)
	assert_eq(staffs.size(), 1, "staff attached to the hand")
