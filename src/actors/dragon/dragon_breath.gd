class_name DragonBreath
extends Node3D
## The pet dragon's breath skill (GAME_DESIGN.md §8.4): a cone in front of it, like Aurelia's Gust. Hits every enemy
## inside once (they then go after the dragon for a moment) and tells puzzle objects in the cone which element touched
## them (on_element_hit), so a Light dragon can light braziers and a Wind dragon can push blocks (FR-PUZ-05).
## Add it to the world, then call fire().

const HEIGHT := 0.45
const PUFFS := 7
const LIFETIME := 0.7

var hit_count := 0
var _skill: DragonSkillData


## Breathes `skill` from `dragon` along `direction`. `damage_scale` comes from the bond.
func fire(dragon: Node3D, skill: DragonSkillData, direction: Vector3, color: Color, damage_scale: float,
		distract_time: float) -> void:
	_skill = skill
	var dir := Vector3(direction.x, 0.0, direction.z).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	global_position = dragon.global_position + Vector3(0, HEIGHT, 0)
	look_at(global_position + dir, Vector3.UP)
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead() or not in_cone(dragon.global_position, dir, enemy.global_position, skill):
			continue
		var offset := enemy.global_position - dragon.global_position
		offset.y = 0.0
		var info := DamageInfo.create(skill.damage * damage_scale, skill.element, offset.normalized() * skill.knockback,
				dragon, skill.stagger)
		if skill.status != &"":
			info.with_status(skill.status, skill.status_duration, skill.status_power)
		if enemy.hurtbox.receive_hit(info):
			hit_count += 1
			enemy.distract(dragon, distract_time)
	for receiver in ElementalReceiver.near(get_tree(), dragon.global_position, skill.radius):
		if in_cone(dragon.global_position, dir, receiver.global_position, skill, true):
			receiver.on_element_hit(skill.element, dragon.global_position)
	_build_visual(color)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


## True if `point` is inside the breath cone from `origin` along `dir` (always for points very close by).
static func in_cone(origin: Vector3, dir: Vector3, point: Vector3, skill: DragonSkillData, near_counts := false) -> bool:
	var offset := point - origin
	offset.y = 0.0
	if offset.length() > skill.radius:
		return false
	if offset.length() < (0.5 if near_counts else 0.01):
		return true
	return rad_to_deg(dir.angle_to(offset)) <= skill.angle_deg / 2.0


func _build_visual(color: Color) -> void:
	var material := ToonMaterials.glow(color, 2.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.75
	var spread := tan(deg_to_rad(_skill.angle_deg / 2.0))
	for i in PUFFS:
		var puff := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.12
		mesh.height = 0.24
		puff.mesh = mesh
		puff.material_override = material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		var side := (float(i) / (PUFFS - 1) - 0.5) * 2.0  # −1 … 1 across the cone
		var reach := _skill.radius * randf_range(0.75, 1.0)
		var end := Vector3(side * spread * reach * 0.8, randf_range(-0.1, 0.15), -reach)
		var tween := create_tween()
		tween.tween_interval(i * 0.02)
		tween.tween_property(puff, "position", end, 0.4).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(puff, "scale", Vector3.ONE * (2.5 + reach * 0.3), 0.4)
		tween.parallel().tween_property(puff, "transparency", 1.0, 0.45)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = _skill.radius
	light.position = Vector3(0, 0, -_skill.radius * 0.5)
	add_child(light)
	create_tween().tween_property(light, "light_energy", 0.0, LIFETIME)
