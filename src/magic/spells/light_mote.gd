class_name LightMoteSpell
extends Spell
## Light Mote: Aurelia's first spell (GAME_DESIGN.md §6.4). A weak glowing bolt that gently homes in on the
## nearest enemy in front of it, and bursts on impact.

const HEIGHT := 1.1              ## m above the caster's feet
const SPAWN_AHEAD := 0.6         ## m in front of the caster
const HOMING_RANGE := 9.0        ## m
const HOMING_CONE_DEG := 50.0
const TURN_RATE := 5.0           ## how quickly it bends towards the target
const COLOR := Color(1.0, 0.92, 0.6)

var _direction := Vector3.FORWARD
var _travelled := 0.0
var _hitbox: HitboxComponent
var _done := false


func _on_cast(aim: Vector3) -> void:
	_direction = aim.normalized()
	global_position += Vector3(0, HEIGHT, 0) + _direction * SPAWN_AHEAD
	_hitbox = HitboxComponent.new()
	_hitbox.team = HurtboxComponent.Team.PLAYER
	_hitbox.damage = damage()
	_hitbox.status_effect = data.status_effect
	_hitbox.status_duration = data.status_duration
	_hitbox.status_power = data.status_power
	_hitbox.element = data.element
	_hitbox.knockback = data.knockback
	_hitbox.stagger = data.stagger
	_hitbox.collide_with_world = true
	_hitbox.active_on_start = true
	_hitbox.source = caster
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = data.radius
	shape.shape = sphere
	_hitbox.add_child(shape)
	add_child(_hitbox)
	_hitbox.hit.connect(func(hurtbox: HurtboxComponent, _info: DamageInfo) -> void:
		landed.emit(hurtbox.get_parent())
		_burst())
	_hitbox.blocked.connect(func(_body: Node3D) -> void: _burst())
	_build_visual()


func _physics_process(delta: float) -> void:
	if _done or data == null:
		return
	var target := _find_target()
	if target:
		var to_target := (target.global_position + Vector3(0, HEIGHT * 0.6, 0) - global_position).normalized()
		_direction = _direction.slerp(to_target, clampf(TURN_RATE * delta, 0.0, 1.0)).normalized()
	var step := data.speed * delta
	global_position += _direction * step
	_travelled += step
	if _travelled >= data.spell_range:
		_burst()


func _find_target() -> Node3D:
	var best: Node3D = null
	var best_distance := HOMING_RANGE
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead():
			continue
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance < best_distance and rad_to_deg(Vector3(_direction.x, 0, _direction.z).angle_to(offset)) < HOMING_CONE_DEG:
			best_distance = distance
			best = enemy
	return best


func _burst() -> void:
	if _done:
		return
	_done = true
	_hitbox.deactivate()
	for child in get_children():
		if child != _hitbox:
			child.queue_free()
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	flash.mesh = sphere
	flash.material_override = ToonMaterials.glow(COLOR, 6.0)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 2.2, 0.18)
	tween.parallel().tween_property(flash, "transparency", 1.0, 0.18)
	tween.tween_callback(queue_free)


func _build_visual() -> void:
	for i in 4:  # core + short trail
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = data.radius * (1.0 - i * 0.2)
		sphere.height = sphere.radius * 2.0
		orb.mesh = sphere
		orb.material_override = ToonMaterials.glow(COLOR, 5.0 - i)
		orb.position = Vector3.ZERO
		orb.set_meta(&"trail", i)
		add_child(orb)
	var light := OmniLight3D.new()
	light.light_color = COLOR
	light.light_energy = 1.4
	light.omni_range = 3.0
	add_child(light)


func _process(_delta: float) -> void:
	if _done:
		return
	for child in get_children():  # trail orbs lag behind the core
		if child.has_meta(&"trail"):
			(child as Node3D).position = -_direction * 0.22 * float(child.get_meta(&"trail"))
