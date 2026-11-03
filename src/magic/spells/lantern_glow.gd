class_name LanternGlowSpell
extends Spell
## Lantern Glow (GAME_DESIGN.md §6.4): Aurelia's lantern flares into a bright aura that follows her.
## Reveals hidden things (nodes in the "revealable" group with a reveal() method) and dazes nearby enemies.

const COLOR := Color(1.0, 0.85, 0.5)
const LIGHT_ENERGY := 3.0

var _light: OmniLight3D
var _time := 0.0


func _on_cast(_aim: Vector3) -> void:
	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.light_energy = LIGHT_ENERGY * power
	_light.omni_range = data.radius
	_light.position = Vector3(0, 2.0, 0)
	add_child(_light)
	var halo := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	halo.mesh = sphere
	var material := ToonMaterials.glow(COLOR, 1.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.25
	halo.material_override = material
	halo.position = Vector3(0, 1.4, 0)
	add_child(halo)
	create_tween().tween_property(halo, "scale", Vector3.ONE * 2.5, 0.4)
	for node in get_tree().get_nodes_in_group(&"revealable"):
		var target := node as Node3D
		if target and target.global_position.distance_to(caster.global_position) <= data.radius and target.has_method(&"reveal"):
			target.reveal()
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if enemy and not enemy.health.is_dead() and enemy.global_position.distance_to(caster.global_position) <= data.radius:
			enemy.status_effects.apply(data.status_effect, data.status_duration, data.status_power, data.element)
			landed.emit(enemy)


func _process(delta: float) -> void:
	if data == null:
		return
	_time += delta
	if is_instance_valid(caster):
		global_position = caster.global_position
	var fade := clampf((data.duration - _time) / 1.0, 0.0, 1.0)
	_light.light_energy = LIGHT_ENERGY * power * fade
	if _time >= data.duration:
		queue_free()
