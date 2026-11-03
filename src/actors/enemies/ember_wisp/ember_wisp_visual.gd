extends Node3D
## Placeholder Ember Wisp: a floating, flickering flame with dark eyes, built from simple shapes.
## Telegraph: the flame swells and brightens while a line on the ground shows where the bolt will fly.

const CORE := Color(1.0, 0.55, 0.2)
const FLAME := Color(1.0, 0.25, 0.08)
const LINE := Color(1.0, 0.3, 0.15)
const HOVER := 1.2
const LINE_LENGTH := 8.0

var _body: Node3D
var _light: OmniLight3D
var _core_material: StandardMaterial3D
var _line: MeshInstance3D
var _line_material: StandardMaterial3D
var _time := 0.0
var _dying := false
var _pulse := 0.0


func _ready() -> void:
	_body = Node3D.new()
	_body.position = Vector3(0, HOVER, 0)
	add_child(_body)
	_core_material = ToonMaterials.glow(CORE, 3.0)
	var core := SphereMesh.new()
	core.radius = 0.32
	core.height = 0.64
	_add(_body, core, _core_material, Vector3.ZERO)
	var flame_material := ToonMaterials.glow(FLAME, 2.0)
	flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_material.albedo_color.a = 0.75
	for i in 3:  # flickering flame tongues
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.22 - i * 0.04
		cone.height = 0.6 - i * 0.1
		var tongue := _add(_body, cone, flame_material, Vector3((i - 1) * 0.12, 0.3, 0.0))
		tongue.set_meta(&"tongue", i)
	var eye := SphereMesh.new()
	eye.radius = 0.05
	eye.height = 0.1
	for side: float in [-1.0, 1.0]:
		_add(_body, eye, ToonMaterials.toon(Color("2a1010"), 0.0), Vector3(side * 0.1, 0.05, -0.29))
	_light = OmniLight3D.new()
	_light.light_color = FLAME
	_light.light_energy = 1.0
	_light.omni_range = 4.0
	_body.add_child(_light)
	_line_material = StandardMaterial3D.new()
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_material.albedo_color = Color(LINE, 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.25, LINE_LENGTH)
	_line = _add(self, quad, _line_material, Vector3(0, 0.04, -LINE_LENGTH / 2.0))
	_line.rotation_degrees.x = -90.0
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line.visible = false


func _process(delta: float) -> void:
	if _dying:
		return
	_time += delta
	_body.position.y = HOVER + sin(_time * 2.5) * 0.12
	for child in _body.get_children():
		if child.has_meta(&"tongue"):
			var i: int = child.get_meta(&"tongue")
			(child as Node3D).scale.y = 1.0 + sin(_time * (9.0 + i * 3.0)) * 0.25
	_pulse = maxf(_pulse - delta * 4.0, 0.0)
	_body.scale = Vector3.ONE * (1.0 + _pulse * 0.4) if not _line.visible else _body.scale


## progress 0→1 brightens the flame and draws the aim line; -1 hides it.
func set_telegraph(progress: float) -> void:
	if progress < 0.0:
		_line.visible = false
		_core_material.emission_energy_multiplier = 3.0
		_light.light_energy = 1.0
		_body.scale = Vector3.ONE
		return
	var p := clampf(progress, 0.0, 1.0)
	_line.visible = true
	_line_material.albedo_color.a = lerpf(0.15, 0.7, p)
	_core_material.emission_energy_multiplier = lerpf(3.0, 8.0, p)
	_light.light_energy = lerpf(1.0, 3.0, p)
	_body.scale = Vector3.ONE * (1.0 + 0.3 * p)


func play_attack() -> void:
	set_telegraph(-1.0)
	_pulse = 1.0


func play_death() -> void:
	_dying = true
	_line.visible = false
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector3.ONE * 1.6, 0.15)
	tween.tween_property(_body, "scale", Vector3.ZERO, 0.4)
	tween.parallel().tween_property(_light, "light_energy", 0.0, 0.4)


func _add(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi
