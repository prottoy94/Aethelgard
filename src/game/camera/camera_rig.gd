class_name CameraRig
extends Node3D
## The hybrid camera (3D_PROPOSAL.md §3): a high-angle follow camera that rotates (Q/R, middle-mouse drag),
## zooms (mouse wheel) and resets (Z); blends to scenic shots at ScenicViewpoints; and fades out
## walls and trees that block the view of the target (occlusion fade, FR-CAM-04).
## The rig node itself is the focus point; the Camera3D child is placed in world space.

const OCCLUSION_MASK := (1 << 0) | (1 << 10)  # world + camera_occluder
const OCCLUSION_SAMPLE_HEIGHTS: Array[float] = [0.3, 1.0, 1.6]
const MAX_HITS_PER_RAY := 4

@export var settings: CameraSettings
@export var target: Node3D

var camera: Camera3D
var _yaw := 0.0
var _target_yaw := 0.0
var _distance := 0.0
var _target_distance := 0.0
var _dragging := false
var _scenic: ScenicViewpoint
var _last_scenic: ScenicViewpoint
var _blend := 0.0
var _faded: Dictionary[GeometryInstance3D, float] = {}


func _ready() -> void:
	add_to_group(&"camera_rig")
	_distance = settings.distance
	_target_distance = settings.distance
	camera = Camera3D.new()
	camera.top_level = true
	camera.fov = settings.fov
	add_child(camera)
	camera.make_current()
	snap_to_target()


## Yaw used for camera-relative movement. Stays on the follow camera during scenic shots.
func control_yaw() -> float:
	return _yaw


func snap_to_target() -> void:
	if target:
		global_position = _focus_point()
	_update_camera()


func enter_scenic(viewpoint: ScenicViewpoint) -> void:
	_scenic = viewpoint
	_last_scenic = viewpoint


func exit_scenic(viewpoint: ScenicViewpoint) -> void:
	if _scenic == viewpoint:
		_scenic = null


func is_scenic() -> bool:
	return _scenic != null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		_target_distance = clamp_zoom(_target_distance - settings.zoom_step, settings)
	elif event.is_action_pressed("camera_zoom_out"):
		_target_distance = clamp_zoom(_target_distance + settings.zoom_step, settings)
	elif event.is_action_pressed("camera_reset"):
		_target_yaw = 0.0
		_target_distance = settings.distance
	elif event.is_action("camera_drag"):
		_dragging = event.is_pressed()
	elif _dragging and event is InputEventMouseMotion:
		_target_yaw -= deg_to_rad((event as InputEventMouseMotion).relative.x * settings.drag_sensitivity)


func _process(delta: float) -> void:
	var turn := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	_target_yaw -= deg_to_rad(settings.rotate_speed_deg) * turn * delta
	_yaw = lerp_angle(_yaw, _target_yaw, smoothing(settings.rotate_smoothing, delta))
	_distance = lerpf(_distance, _target_distance, smoothing(settings.zoom_smoothing, delta))
	if target:
		global_position = global_position.lerp(_focus_point(), smoothing(settings.follow_smoothing, delta))
	_blend = move_toward(_blend, 1.0 if _scenic else 0.0, settings.scenic_blend_speed * delta)
	_update_camera()


func _physics_process(delta: float) -> void:
	_update_occlusion(delta)


func _focus_point() -> Vector3:
	return target.global_position + Vector3(0, settings.focus_height, 0)


func _update_camera() -> void:
	var follow := Transform3D(Basis(), global_position + follow_offset(_yaw, settings.pitch_deg, _distance))
	follow = follow.looking_at(global_position, Vector3.UP)
	if _blend > 0.0 and _last_scenic:
		var weight := smoothstep(0.0, 1.0, _blend)
		camera.global_transform = follow.interpolate_with(_last_scenic.camera_transform(), weight)
		camera.fov = lerpf(settings.fov, _last_scenic.fov, weight)
	else:
		camera.global_transform = follow
		camera.fov = settings.fov


# --- Occlusion fade ------------------------------------------------------------------------

func _update_occlusion(delta: float) -> void:
	if target == null or not is_inside_tree():
		return
	var blocking: Dictionary[GeometryInstance3D, bool] = {}
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	for height in OCCLUSION_SAMPLE_HEIGHTS:
		var exclude: Array[RID] = []
		if target is CollisionObject3D:
			exclude.append((target as CollisionObject3D).get_rid())
		for i in MAX_HITS_PER_RAY:
			var query := PhysicsRayQueryParameters3D.create(from, target.global_position + Vector3(0, height, 0),
					OCCLUSION_MASK, exclude)
			query.collide_with_areas = true
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			exclude.append(hit.rid)
			var collider := hit.collider as Node
			var root := collider if collider is StaticBody3D else collider.get_parent()
			for geometry in _geometry_under(root):
				blocking[geometry] = true
	for geometry in blocking:
		if not _faded.has(geometry):
			_faded[geometry] = 0.0
	for geometry: GeometryInstance3D in _faded.keys():
		if not is_instance_valid(geometry):
			_faded.erase(geometry)
			continue
		var goal := settings.occlusion_fade if blocking.has(geometry) else 0.0
		var value := move_toward(_faded[geometry], goal, settings.occlusion_fade_speed * delta)
		geometry.set_instance_shader_parameter(&"fade", value)
		if value <= 0.0 and goal <= 0.0:
			_faded.erase(geometry)
		else:
			_faded[geometry] = value


func _geometry_under(node: Node) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	if node is GeometryInstance3D and not node is Label3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_geometry_under(child))
	return result


# --- Pure helpers (unit tested) --------------------------------------------------------------

## Camera position relative to the focus point for a given yaw (rad), pitch (deg, negative = looking down)
## and distance (m). With yaw 0 the camera sits on +Z and looks towards -Z.
static func follow_offset(yaw: float, pitch_deg: float, distance: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(pitch_deg))) * Vector3(0, 0, distance)


static func clamp_zoom(distance: float, camera_settings: CameraSettings) -> float:
	return clampf(distance, camera_settings.min_distance, camera_settings.max_distance)


## Frame-rate independent smoothing factor for lerp.
static func smoothing(rate: float, delta: float) -> float:
	return 1.0 - exp(-rate * delta)
