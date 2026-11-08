class_name Enemy
extends CharacterBody3D
## Base for enemies (TECHNICAL_DESIGN.md §4.3). States: Idle (wander), Chase, Telegraph, Attack, Recover,
## Stagger, Dead. Every attack follows Telegraph → Attack → Recover, so it is always readable (FR-CMB-05).
## Children: Visual (with telegraph/attack/flash methods), Health, Hurtbox, AttackHitbox, StateMachine.
## A LootDropper is added in code when the data has a loot table.
## Its target is Aurelia, or for a few seconds the pet dragon after it bites or breathes on it (distract()).
## Enemies with several attacks (EnemyData.moves; Phase 8) pick a move in range when they wind up, show its warning
## with a TelegraphMarker and play "enemy_<id>_<move>_telegraph"; bosses (Boss) choose from their phase's moves.

signal defeated(enemy: Enemy)
signal summoned(helper: Node3D)

const GRAVITY := 25.0
const HEALTH_BAR_HEIGHT := 1.6
const KNOCKBACK_DECAY := 12.0
const HIT_STOP := 0.05
const ENGAGED_RANGE_FACTOR := 1.3
const AIM_LOCK := 0.7          ## of the wind-up: after this it stops turning (the last moment can be dodged)
const VOLLEY_HEIGHT := 1.2
const IMMUNE_TEXT := "Immune"
const IMMUNE_COLOR := Color(1.0, 0.55, 0.3)

@export var data: EnemyData

var target: Node3D                ## who it is after: Aurelia, or her dragon while distracted
var home := Vector3.ZERO
var knockback := Vector3.ZERO
var _health_bar: WorldHealthBar
var _loot: LootDropperComponent
var _distracted_by: Node3D
var _distract_left := 0.0
var current_move: EnemyMoveData           ## the attack it is winding up or doing (null: the single data attack)
var _marker: TelegraphMarker
var _charge_dir := Vector3.FORWARD
var _aim_locked := false
var _move_hitbox_radius := -1.0

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
	health.invulnerable = data.invulnerable
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
	if has_moves():
		_marker = TelegraphMarker.new()
		add_child(_marker)


func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	if _distract_left > 0.0:
		_distract_left -= delta
		if _distract_left <= 0.0 or not is_alive(_distracted_by):
			_distract_left = 0.0
			if target == _distracted_by:
				target = null
			_distracted_by = null
		else:
			target = _distracted_by
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Node3D
	if not health.is_dead() and distance_to_target() <= data.aggro_range * ENGAGED_RANGE_FACTOR:
		if _health_bar:
			_health_bar.keep_visible()  # show rank and health while engaged (FR-CMB-02)


# --- Used by states ------------------------------------------------------------------------

## True while it is after Aurelia: chasing, winding up, attacking or recovering (for the combat music).
func is_engaged() -> bool:
	return not health.is_dead() and has_live_target() and (state_machine.is_in(&"Chase") \
			or state_machine.is_in(&"Telegraph") or state_machine.is_in(&"Attack") or state_machine.is_in(&"Recover"))


func has_live_target() -> bool:
	return is_alive(target)


## True for a character (with a `health` HealthComponent) that is still standing.
static func is_alive(node: Node3D) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var node_health := node.get(&"health") as HealthComponent
	return node_health != null and not node_health.is_dead()


## The pet dragon bit it: it goes after `by` for `seconds` instead of Aurelia (GAME_DESIGN.md §8.2: "distracts").
func distract(by: Node3D, seconds: float) -> void:
	if health.is_dead() or not is_alive(by):
		return
	_distracted_by = by
	_distract_left = maxf(_distract_left, seconds)
	target = by
	if state_machine.is_in(&"Idle"):
		state_machine.transition_to(&"Chase")


func is_distracted() -> bool:
	return _distract_left > 0.0


## Radius of the ground its attack covers (the pet dragon keeps out of it while it winds up).
func danger_radius() -> float:
	if current_move:
		return current_move.length * 0.5 if current_move.kind == EnemyMoveData.Kind.CHARGE else current_move.radius
	return data.attack_radius


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


