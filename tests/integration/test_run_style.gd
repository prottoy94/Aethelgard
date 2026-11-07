extends GutTest
## Aurelia's cute run (owner request 2026-11-06): the run style switches on while running and off when she walks or
## stands and shortens the stride (quicker playback).

const ANIM_SET := preload("res://data/animations/humanoid_default.tres")
const RUN_STYLE: RunStyle = preload("res://data/animations/aurelia_run_style.tres")


func _visual(style: RunStyle) -> HumanoidVisual:
	var visual := HumanoidVisual.new()
	visual.model_scene = ANIM_SET.library_scene
	visual.anim_set = ANIM_SET
	visual.run_style = style
	add_child_autofree(visual)
	return visual


func test_style_follows_running() -> void:
	var visual := _visual(RUN_STYLE)
	var modifier := visual._run_style_modifier
	assert_not_null(modifier, "the run style is added to the skeleton")
	visual.update_motion(1.0, false, 0.016, 5.0)
	assert_eq(modifier.target_weight, 1.0, "on while running")
	visual.update_motion(0.3, false, 0.016, 1.5)
	assert_eq(modifier.target_weight, 0.0, "off while walking")
	visual.update_motion(0.0, false, 0.016, 0.0)
	assert_eq(modifier.target_weight, 0.0, "off while standing")


func test_shorter_steps_play_quicker() -> void:
	var styled := _visual(RUN_STYLE)
	var plain := _visual(null)
	styled.update_motion(1.0, false, 0.016, 5.0)
	plain.update_motion(1.0, false, 0.016, 5.0)
	assert_gt(styled.animation_player.speed_scale, plain.animation_player.speed_scale, "quick little steps")
	assert_lt(RUN_STYLE.stride_scale, 1.0)
