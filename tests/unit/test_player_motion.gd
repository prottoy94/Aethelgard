extends GutTest
## Camera-relative movement math (Player.input_to_world / yaw_of).


func test_up_moves_away_from_camera_at_yaw_zero() -> void:
	assert_almost_eq(Player.input_to_world(Vector2(0, -1), 0.0), Vector3(0, 0, -1), Vector3.ONE * 0.001)
	assert_almost_eq(Player.input_to_world(Vector2(1, 0), 0.0), Vector3(1, 0, 0), Vector3.ONE * 0.001)


func test_rotated_camera_rotates_movement() -> void:
	# Camera orbited 90 degrees (yaw = PI/2): its forward is now -X, so "up" must move towards -X.
	assert_almost_eq(Player.input_to_world(Vector2(0, -1), PI / 2.0), Vector3(-1, 0, 0), Vector3.ONE * 0.001)


func test_movement_matches_camera_forward() -> void:
	for yaw: float in [0.0, 0.7, 2.0, -2.5]:
		var camera_forward := -CameraRig.follow_offset(yaw, -42.0, 10.0)
		camera_forward.y = 0.0
		var up := Player.input_to_world(Vector2(0, -1), yaw)
		assert_almost_eq(up, camera_forward.normalized(), Vector3.ONE * 0.001, "yaw %s" % yaw)


func test_yaw_of_points_forward_along_direction() -> void:
	for dir: Vector3 in [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-0.6, 0, 0.8)]:
		var yaw := Player.yaw_of(dir)
		var forward := Vector3(-sin(yaw), 0, -cos(yaw))
		assert_almost_eq(forward, dir.normalized(), Vector3.ONE * 0.001)
