extends GutTest
## Camera math: follow offset, zoom clamping, smoothing.

const SETTINGS := preload("res://data/camera/follow_camera.tres")


func test_offset_behind_and_above_at_yaw_zero() -> void:
	var offset := CameraRig.follow_offset(0.0, -42.0, 13.5)
	assert_almost_eq(offset.length(), 13.5, 0.001)
	assert_gt(offset.y, 0.0, "camera is above the focus")
	assert_gt(offset.z, 0.0, "camera is on +Z, looking towards -Z")
	assert_almost_eq(rad_to_deg(asin(offset.y / offset.length())), 42.0, 0.01, "pitch is 42 degrees down")


func test_zoom_is_clamped() -> void:
	assert_eq(CameraRig.clamp_zoom(1.0, SETTINGS), SETTINGS.min_distance)
	assert_eq(CameraRig.clamp_zoom(99.0, SETTINGS), SETTINGS.max_distance)
	assert_eq(CameraRig.clamp_zoom(12.0, SETTINGS), 12.0)


func test_smoothing_is_frame_rate_independent() -> void:
	# Two half steps must equal one full step.
	var one_step := CameraRig.smoothing(10.0, 0.1)
	var half := CameraRig.smoothing(10.0, 0.05)
	assert_almost_eq(1.0 - (1.0 - half) * (1.0 - half), one_step, 0.0001)