## Plays this enemy's sound `part` (alert, telegraph, attack, hurt, death): "enemy_<id>_<part>".
func play_sound(part: String) -> void:
	AudioManager.play(StringName("enemy_%s_%s" % [data.id, part]), global_position)


# --- Attacks (one data attack, or several moves) -----------------------------------------------

func has_moves() -> bool:
	return not available_moves().is_empty()


## The moves it can use now (bosses: the current phase's). Override.
func available_moves() -> Array[EnemyMoveData]:
	return data.moves


## Chooses a move for a target `distance` away (weighted among those in range), or null if none reaches.
func pick_move(distance: float) -> EnemyMoveData:
	var choices: Array[EnemyMoveData] = []
	choices.assign(available_moves().filter(func(m: EnemyMoveData) -> bool: return m.in_range(distance)))
	if choices.is_empty():
		return null
	var total := 0.0
	for m in choices:
		total += m.weight
	var roll := randf() * total
	for m in choices:
		roll -= m.weight
		if roll <= 0.0:
			return m
	return choices[-1]


func find_move(id: StringName) -> EnemyMoveData:
	for m in available_moves():
		if m.id == id:
			return m
	return null


## Chase asks this every frame: true (with `move` chosen) when an attack can start from here.
func ready_to_attack(distance: float) -> bool:
	if not has_moves():
		return distance <= data.attack_range
	current_move = pick_move(distance)
	return current_move != null


func telegraph_time() -> float:
	return current_move.telegraph_time if current_move else data.telegraph_time


func attack_active_time() -> float:
	return current_move.active_time if current_move else data.attack_active


func recover_time() -> float:
	return current_move.recover_time if current_move else data.recover_time


## True while its attack covers ground around or in front of it (the pet dragon keeps out); not for bolts.
func threatens_area() -> bool:
	if current_move:
		return current_move.kind != EnemyMoveData.Kind.VOLLEY and current_move.kind != EnemyMoveData.Kind.SUMMON
	return data.min_range <= 0.0


## The wind-up begins: its sound (as long as the warning) and, for moves, the marker on the ground.
func begin_telegraph() -> void:
	_aim_locked = false
	if current_move:
		play_sound("%s_telegraph" % current_move.id)
	else:
		play_sound("telegraph")
	if has_live_target():
		face(direction_to(target.global_position))


## Called every frame of the wind-up with its progress 0–1. Moves keep turning to the target for the first part,
## then lock their direction so the last moment can be dodged.
func update_telegraph(progress: float) -> void:
	if current_move == null:
		visual.set_telegraph(progress)
		return
	if progress < AIM_LOCK and has_live_target():
		face(direction_to(target.global_position))
	elif not _aim_locked:
		_aim_locked = true
	if visual.has_method(&"set_telegraph"):
		visual.set_telegraph(progress)
	_marker.show_move(current_move, global_position, facing(), progress)


func end_telegraph() -> void:
	if visual.has_method(&"set_telegraph"):
		visual.set_telegraph(-1.0)
	if _marker:
		_marker.hide_marker()


## The direction it faces (its visual's forward).
func facing() -> Vector3:
	return Vector3(-sin(visual.rotation.y), 0.0, -cos(visual.rotation.y))


## The hit itself. Melee enemies switch on their attack hitbox; ranged enemies override this to shoot.
func perform_attack() -> void:
	if current_move:
		_perform_move(current_move)
		return
	attack_hitbox.activate()
	visual.play_attack()
	play_sound("attack")


## Every frame of the attack (a charge dashes forward; others stand still).
func update_attack(delta: float) -> void:
	if current_move and current_move.kind == EnemyMoveData.Kind.CHARGE:
		move(_charge_dir * current_move.charge_speed(), delta)
	else:
		move(Vector3.ZERO, delta)


func end_attack() -> void:
	attack_hitbox.deactivate()


## The move to do straight after this one (a combo), or null.
func next_follow_up() -> EnemyMoveData:
	if current_move == null or current_move.follow_up == &"":
		return null
	return find_move(current_move.follow_up)


