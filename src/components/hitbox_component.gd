class_name HitboxComponent
extends Area3D
## A damaging area (staff swing, projectile, enemy attack). While active it hits each hurtbox of the
## other team once per activation. Give it a CollisionShape3D child.

signal hit(hurtbox: HurtboxComponent, info: DamageInfo)
signal blocked(body: Node3D)  ## hit a wall (only if collide_with_world)

const WORLD_LAYER := 1 << 0

@export var team := HurtboxComponent.Team.PLAYER
@export var damage := 10.0
@export var element := Elements.Type.NONE
@export var knockback := 4.0          ## m/s push, away from `source`
@export var stagger := false
@export var collide_with_world := false
@export var active_on_start := false

## Who is attacking (used for the knockback direction and to never hit yourself).
var source: Node3D
var _already_hit: Array[HurtboxComponent] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = HurtboxComponent.ENEMY_HURTBOX_LAYER if team == HurtboxComponent.Team.PLAYER \
			else HurtboxComponent.PLAYER_HURTBOX_LAYER
	if collide_with_world:
		collision_mask |= WORLD_LAYER
	monitorable = false
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	monitoring = active_on_start


func activate() -> void:
	_already_hit.clear()
	monitoring = true


func deactivate() -> void:
	set_deferred(&"monitoring", false)


func is_active() -> bool:
	return monitoring


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or hurtbox in _already_hit:
		return
	if source and hurtbox.get_parent() == source:
		return
	_already_hit.append(hurtbox)
	var from := source.global_position if source else global_position
	var away := hurtbox.global_position - from
	away.y = 0.0
	var push := away.normalized() * knockback if away.length_squared() > 0.0001 else Vector3.ZERO
	var info := DamageInfo.create(damage, element, push, source, stagger)
	if hurtbox.receive_hit(info):
		hit.emit(hurtbox, info)


func _on_body_entered(body: Node3D) -> void:
	if collide_with_world and body is StaticBody3D:
		blocked.emit(body)
