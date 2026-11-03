extends GutTest
## Camera rig in a physics world: walking into a ScenicViewpoint switches to the scenic shot, and a wall between
## the camera and the player gets the occlusion fade.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const SETTINGS := preload("res://data/camera/follow_camera.tres")

var world: Node3D
var player: Player
var rig: CameraRig


func before_each() -> void:
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.05, 0)
	world.add_child(player)
	rig = CameraRig.new()
	rig.settings = SETTINGS
	rig.target = player
	world.add_child(rig)
	player.camera_rig = rig
	await wait_physics_frames(5)


func after_each() -> void:
	Input.action_release(&"move_up")


func test_scenic_viewpoint_switches_camera() -> void:
	var viewpoint := ScenicViewpoint.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 4)
	shape.shape = box
	viewpoint.add_child(shape)
	var marker := Marker3D.new()
	viewpoint.add_child(marker)
	viewpoint.camera_marker = marker
	viewpoint.position = Vector3(0, 1.5, -6)
	world.add_child(viewpoint)
	assert_false(rig.is_scenic())
	Input.action_press(&"move_up")
	await wait_physics_frames(75)
	assert_true(rig.is_scenic(), "entered the viewpoint")
	Input.action_release(&"move_up")
	player.global_position = Vector3(0, 0.05, 10)
	await wait_physics_frames(5)
	assert_false(rig.is_scenic(), "left the viewpoint")


func test_wall_between_camera_and_player_fades() -> void:
	# The camera sits behind the player on +Z; put a wall halfway between them.
	var camera_pos := rig.camera.global_position
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 6, 0.5)
	shape.shape = box
	wall.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box.size
	mesh.mesh = box_mesh
	mesh.material_override = ToonMaterials.toon(Color.GRAY)
	wall.add_child(mesh)
	wall.position = Vector3(0, 3, camera_pos.z * 0.5)
	world.add_child(wall)
	await wait_physics_frames(30)
	assert_true(rig._faded.has(mesh), "the wall's mesh is being faded")
	assert_gt(rig._faded.get(mesh, 0.0), 0.5, "fade reached most of the target")
	wall.position = Vector3(20, 3, 0)  # move it out of the way
	await wait_physics_frames(30)
	assert_false(rig._faded.has(mesh), "fade removed once the view is clear")
