class_name Player
extends CharacterBody3D
## Aurelia, the player character. Movement is relative to the camera on the ground plane.
## Behaviour lives in StateMachine states (Idle, Move, Dash); tuning comes from `stats`.
## Visuals are the "Visual" child, so the placeholder can be swapped for the VRoid model later.

signal dashed
signal interact_target_changed(target: InteractableComponent)

@export var stats: MovementStats

## Set by the level. If empty, the first node in the "camera_rig" group is used.
var camera_rig: CameraRig
var facing_yaw := 0.0
var is_invulnerable: bool:
	get:
		return _invulnerable_time > 0.0
var dash_cooldown := Cooldown.new()

var _dash_buffer := 0.0
var _invulnerable_time := 0.0
var _interactables: Array[InteractableComponent] = []
var _interact_target: InteractableComponent

@onready var visual: Node3D = $Visual
@onready var state_machine: StateMachine = $StateMachine
@onready var _detector: Area3D = $InteractionDetector


func _ready() -> void:
	add_to_group(&"player")
	floor_snap_length = stats.floor_snap
	floor_max_angle = deg_to_rad(stats.max_floor_angle_deg)
	_detector.area_entered.connect(_on_area_entered)
	_detector.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	dash_cooldown.tick(delta)
	_dash_buffer = maxf(_dash_buffer - delta, 0.0)
	_invulnerable_time = maxf(_invulnerable_time - delta, 0.0)
	_update_interact_target()


func _process(delta: float) -> void:
	if visual.has_method(&"update_motion"):
		var horizontal := Vector2(velocity.x, velocity.z).length()
		visual.update_motion(horizontal / stats.walk_speed, state_machine.is_in(&"Dash"), delta, horizontal)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		request_dash()
	elif event.is_action_pressed("interact") and try_interact():
		get_viewport().set_input_as_handled()


# --- Used by states ------------------------------------------------------------------------

## Camera-relative movement direction from the move keys/stick (length 0–1).
func move_input() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return input_to_world(input, camera_yaw())


func camera_yaw() -> float:
	if camera_rig == null:
		camera_rig = get_tree().get_first_node_in_group(&"camera_rig") as CameraRig
	return camera_rig.control_yaw() if camera_rig else 0.0


## Remembers a dash press for a short time, so pressing just before the cooldown ends still dashes.
func request_dash() -> void:
	_dash_buffer = stats.dash_buffer_time


func consume_dash_request() -> bool:
	if _dash_buffer > 0.0 and dash_cooldown.is_ready():
		_dash_buffer = 0.0
		return true
	return false


## Makes Aurelia ignore hits for `seconds` (dash i-frames; later also after being hurt).
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_time = maxf(_invulnerable_time, seconds)


## Moves the horizontal velocity towards `target` and applies gravity, then slides.
func apply_movement(target: Vector3, rate: float, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= stats.gravity * delta
	move_and_slide()


func face_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	facing_yaw = lerp_angle(facing_yaw, yaw_of(direction), 1.0 - exp(-stats.turn_speed * delta))
	visual.rotation.y = facing_yaw


func facing_direction() -> Vector3:
	return Vector3(-sin(facing_yaw), 0.0, -cos(facing_yaw))


## Swaps the character model (e.g. placeholder → animated model) and keeps the facing direction.
func set_visual(new_visual: Node3D) -> void:
	remove_child(visual)
	visual.queue_free()
	new_visual.name = &"Visual"
	add_child(new_visual)
	visual = new_visual
	visual.rotation.y = facing_yaw


## Interacts with the nearest interactable in range. Returns true if something was used.
func try_interact() -> bool:
	if _interact_target == null or state_machine.is_in(&"Dash"):
		return false
	_interact_target.interact(self)
	return true


# --- Pure helpers (unit tested) --------------------------------------------------------------

## Converts stick/WASD input (x right, y down) into a world direction for a camera rotated by `yaw`.
## With yaw 0 the camera looks towards -Z, so "up" moves away from the camera.
static func input_to_world(input: Vector2, yaw: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)


## Yaw that makes a node's forward (-Z) point along `direction`.
static func yaw_of(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


# --- Interaction -----------------------------------------------------------------------------

func _on_area_entered(area: Area3D) -> void:
	var interactable := area as InteractableComponent
	if interactable and not _interactables.has(interactable):
		_interactables.append(interactable)


func _on_area_exited(area: Area3D) -> void:
	_interactables.erase(area)


func _update_interact_target() -> void:
	var nearest: InteractableComponent = null
	var best := INF
	for candidate in _interactables:
		var d := global_position.distance_squared_to(candidate.global_position)
		if d < best:
			best = d
			nearest = candidate
	if nearest == _interact_target:
		return
	if _interact_target:
		_interact_target.show_prompt(false)
	_interact_target = nearest
	if _interact_target:
		_interact_target.show_prompt(true)
	interact_target_changed.emit(_interact_target)