func _perform_move(m: EnemyMoveData) -> void:
	visual.play_attack()
	play_sound("%s" % m.id)
	attack_hitbox.damage = m.damage
	attack_hitbox.element = m.element
	attack_hitbox.knockback = m.knockback
	attack_hitbox.status_effect = m.status
	attack_hitbox.status_duration = m.status_duration
	attack_hitbox.status_power = m.status_power
	var shape := (attack_hitbox.get_child(0) as CollisionShape3D).shape as SphereShape3D
	match m.kind:
		EnemyMoveData.Kind.MELEE, EnemyMoveData.Kind.RING:
			shape.radius = m.radius
			attack_hitbox.arc_deg = m.arc_deg
			attack_hitbox.arc_forward = facing()
			attack_hitbox.activate()
		EnemyMoveData.Kind.CHARGE:
			shape.radius = m.radius
			attack_hitbox.arc_deg = 360.0
			_charge_dir = facing()
			attack_hitbox.activate()
		EnemyMoveData.Kind.VOLLEY:
			_fire_volley(m)
		EnemyMoveData.Kind.SUMMON:
			_summon(m)


func _fire_volley(m: EnemyMoveData) -> void:
	var forward := facing()
	for i in m.count:
		var t := 0.5 if m.count == 1 else float(i) / (m.count - 1)
		var dir := forward.rotated(Vector3.UP, deg_to_rad(lerpf(m.spread_deg * 0.5, -m.spread_deg * 0.5, t)))
		var bolt := Projectile.new()
		get_parent().add_child(bolt)
		bolt.launch(self, global_position + Vector3(0, VOLLEY_HEIGHT, 0), dir, HurtboxComponent.Team.ENEMY, m.damage,
				m.element, Elements.color(m.element) if m.element != Elements.Type.NONE else Color.WHITE,
				m.projectile_speed, m.projectile_range, m.projectile_radius)
		if m.status != &"":
			bolt.hitbox.status_effect = m.status
			bolt.hitbox.status_duration = m.status_duration
			bolt.hitbox.status_power = m.status_power


func _summon(m: EnemyMoveData) -> void:
	if m.summon_scene == null:
		return
	for i in m.summon_count:
		var helper := m.summon_scene.instantiate() as Node3D
		var angle := TAU * i / m.summon_count
		helper.position = global_position + Vector3(cos(angle), 0, sin(angle)) * m.summon_distance
		get_parent().add_child(helper)
		summoned.emit(helper)


func _on_status_changed() -> void:
	var names: Array[String] = []
	for id in status_effects.effects:
		names.append(String(id).replace("_", " ").to_upper())
	if _health_bar:
		_health_bar.set_status(" ".join(names))


# --- Events --------------------------------------------------------------------------------

func _on_hurt(info: DamageInfo, amount: float) -> void:
	knockback = info.knockback * (1.0 - data.knockback_resistance)
	CombatFx.flash(visual)
	if health.invulnerable:  # scripted fights (FR-BOS-04): the hit lands but does nothing
		CombatFx.floating_text(get_parent(), global_position + Vector3(0, HEALTH_BAR_HEIGHT + 0.2, 0), IMMUNE_TEXT,
				IMMUNE_COLOR)
		if visual.has_method(&"play_shield"):
			visual.call(&"play_shield")
		play_sound("immune")
		return
	CombatFx.damage_number(get_parent(), global_position + Vector3(0, HEALTH_BAR_HEIGHT + 0.2, 0),
			amount, Elements.multiplier(info.element, data.element))
	CombatFx.hit_stop(get_tree(), HIT_STOP)
	if _health_bar:
		_health_bar.set_ratio(health.ratio())
	if health.is_dead():
		return
	play_sound("hurt")
	if info.stagger and not data.stagger_resistant and not state_machine.is_in(&"Dead"):
		state_machine.transition_to(&"Stagger")
	elif state_machine.is_in(&"Idle"):
		state_machine.transition_to(&"Chase")  # hit from afar: notice the attacker


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
	play_sound("death")
	if _loot:
		_loot.drop.call_deferred(global_position, get_parent())  # not during the physics step that killed it
	EventBus.enemy_defeated.emit(data.id)
	defeated.emit(self)
