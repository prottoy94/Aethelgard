class_name ScenicViewpoint
extends Area3D
## Entering this area swings the camera to a low, wide vista shot; leaving swings it back (FR-CAM-03).
## Give it a CollisionShape3D child for the trigger volume and a Marker3D for the camera pose.

const PLAYER_LAYER := 1 << 1  # layer 2

@export var camera_marker: Marker3D
@export var fov := 55.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func camera_transform() -> Transform3D:
	return camera_marker.global_transform


func _on_body_entered(body: Node3D) -> void:
	var rig := _rig()
	if body is Player and rig:
		rig.enter_scenic(self)


func _on_body_exited(body: Node3D) -> void:
	var rig := _rig()
	if body is Player and rig:
		rig.exit_scenic(self)


func _rig() -> CameraRig:
	return get_tree().get_first_node_in_group(&"camera_rig") as CameraRig
