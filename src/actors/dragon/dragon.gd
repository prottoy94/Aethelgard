class_name Dragon
extends CharacterBody3D
## Aurelia's pet dragon in the world (GAME_DESIGN.md §8.4, TECHNICAL_DESIGN.md §4.11; FR-DRG-02/03/07).
## Commands (G cycles, DragonManager.command):
## - Follow: walks after Aurelia and bites enemies that come after her.
## - Attack: goes after her target (the last enemy she hit, or the one she aims at), else the nearest threat.
## - Guard: stays at her side between her and the nearest enemy (so enemy bolts hit it) and bites what comes close.
## H uses its breath skill on its own cooldown. It keeps out of enemies' telegraph rings, appears back beside Aurelia
## when left far behind, and enemies it bites go after it for a moment. At 0 HP it is knocked out: it curls up and comes
## back after a while, or when she rests at a Lantern Shrine. Petting it (E) makes it happy and raises the bond.
## States: Follow, Attack, Guard, UseSkill, KnockedOut. Lasting state lives in DragonManager.
## The "Visual" child is a placeholder of simple shapes (DragonPlaceholder), so a model can replace it later.

signal skill_used(skill: DragonSkillData)
signal bit(enemy: Enemy)

const TUNING: DragonTuning = preload("res://data/dragons/dragon_tuning.tres")
const GRAVITY := 25.0
const KNOCKBACK_DECAY := 12.0
const WORLD_LAYER := 1 << 0
const BODY_RADIUS := 0.26
const BODY_HEIGHT := 0.56
const HURTBOX_RADIUS := 0.38
const PET_RADIUS := 0.25          ## m: small, so the prompt only shows when Aurelia walks right up to it
const MOUTH := Vector3(0, 0.35, -0.45)
const BITE_ACTIVE := 0.15         ## s the bite hit is active
const BITE_KNOCKBACK := 2.0
const EMOTE_HEIGHT := 0.95
const EMOTE_TIME := 1.6
const TURN_SPEED := 12.0
const ARRIVE_DISTANCE := 0.25

var player: Player
var species: DragonSpeciesData
var stats: DragonStageStats
var skill: DragonSkillData
var traits: Array[DragonSkillData] = []
var skill_cooldown := Cooldown.new()
var bite_cooldown := Cooldown.new()
var target: Enemy                    ## who it is fighting
var knockback := Vector3.ZERO
var speed_multiplier := 1.0
var facing_yaw := 0.0
var _following := false
var _since_hurt := 99.0
var _invulnerable := 0.0
var _bite_left := 0.0
var _emote_left := 0.0
var _in_fight := false

var visual: DragonPlaceholder
var health: HealthComponent
var status_effects: StatusEffectComponent
var hurtbox: HurtboxComponent
var bite_hitbox: HitboxComponent
var interactable: InteractableComponent
var state_machine: StateMachine
var _emote: Label3D


## A new dragon beside `near` (Aurelia), added to `parent`.
static func spawn(parent: Node, near: Node3D) -> Dragon:
	var dragon := Dragon.new()
	parent.add_child(dragon)
	if near:
		dragon.place_beside(near)
	return dragon


func _init() -> void:
	name = &"Dragon"


