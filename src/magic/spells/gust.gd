class_name GustSpell
extends Spell
## Gust: a cone of wind in front of Aurelia (GAME_DESIGN.md §6.4). Light damage, strong knockback and stagger.
## Hits every enemy inside the cone once. Later it also pushes puzzle objects (on_element_hit, Phase 6).

const HEIGHT := 1.0
const LIFETIME := 0.6
const COLOR := Color(0.6, 0.95, 0.85)

var hit_count := 0


func _on_cast(aim: Vector3) -> void:
	var direction := Vector3(aim.x, 0, aim.z).normalized()
	look_at(global_position + direction, Vector3.UP)
	for node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead():
			continue
		var offset := enemy.global_position - caster.global_position
		offset.y = 0.0
		if offset.length() > data.radius or rad_to_deg(direction.angle_to(offset)) > data.angle_deg / 2.0:
			continue
		var info := DamageInfo.create(damage(), data.element, offset.normalized() * data.knockback, caster, data.stagger)
		if enemy.hurtbox.receive_hit(info):
			hit_count += 1
			landed.emit(enemy)
	_build_visual()
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func _build_visual() -> void:
	# Three expanding, fading wind arcs
	for i in 3:
		var arc := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.9
		torus.outer_radius = 1.0
		arc.mesh = torus
		var material := ToonMaterials.glow(COLOR, 2.0)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.6
		arc.material_override = material
		arc.position = Vector3(0, HEIGHT, -0.8)
		arc.rotation_degrees.x = 90.0
		arc.scale = Vector3(0.6, 0.3, 0.6)
		add_child(arc)
		var tween := create_tween()
		tween.tween_interval(i * 0.07)
		tween.tween_property(arc, "position", Vector3(0, HEIGHT, -data.radius * 0.8), 0.35)
		tween.parallel().tween_property(arc, "scale", Vector3(2.4, 1.0, 2.4), 0.35)
		tween.parallel().tween_property(arc, "transparency", 1.0, 0.35)
