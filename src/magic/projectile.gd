class_name Projectile
extends Node3D
## A simple travelling hit (enemy bolts and similar): flies straight, hits the first hurtbox of the other team or
## stops at a wall, then bursts. Configure with launch().

const BURST_TIME := 0.18

var direction := Vector3.FORWARD
var speed := 7.0
var max_range := 14.0
var hitbox: HitboxComponent
var _travelled := 0.0
var _done := false
var _color := Color.WHITE


## Builds the projectile and its hitbox. Add it to the world first, then call this.
func launch(source: Node3D, from: Vector3, dir: Vector3, team: HurtboxComponent.Team, damage: float,
		element: Elements.Type, color: Color, speed_: float, range_: float, radius: float) -> void:
	global_position = from
	direction = Vector3(dir.x, 0.0, dir.z).normalized()
	speed = speed_
	max_range = range_
	_color = color
	hitbox = HitboxComponent.new()
	hitbox.team = team
	hitbox.damage = damage
	hitbox.element = element
	hitbox.knockback = 2.0
	hitbox.collide_with_world = true
	hitbox.active_on_start = true
	hitbox.source = source
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	hitbox.add_child(shape)
	add_child(hitbox)
	hitbox.hit.connect(func(_hurtbox: HurtboxComponent, _info: DamageInfo) -> void: burst())
	hitbox.blocked.connect(func(_body: Node3D) -> void: burst())
	var core := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	core.mesh = mesh
	core.material_override = ToonMaterials.glow(color, 4.0)
	add_child(core)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.2
	light.omni_range = 3.0
	add_child(light)


func _physics_process(delta: float) -> void:
	if _done or hitbox == null:
		return
	var step := speed * delta
	global_position += direction * step
	_travelled += step
	if _travelled >= max_range:
		burst()


func burst() -> void:
	if _done:
		return
	_done = true
	hitbox.deactivate()
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	flash.mesh = mesh
	flash.material_override = ToonMaterials.glow(_color, 5.0)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 2.0, BURST_TIME)
	tween.parallel().tween_property(flash, "transparency", 1.0, BURST_TIME)
	tween.tween_callback(queue_free)