func _ready() -> void:
	add_to_group(&"dragon")
	collision_layer = 0          # its body never blocks Aurelia or enemies
	collision_mask = WORLD_LAYER
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(50.0)
	_add_shape(self, CapsuleShape3D.new(), Vector3(0, BODY_HEIGHT * 0.5, 0))
	visual = DragonPlaceholder.new()
	visual.name = &"Visual"
	add_child(visual)
	health = HealthComponent.new()
	add_child(health)
	status_effects = StatusEffectComponent.new()
	status_effects.health = health
	add_child(status_effects)
	hurtbox = HurtboxComponent.new()
	hurtbox.team = HurtboxComponent.Team.PLAYER  # enemy attacks and bolts hit it, Aurelia's don't
	hurtbox.health = health
	hurtbox.status_effects = status_effects
	hurtbox.invulnerable_check = func() -> bool: return _invulnerable > 0.0 or not DragonManager.is_active()
	add_child(hurtbox)
	var hurt_shape := SphereShape3D.new()
	hurt_shape.radius = HURTBOX_RADIUS
	_add_shape(hurtbox, hurt_shape, Vector3(0, 0.3, 0))
	bite_hitbox = HitboxComponent.new()
	bite_hitbox.team = HurtboxComponent.Team.PLAYER
	bite_hitbox.source = self
	add_child(bite_hitbox)
	_add_shape(bite_hitbox, SphereShape3D.new(), MOUTH)
	interactable = InteractableComponent.new()
	interactable.prompt_height = 0.9
	add_child(interactable)
	var pet_shape := SphereShape3D.new()
	pet_shape.radius = PET_RADIUS
	_add_shape(interactable, pet_shape, Vector3(0, 0.3, 0))
	_build_emote()
	_build_states()
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	health.changed.connect(_on_health_changed)
	bite_hitbox.hit.connect(_on_bite_hit)
	interactable.interacted.connect(_on_pet)
	DragonManager.command_changed.connect(_on_command_changed)
	DragonManager.bond_level_up.connect(_on_bond_level_up)
	DragonManager.element_chosen.connect(_on_look_changed)
	DragonManager.name_changed.connect(_on_look_changed)
	DragonManager.fed.connect(_on_fed)
	DragonManager.petted.connect(_on_petted)
	DragonManager.recovered.connect(_on_recovered)
	DragonManager.rested.connect(_on_rested)
	refresh_stats(false)


func _physics_process(delta: float) -> void:
	skill_cooldown.tick(delta)
	bite_cooldown.tick(delta)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_since_hurt += delta
	knockback = knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	if _bite_left > 0.0:
		_bite_left -= delta
		if _bite_left <= 0.0:
			bite_hitbox.deactivate()
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(&"player") as Player
	var fighting := _any_enemy_engaged()
	if fighting != _in_fight:
		_in_fight = fighting
		update_pet_prompt()
	if DragonManager.is_active() and _since_hurt >= TUNING.calm_regen_delay and health.current < health.max_health \
			and not fighting:
		health.heal(TUNING.calm_regen * delta)


func _process(delta: float) -> void:
	var horizontal := Vector2(velocity.x, velocity.z).length()
	visual.update_motion(horizontal / maxf(stats.move_speed, 0.1), delta)
	visual.rotation.y = lerp_angle(visual.rotation.y, facing_yaw, 1.0 - exp(-TURN_SPEED * delta))
	if _emote_left > 0.0:
		_emote_left -= delta
		_emote.modulate.a = clampf(_emote_left / 0.4, 0.0, 1.0)
		_emote.visible = _emote_left > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dragon_command"):
		DragonManager.cycle_command()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dragon_skill"):
		request_skill()
		get_viewport().set_input_as_handled()


# --- Stats ---------------------------------------------------------------------------------------

