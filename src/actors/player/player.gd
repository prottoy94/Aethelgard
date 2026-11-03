class_name Player
extends CharacterBody3D
## Aurelia, the player character. Movement is relative to the camera on the ground plane.
## Behaviour lives in StateMachine states (Idle, Move, Dash, Strike, Hurt, Dead); tuning comes from
## `stats` (movement) and `combat`. Components: Health, Stamina, SpellCaster, Hurtbox, StrikeHitbox.
## Visuals are the "Visual" child, so the placeholder can be swapped for the VRoid model later.

signal dashed
signal interact_target_changed(target: InteractableComponent)
signal died
signal respawned

const SPELL_ACTIONS: Array[StringName] = [&"cast_1", &"cast_2", &"cast_3", &"cast_4"]
const STICK_AIM_DEADZONE := 0.3
const RETICLE_STICK_DISTANCE := 3.0  ## m ahead when aiming with a stick
const RETICLE_COLOR := Color(1.0, 0.92, 0.65)

@export var stats: MovementStats
@export var combat: PlayerCombatStats

## Set by the level. If empty, the first node in the "camera_rig" group is used.
var camera_rig: CameraRig
var respawn_point := Vector3.ZERO
var facing_yaw := 0.0
var is_invulnerable: bool:
	get:
		return _invulnerable_time > 0.0
var dash_cooldown := Cooldown.new()
var strike_cooldown := Cooldown.new()
## Velocity added by hits; decays over time (applied in apply_movement).
var knockback := Vector3.ZERO

var _dash_buffer := 0.0
var _strike_buffer := 0.0
var _invulnerable_time := 0.0
var _aim_hold := 0.0
var _last_aim := Vector3.FORWARD
var _mouse_aim := true
var _interactables: Array[InteractableComponent] = []
var _interact_target: InteractableComponent
var _reticle: MeshInstance3D

@onready var visual: Node3D = $Visual
@onready var state_machine: StateMachine = $StateMachine
@onready var health: HealthComponent = $Health
@onready var stamina: StaminaComponent = $Stamina
@onready var spell_caster: SpellCaster = $SpellCaster
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var strike_hitbox: HitboxComponent = $StrikeHitbox
@onready var _detector: Area3D = $InteractionDetector


func _ready() -> void:
	add_to_group(&"player")
	floor_snap_length = stats.floor_snap
	floor_max_angle = deg_to_rad(stats.max_floor_angle_deg)
	respawn_point = global_position
	_detector.area_entered.connect(_on_area_entered)
	_detector.area_exited.connect(_on_area_exited)
	_apply_combat_stats()
	hurtbox.invulnerable_check = func() -> bool: return is_invulnerable or health.is_dead()
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	strike_hitbox.source = self
	_build_reticle()


func _physics_process(delta: float) -> void:
	dash_cooldown.tick(delta)
	strike_cooldown.tick(delta)
	_dash_buffer = maxf(_dash_buffer - delta, 0.0)
	_strike_buffer = maxf(_strike_buffer - delta, 0.0)
	_invulnerable_time = maxf(_invulnerable_time - delta, 0.0)
	_aim_hold = maxf(_aim_hold - delta, 0.0)
	knockback = knockback.move_toward(Vector3.ZERO, combat.knockback_decay * delta)
	_update_interact_target()


func _process(delta: float) -> void:
	if visual.has_method(&"update_motion"):
		var horizontal := Vector2(velocity.x, velocity.z).length()
		visual.update_motion(horizontal / stats.walk_speed, state_machine.is_in(&"Dash"), delta, horizontal)
	_update_reticle()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_aim = true
	if health.is_dead():
		return
	if event.is_action_pressed("dash"):
		request_dash()
	elif event.is_action_pressed("attack"):
		request_strike()
	elif event.is_action_pressed("interact") and try_interact():
		get_viewport().set_input_as_handled()
	else:
		for slot in SPELL_ACTIONS.size():
			if event.is_action_pressed(SPELL_ACTIONS[slot]):
				try_cast(slot)
				break


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


func request_strike() -> void:
	_strike_buffer = combat.strike_buffer


func consume_strike_request() -> bool:
	if _strike_buffer > 0.0 and strike_cooldown.is_ready():
		_strike_buffer = 0.0
		return true
	return false


## Makes Aurelia ignore hits for `seconds` (dash i-frames, after being hurt, after respawning).
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_time = maxf(_invulnerable_time, seconds)


## Moves the horizontal velocity towards `target` (plus any knockback) and applies gravity, then slides.
func apply_movement(target: Vector3, rate: float, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z) - knockback
	horizontal = horizontal.move_toward(target, rate * delta) + knockback
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= stats.gravity * delta
	move_and_slide()


func face_towards(direction: Vector3, delta: float) -> void:
	if _aim_hold > 0.0:
		direction = _last_aim  # keep facing where the last spell went
	if direction.length_squared() < 0.0001:
		return
	facing_yaw = lerp_angle(facing_yaw, yaw_of(direction), 1.0 - exp(-stats.turn_speed * delta))
	visual.rotation.y = facing_yaw


func face_instantly(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	facing_yaw = yaw_of(direction)
	visual.rotation.y = facing_yaw


func facing_direction() -> Vector3:
	return Vector3(-sin(facing_yaw), 0.0, -cos(facing_yaw))


## Where Aurelia aims: the right stick if used, otherwise the mouse on the ground, otherwise her facing.
func aim_direction() -> Vector3:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > STICK_AIM_DEADZONE:
		_mouse_aim = false
		return input_to_world(stick.normalized(), camera_yaw())
	if _mouse_aim:
		var point: Variant = mouse_ground_point()
		if point != null:
			var offset: Vector3 = point - global_position
			offset.y = 0.0
			if offset.length() > 0.2:
				return offset.normalized()
	return facing_direction()


## The point on the ground (at Aurelia's height) under the mouse cursor, or null.
func mouse_ground_point() -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var mouse := get_viewport().get_mouse_position()
	return Plane(Vector3.UP, global_position.y).intersects_ray(
			camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))


## Casts the spell in `slot` towards the aim. Returns true if it was cast.
func try_cast(slot: int) -> bool:
	if health.is_dead() or state_machine.is_in(&"Dash") or state_machine.is_in(&"Hurt"):
		return false
	var aim := aim_direction()
	if not spell_caster.try_cast(slot, self, aim):
		return false  # refused: empty slot, Exhausted, cooldown or not enough stamina
	_last_aim = aim
	_aim_hold = combat.cast_face_time
	face_instantly(aim)
	play_role(&"cast")
	return true


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
	if _interact_target == null or state_machine.is_in(&"Dash") or health.is_dead():
		return false
	_interact_target.interact(self)
	return true


## Back to the respawn point with full health and stamina (FR-PLY-08).
func respawn() -> void:
	global_position = respawn_point
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	health.reset()
	stamina.reset()
	if visual.has_method(&"reset_pose"):
		visual.reset_pose()
	grant_invulnerability(combat.respawn_invulnerable)
	state_machine.transition_to(&"Idle")
	respawned.emit()


## Asks the model to play a reaction: &"strike", &"cast", &"hurt", &"death", &"interact"...
func play_role(role: StringName) -> void:
	if visual.has_method(&"play_role"):
		visual.play_role(role)


# --- Combat events -------------------------------------------------------------------------

func _apply_combat_stats() -> void:
	health.max_health = combat.max_health
	health.defense = combat.defense
	health.reset()
	stamina.max_stamina = combat.max_stamina
	stamina.regen_rate = combat.stamina_regen
	stamina.regen_delay = combat.stamina_regen_delay
	stamina.recover_ratio = combat.exhausted_recover_ratio
	stamina.reset()
	spell_caster.global_cooldown = combat.global_cooldown
	for i in mini(combat.starting_spells.size(), SpellCaster.SLOT_COUNT):
		spell_caster.set_slot(i, combat.starting_spells[i])
	strike_hitbox.damage = combat.strike_damage
	strike_hitbox.knockback = combat.strike_knockback


func _on_hurt(info: DamageInfo, _amount: float) -> void:
	if health.is_dead():
		return
	knockback = info.knockback
	grant_invulnerability(combat.hurt_invulnerable)
	CombatFx.flash(visual)
	if camera_rig:
		camera_rig.add_shake(0.35)
	if not state_machine.is_in(&"Dash"):
		state_machine.transition_to(&"Hurt")


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
	if camera_rig:
		camera_rig.add_shake(0.6)
	died.emit()


# --- Aim reticle ---------------------------------------------------------------------------

func _build_reticle() -> void:
	_reticle = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.3
	_reticle.mesh = ring
	var material := ToonMaterials.glow(RETICLE_COLOR, 2.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	material.no_depth_test = true
	_reticle.material_override = material
	_reticle.scale = Vector3(1, 0.1, 1)
	_reticle.top_level = true
	_reticle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_reticle)


func _update_reticle() -> void:
	_reticle.visible = not health.is_dead()
	var point: Variant = mouse_ground_point() if _mouse_aim else null
	if point == null:
		point = global_position + aim_direction() * RETICLE_STICK_DISTANCE
	_reticle.global_position = (point as Vector3) + Vector3(0, 0.05, 0)


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
