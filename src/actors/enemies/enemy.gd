class_name Enemy
extends CharacterBody3D
## Base for enemies (TECHNICAL_DESIGN.md §4.3). States: Idle (wander), Chase, Telegraph, Attack, Recover,
## Stagger, Dead. Every attack follows Telegraph → Attack → Recover, so it is always readable (FR-CMB-05).
## Children: Visual (with telegraph/attack/flash methods), Health, Hurtbox, AttackHitbox, StateMachine.
## A LootDropper is added in code when the data has a loot table.

signal defeated(enemy: Enemy)

const GRAVITY := 25.0
const HEALTH_BAR_HEIGHT := 1.6
const KNOCKBACK_DECAY := 12.0
const HIT_STOP := 0.05
const ENGAGED_RANGE_FACTOR := 1.3

@export var data: EnemyData

var target: Player
var home := Vector3.ZERO
var knockback := Vector3.ZERO
var _health_bar: WorldHealthBar
var _loot: LootDropperComponent

@onready var visual: Node3D = $Visual
@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var status_effects: StatusEffectComponent = $StatusEffects
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	add_to_group(&"enemy")
	home = global_position
	health.max_health = data.max_health
	health.defense = data.defense
	health.element = data.element
	health.reset()
	attack_hitbox.damage = data.attack_damage
	attack_hitbox.element = data.attack_element
	attack_hitbox.knockback = data.attack_knockback
	attack_hitbox.source = self
	attack_hitbox.status_effect = data.attack_status
	attack_hitbox.status_duration = data.attack_status_duration
	attack_hitbox.status_power = data.attack_status_power
	var reach := SphereShape3D.new()  # own shape per enemy, sized from its data
	reach.radius = data.attack_radius
	(attack_hitbox.get_child(0) as CollisionShape3D).shape = reach
	hurtbox.hurt.connect(_on_hurt)
	status_effects.frozen.connect(func(seconds: float) -> void:
		if not health.is_dead():
			state_machine.transition_to(&"Stagger", {"time": seconds}))
	health.died.connect(_on_died)
	_health_bar = WorldHealthBar.new()
	_health_bar.position = Vector3(0, HEALTH_BAR_HEIGHT, 0)
	add_child(_health_bar)
	_health_bar.set_rank(data.rank)
	status_effects.changed.connect(_on_status_changed)
	if data.loot:
		_loot = LootDropperComponent.new()
		_loot.table = data.loot
		add_child(_loot)


func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Player
	if not health.is_dead() and distance_to_target() <= data.aggro_range * ENGAGED_RANGE_FACTOR:
		_health_bar.keep_visible()  # show rank and health while engaged (FR-CMB-02)


# --- Used by states ------------------------------------------------------------------------

func has_live_target() -> bool:
	return target != null and is_instance_valid(target) and not target.health.is_dead()


func distance_to_target() -> float:
	if not has_live_target():
		return INF
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset.length()


func direction_to(point: Vector3) -> Vector3:
	var offset := point - global_position
	offset.y = 0.0
	return offset.normalized() if offset.length_squared() > 0.0001 else Vector3.ZERO


## Moves horizontally towards `target_velocity` (plus knockback), with gravity, then slides.
func move(target_velocity: Vector3, delta: float) -> void:
	var slowed := target_velocity * status_effects.speed_multiplier()
	velocity.x = slowed.x + knockback.x
	velocity.z = slowed.z + knockback.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if target_velocity.length_squared() > 0.01:
		visual.rotation.y = Player.yaw_of(target_velocity)


func face(direction: Vector3) -> void:
	if direction.length_squared() > 0.0001:
		visual.rotation.y = Player.yaw_of(direction)


## The hit itself. Melee enemies switch on their attack hitbox; ranged enemies override this to shoot.
func perform_attack() -> void:
	attack_hitbox.activate()
	visual.play_attack()


func end_attack() -> void:
	attack_hitbox.deactivate()


func _on_status_changed() -> void:
	var names: Array[String] = []
	for id in status_effects.effects:
		names.append(String(id).replace("_", " ").to_upper())
	_health_bar.set_status(" ".join(names))


# --- Events --------------------------------------------------------------------------------

func _on_hurt(info: DamageInfo, amount: float) -> void:
	knockback = info.knockback * (1.0 - data.knockback_resistance)
	CombatFx.flash(visual)
	CombatFx.damage_number(get_parent(), global_position + Vector3(0, HEALTH_BAR_HEIGHT + 0.2, 0),
			amount, Elements.multiplier(info.element, data.element))
	CombatFx.hit_stop(get_tree(), HIT_STOP)
	_health_bar.set_ratio(health.ratio())
	if health.is_dead():
		return
	if info.stagger and not state_machine.is_in(&"Dead"):
		state_machine.transition_to(&"Stagger")
	elif state_machine.is_in(&"Idle"):
		state_machine.transition_to(&"Chase")  # hit from afar: notice the attacker


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
	if _loot:
		_loot.drop.call_deferred(global_position, get_parent())  # not during the physics step that killed it
	EventBus.enemy_defeated.emit(data.id)
	defeated.emit(self)