## Reads species, stage, bond and traits from DragonManager. With `top_up`, a higher maximum is added to its health.
func refresh_stats(top_up: bool) -> void:
	species = DragonManager.species()
	if species == null:
		species = TUNING.species[0]
	stats = species.stats_for(maxi(DragonManager.stage, DragonTypes.Stage.HATCHLING) as DragonTypes.Stage)
	skill = DragonManager.active_skill()
	traits = DragonManager.passives()
	var new_max := stats.max_health * DragonManager.health_multiplier()
	var ratio := DragonManager.health_ratio
	health.element = species.element
	health.defense = stats.defense
	health.set_max_health(new_max, top_up)
	if not top_up:
		# Awake it has at least 1 HP; knocked out it has none until it wakes.
		health.current = maxf(new_max * ratio, 1.0) if DragonManager.is_active() else 0.0
		health.changed.emit(health.current, health.max_health)
	speed_multiplier = 1.0
	var taken := 1.0
	var bite_knockback := BITE_KNOCKBACK
	bite_hitbox.status_effect = &""
	var glow := 0.0
	for entry in traits:
		speed_multiplier *= entry.speed_multiplier
		taken *= entry.damage_taken_multiplier
		bite_knockback += entry.bite_knockback_bonus
		glow = maxf(glow, entry.glow_energy)
		if entry.bite_status != &"":
			bite_hitbox.status_effect = entry.bite_status
			bite_hitbox.status_duration = entry.bite_status_duration
			bite_hitbox.status_power = entry.bite_status_power
	var resist: Dictionary[Elements.Type, float] = {}
	if taken < 1.0:
		for type: int in Elements.Type.values():
			resist[type as Elements.Type] = 1.0 - taken
	health.resistances = resist
	bite_hitbox.damage = stats.bite_damage * DragonManager.damage_multiplier()
	bite_hitbox.element = species.element
	bite_hitbox.knockback = bite_knockback
	((bite_hitbox.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius = stats.bite_radius
	visual.apply_species(species)
	visual.set_glow(glow)
	visual.scale = Vector3.ONE * stats.size
	interactable.set_prompt("Pet %s" % DragonManager.display_name())


func run_speed() -> float:
	return stats.move_speed * speed_multiplier


# --- Used by states ------------------------------------------------------------------------------

## The state that carries out the current command when there is nothing to bite.
func command_state() -> StringName:
	return &"Guard" if DragonManager.command == DragonTypes.Command.GUARD else &"Follow"


## Moves horizontally at `desired` velocity (stepping out of telegraph rings first unless `avoid` is false), with
## gravity and knockback.
func move_with(desired: Vector3, delta: float, avoid := true) -> void:
	if avoid:
		desired = avoid_danger(desired)
	var slowed := desired * status_effects.speed_multiplier()
	velocity.x = slowed.x + knockback.x
	velocity.z = slowed.z + knockback.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if Vector2(desired.x, desired.z).length_squared() > 0.04:
		face(desired)


## Walks to `point`; returns the distance left.
func move_to(point: Vector3, speed: float, delta: float) -> float:
	var offset := point - global_position
	offset.y = 0.0
	var distance := offset.length()
	move_with(offset.normalized() * speed if distance > ARRIVE_DISTANCE else Vector3.ZERO, delta)
	return distance


func face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length_squared() > 0.0001:
		facing_yaw = Player.yaw_of(direction)


func forward() -> Vector3:
	return Vector3(-sin(facing_yaw), 0.0, -cos(facing_yaw))


func distance_to_player() -> float:
	return _flat_distance(global_position, player.global_position) if player else 0.0


## Walks after Aurelia: starts when she is a few metres away, settles near her, runs to catch up.
func follow_player(delta: float) -> void:
	if player == null:
		move_with(Vector3.ZERO, delta)
		return
	var offset := player.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if _following and distance <= TUNING.follow_distance:
		_following = false
	elif not _following and distance > TUNING.follow_restart:
		_following = true
	if _following:
		var speed := run_speed() * (TUNING.catch_up_multiplier if distance > TUNING.catch_up_distance else 1.0)
		move_with(offset.normalized() * speed, delta)
	else:
		move_with(Vector3.ZERO, delta)
		face(offset)


## Appears back beside Aurelia when left too far behind (TECHNICAL_DESIGN.md §4.11). Returns true if it did.
func check_leash() -> bool:
	if player and distance_to_player() > TUNING.leash_distance:
		place_beside(player)
		AudioManager.play(&"dragon_return", global_position)
		return true
	return false


## Puts it just behind `who`, facing the same way.
func place_beside(who: Node3D) -> void:
	var behind := Vector3.BACK
	if who is Player:
		behind = -(who as Player).facing_direction()
	global_position = who.global_position + behind * TUNING.follow_distance + Vector3(0, 0.05, 0)
	velocity = Vector3.ZERO
	knockback = Vector3.ZERO
	face(-behind)
	if visual:
		visual.rotation.y = facing_yaw


## The enemy it should fight now for the current command, or null.
func pick_target() -> Enemy:
	if player == null:
		return null
	match DragonManager.command:
		DragonTypes.Command.ATTACK:
			var aimed := aimed_enemy()
			return aimed if aimed else find_threat(player.global_position, TUNING.attack_search_radius, true)
		DragonTypes.Command.GUARD:
			return find_threat(player.global_position, TUNING.guard_engage_radius, false)
	return find_threat(player.global_position, TUNING.engage_radius, true)


## Whether it should keep fighting `enemy` under the current command.
func should_keep_fighting(enemy: Enemy) -> bool:
	if not is_live_enemy(enemy) or player == null:
		return false
	var reach := TUNING.attack_leash
	match DragonManager.command:
		DragonTypes.Command.FOLLOW:
			reach = TUNING.engage_radius * 1.6
		DragonTypes.Command.GUARD:
			reach = TUNING.guard_engage_radius * 1.6
	return _flat_distance(enemy.global_position, player.global_position) <= reach


## Aurelia's target: the last enemy she hit (recently), or the enemy closest to where she aims.
func aimed_enemy() -> Enemy:
	var recent := player.recent_target(TUNING.target_memory) as Enemy
	if is_live_enemy(recent) and _flat_distance(recent.global_position, player.global_position) <= TUNING.attack_search_radius:
		return recent
	var aim := player.aim_direction()
	var best: Enemy = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if not is_live_enemy(enemy):
			continue
		var offset := enemy.global_position - player.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= TUNING.attack_search_radius and distance < best_distance \
				and rad_to_deg(aim.angle_to(offset)) <= TUNING.attack_aim_angle:
			best = enemy
			best_distance = distance
	return best


## The nearest live enemy within `radius` of `around` (only ones after Aurelia or her dragon when `engaged_only`).
func find_threat(around: Vector3, radius: float, engaged_only: bool) -> Enemy:
	var best: Enemy = null
	var best_distance := radius
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if not is_live_enemy(enemy) or (engaged_only and not enemy.is_engaged()):
			continue
		var distance := _flat_distance(enemy.global_position, around)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


static func is_live_enemy(enemy: Enemy) -> bool:
	return enemy != null and is_instance_valid(enemy) and not enemy.health.is_dead()


## Bites `enemy` if it is in reach and the bite is ready. Returns true if it bit.
func try_bite(enemy: Enemy) -> bool:
	if not bite_cooldown.is_ready() or not is_live_enemy(enemy):
		return false
	if _flat_distance(enemy.global_position, global_position) > stats.bite_range:
		return false
	face(enemy.global_position - global_position)
	(bite_hitbox.get_child(0) as CollisionShape3D).position = MOUTH.rotated(Vector3.UP, facing_yaw)
	bite_hitbox.activate()
	_bite_left = BITE_ACTIVE
	bite_cooldown.start(stats.bite_cooldown)
	visual.play_bite()
	AudioManager.play(&"dragon_bite", global_position)
	return true


## H: use the breath skill (FR-DRG-03). Refused (with a "?") while knocked out, on cooldown or before it has one.
func request_skill() -> bool:
	if skill == null or not DragonManager.is_active() or not skill_cooldown.is_ready() \
			or state_machine.is_in(&"UseSkill") or state_machine.is_in(&"KnockedOut"):
		if DragonManager.is_active():
			show_emote("?")
		return false
	var aim := player.aim_direction() if player else forward()
	var enemy := aimed_enemy() if player else null
	if enemy == null and is_live_enemy(target):
		enemy = target
	if enemy and _flat_distance(enemy.global_position, global_position) > skill.approach_range:
		enemy = null
	state_machine.transition_to(&"UseSkill", {"target": enemy, "direction": aim})
	return true


## The breath itself, along `direction`.
func breathe(direction: Vector3) -> void:
	face(direction)
	var breath := DragonBreath.new()
	get_parent().add_child(breath)
	breath.fire(self, skill, direction, species.breath_color, DragonManager.damage_multiplier(), TUNING.distract_time)
	skill_cooldown.start(skill.cooldown)
	AudioManager.play(StringName("dragon_breath_%s" % DragonManager.element_id(species.element)), global_position)
	skill_used.emit(skill)


## Velocity that steps out of any enemy's telegraph ring it is standing in (or `desired` if it is in none).
func avoid_danger(desired: Vector3) -> Vector3:
	for node in get_tree().get_nodes_in_group(&"danger_zone"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		var offset := global_position - enemy.global_position
		offset.y = 0.0
		if offset.length() < enemy.danger_radius() + TUNING.danger_margin:
			var away := offset.normalized() if offset.length() > 0.05 else -forward()
			return away * run_speed()
	return desired


## A little symbol above its head: ♥ ! ? ♪ zzz, or a short word.
func show_emote(text: String, seconds := EMOTE_TIME) -> void:
	_emote.text = text
	_emote.visible = true
	_emote.modulate.a = 1.0
	_emote_left = seconds


func chirp() -> void:
	AudioManager.play(&"dragon_chirp_hatchling", global_position)


## Petting is offered only while it is awake and no enemy is after them (E stays free for the fight).
func update_pet_prompt() -> void:
	interactable.set_deferred(&"monitorable", DragonManager.is_active() and not _in_fight)


# --- Events --------------------------------------------------------------------------------------

func _on_hurt(info: DamageInfo, _amount: float) -> void:
	_since_hurt = 0.0
	if health.is_dead():
		return
	_invulnerable = TUNING.hurt_invulnerable
	knockback = info.knockback
	CombatFx.flash(visual)
	AudioManager.play(&"dragon_hurt", global_position)


func _on_died() -> void:
	DragonManager.knock_out()
	state_machine.transition_to(&"KnockedOut")


func _on_health_changed(current: float, maximum: float) -> void:
	if DragonManager.is_active() and maximum > 0.0:
		DragonManager.health_ratio = clampf(current / maximum, 0.0, 1.0)


func _on_bite_hit(hit_hurtbox: HurtboxComponent, _info: DamageInfo) -> void:
	var enemy := hit_hurtbox.get_parent() as Enemy
	if enemy:
		enemy.distract(self, TUNING.distract_time)  # it goes after the dragon for a moment
		bit.emit(enemy)


func _on_command_changed(command: DragonTypes.Command) -> void:
	if not DragonManager.is_active():
		return
	AudioManager.play(&"dragon_command_ack", global_position)
	show_emote("%s!" % DragonTypes.command_name(command))
	if state_machine.is_in(&"Follow") or state_machine.is_in(&"Guard") or state_machine.is_in(&"Attack"):
		state_machine.transition_to(command_state())


func _on_bond_level_up(_level: int) -> void:
	refresh_stats(true)
	show_emote("♪")
	AudioManager.play(&"dragon_happy", global_position)


func _on_look_changed(_value: Variant) -> void:
	refresh_stats(true)


func _on_pet(_by: Node) -> void:
	DragonManager.pet()


func _on_petted(gave_bond: bool) -> void:
	show_emote("♥  +bond" if gave_bond else "♥")
	visual.play_happy()
	AudioManager.play(&"dragon_happy", global_position)


func _on_fed(item: ConsumableData) -> void:
	health.heal(item.dragon_heal)
	show_emote("♥")
	visual.play_happy()
	AudioManager.play(&"dragon_eat", global_position)


func _on_recovered() -> void:
	_wake(false)


func _on_rested() -> void:
	_wake(true)


## Back on its feet beside Aurelia (after a knock-out), with full health when she rested.
func _wake(full: bool) -> void:
	var was_out := state_machine.is_in(&"KnockedOut")
	var ratio := 1.0 if full else DragonManager.health_ratio
	health.current = maxf(health.max_health * ratio, 1.0)
	health.changed.emit(health.current, health.max_health)
	status_effects.clear()
	if was_out:
		if player:
			place_beside(player)
		state_machine.transition_to(command_state())
		show_emote("!")
		chirp()


# --- Building ------------------------------------------------------------------------------------

func _build_states() -> void:
	state_machine = StateMachine.new()
	state_machine.name = &"StateMachine"
	var scripts := {
		&"Follow": preload("res://src/actors/dragon/states/follow_state.gd"),
		&"Attack": preload("res://src/actors/dragon/states/attack_state.gd"),
		&"Guard": preload("res://src/actors/dragon/states/guard_state.gd"),
		&"UseSkill": preload("res://src/actors/dragon/states/use_skill_state.gd"),
		&"KnockedOut": preload("res://src/actors/dragon/states/knocked_out_state.gd"),
	}
	for state_name: StringName in scripts:
		var state := (scripts[state_name] as Script).new() as State
		state.name = state_name
		state_machine.add_child(state)
	var first := &"KnockedOut" if DragonManager.knocked_out_left > 0.0 else command_state()
	state_machine.initial_state = state_machine.get_node(NodePath(first)) as State
	add_child(state_machine)


func _build_emote() -> void:
	_emote = Label3D.new()
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.no_depth_test = true
	_emote.font_size = 56
	_emote.outline_size = 14
	_emote.pixel_size = 0.005
	_emote.modulate = Color("ffe8f0")
	_emote.outline_modulate = Color(0.12, 0.07, 0.12, 0.9)
	_emote.position = Vector3(0, EMOTE_HEIGHT, 0)
	_emote.visible = false
	add_child(_emote)


static func _add_shape(parent: Node3D, shape: Shape3D, pos: Vector3) -> void:
	var node := CollisionShape3D.new()
	if shape is CapsuleShape3D:
		(shape as CapsuleShape3D).radius = BODY_RADIUS
		(shape as CapsuleShape3D).height = BODY_HEIGHT
	node.shape = shape
	node.position = pos
	parent.add_child(node)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _any_enemy_engaged() -> bool:
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if enemy and enemy.is_engaged():
			return true
	return false
