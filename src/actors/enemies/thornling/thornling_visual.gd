extends Node3D
## Placeholder Thornling: a corrupted thorn-plant bulb with a red eye (GAME_DESIGN.md §7.1), built from simple shapes.
## Enemy states call: set_telegraph(progress 0–1, or -1 to hide), play_attack(), play_death().
## Faces -Z. The telegraph ring on the ground matches the attack radius from the enemy's data.

const BODY := Color(0.36, 0.62, 0.3)
const THORN := Color(0.2, 0.38, 0.18)
const EYE := Color(1.0, 0.2, 0.15)
const RING := Color(1.0, 0.25, 0.2)
const THORN_COUNT := 8
const BODY_RADIUS := 0.55
const BOB_HEIGHT := 0.05
const SPIN_TIME := 0.25

var _body: Node3D
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _attack_radius := 1.9
var _time := 0.0
var _spin := 0.0
var _dying := false


func _ready() -> void:
	var enemy := get_parent() as Enemy
	if enemy and enemy.data:
		_attack_radius = enemy.data.attack_radius
	_body = Node3D.new()
	add_child(_body)
	var bulb := SphereMesh.new()
	bulb.radius = BODY_RADIUS
	bulb.height = BODY_RADIUS * 2.0
	_add(_body, bulb, ToonMaterials.toon(BODY, 0.3, 0.02), Vector3(0, BODY_RADIUS, 0))
	var thorn_material := ToonMaterials.toon(THORN, 0.2)
	for i in THORN_COUNT:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.12
		cone.height = 0.5
		var a := TAU * i / THORN_COUNT
		var thorn := _add(_body, cone, thorn_material, Vector3(cos(a) * 0.6, BODY_RADIUS, sin(a) * 0.6))
		thorn.rotation = Vector3(0, -a, 0)
		thorn.rotate_object_local(Vector3.FORWARD, -PI / 2.0)
	var eye := SphereMesh.new()
	eye.radius = 0.12
	eye.height = 0.24
	_add(_body, eye, ToonMaterials.toon(EYE, 0.0, 0.0, 0.0, EYE, 3.0), Vector3(0, BODY_RADIUS + 0.07, -0.48))
	_build_ring()


func _process(delta: float) -> void:
	_time += delta
	if _dying:
		return
	_body.position.y = absf(sin(_time * 4.0)) * BOB_HEIGHT
	if _spin > 0.0:
		_spin = maxf(_spin - delta, 0.0)
		_body.rotation.y = TAU * (1.0 - _spin / SPIN_TIME)


## progress 0→1 grows the warning ring to the attack radius; -1 hides it.
func set_telegraph(progress: float) -> void:
	if progress < 0.0:
		_ring.visible = false
		return
	var p := clampf(progress, 0.0, 1.0)
	_ring.visible = true
	var r := lerpf(0.3, 1.0, p) * _attack_radius
	_ring.scale = Vector3(r, 1.0, r)
	_ring_material.albedo_color.a = lerpf(0.25, 0.85, p)
	_ring_material.emission_energy_multiplier = lerpf(0.5, 3.0, p)
	_body.scale = Vector3.ONE * (1.0 + 0.12 * p)  # swells before the spin


func play_attack() -> void:
	_body.scale = Vector3.ONE
	_spin = SPIN_TIME


func play_death() -> void:
	_dying = true
	_ring.visible = false
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector3(1.3, 0.2, 1.3), 0.35).set_ease(Tween.EASE_IN)
	tween.tween_property(_body, "scale", Vector3.ZERO, 0.5)


func _build_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.albedo_color = Color(RING, 0.25)
	_ring_material.emission_enabled = true
	_ring_material.emission = RING
	_ring = _add(self, torus, _ring_material, Vector3(0, 0.05, 0))
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false


func _add(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi
