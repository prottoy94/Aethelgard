class_name EmberboundVisual
extends Node3D
## Placeholder Emberbound soldier of simple shapes (GAME_DESIGN.md §7.1): legs, armoured body, helmet with a glowing
## ember visor, shoulder plates and a weapon. Sized and coloured per enemy (a Scout with a sword, the Cinder Warden
## with a huge cleaver). Faces -Z. Enemies call set_telegraph(0–1 / -1), play_attack() and play_death().

@export var height := 1.75
@export var armour := Color(0.28, 0.24, 0.24)
@export var cloth := Color(0.55, 0.16, 0.12)
@export var trim := Color(0.72, 0.52, 0.28)
@export var ember := Color(1.0, 0.42, 0.12)
@export var weapon_length := 1.0
@export var weapon_width := 0.12
@export var bulk := 1.0              ## wider shoulders and body

var _body: Node3D
var _arm: Node3D
var _visor_material: StandardMaterial3D
var _glow: OmniLight3D
var _time := 0.0
var _dying := false


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var h := height
	var w := 0.22 * bulk
	for side: float in [-1.0, 1.0]:
		_box(_body, Vector3(w * 0.7, h * 0.42, w * 0.8), Vector3(side * w * 0.55, h * 0.21, 0), armour.darkened(0.2), true)
	_box(_body, Vector3(w * 2.4, h * 0.36, w * 1.5), Vector3(0, h * 0.58, 0), armour, true)
	_box(_body, Vector3(w * 2.5, h * 0.16, w * 1.6), Vector3(0, h * 0.44, 0), cloth, false)  # tabard / belt
	_box(_body, Vector3(w * 0.6, h * 0.05, w * 1.62), Vector3(0, h * 0.5, 0), trim, false)
	for side: float in [-1.0, 1.0]:
		var pauldron := _box(_body, Vector3(w * 1.0, h * 0.08, w * 1.3), Vector3(side * w * 1.45, h * 0.74, 0), trim, true)
		pauldron.rotation_degrees.z = -side * 15.0
	_box(_body, Vector3(w * 1.3, h * 0.17, w * 1.3), Vector3(0, h * 0.86, 0), armour.lightened(0.1), true)  # helmet
	_visor_material = ToonMaterials.glow(ember, 2.0)
	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(w * 1.0, h * 0.03, 0.02)
	visor.mesh = visor_mesh
	visor.material_override = _visor_material
	visor.position = Vector3(0, h * 0.87, -w * 0.66)
	_body.add_child(visor)
	var crest := _box(_body, Vector3(0.05, h * 0.09, w * 1.1), Vector3(0, h * 0.98, 0), cloth, false)
	crest.rotation_degrees.x = 10.0
	_arm = Node3D.new()
	_arm.position = Vector3(w * 1.45, h * 0.68, 0)
	_body.add_child(_arm)
	_box(_arm, Vector3(w * 0.5, h * 0.3, w * 0.5), Vector3(0, -h * 0.15, 0), armour, true)
	var blade := _box(_arm, Vector3(weapon_width, weapon_length, 0.04), Vector3(0, -h * 0.28, -weapon_length * 0.5), Color(0.75, 0.72, 0.7), true)
	blade.rotation_degrees.x = -90.0
	var edge := MeshInstance3D.new()
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(weapon_width * 0.35, weapon_length * 0.9, 0.05)
	edge.mesh = edge_mesh
	edge.material_override = ToonMaterials.glow(ember, 1.5)
	edge.position = blade.position + Vector3(0, 0, 0)
	edge.rotation_degrees.x = -90.0
	_arm.add_child(edge)
	_glow = OmniLight3D.new()
	_glow.light_color = ember
	_glow.light_energy = 0.4
	_glow.omni_range = 2.5 * bulk
	_glow.position = Vector3(0, h * 0.8, -0.3)
	add_child(_glow)


func _process(delta: float) -> void:
	if _dying:
		return
	_time += delta
	var parent := get_parent() as CharacterBody3D
	var speed := Vector2(parent.velocity.x, parent.velocity.z).length() if parent else 0.0
	_body.position.y = absf(sin(_time * 9.0)) * 0.04 * minf(speed, 1.0)


## Wind-up: the weapon rises behind, the visor and edge glow brighter. -1 relaxes.
func set_telegraph(progress: float) -> void:
	if _dying:
		return
	var p := clampf(progress, 0.0, 1.0) if progress >= 0.0 else 0.0
	_arm.rotation_degrees.x = 110.0 * p
	_visor_material.emission_energy_multiplier = 2.0 + 4.0 * p
	_glow.light_energy = 0.4 + 2.0 * p


func play_attack() -> void:
	var tween := create_tween()
	tween.tween_property(_arm, "rotation_degrees:x", -70.0, 0.08)
	tween.tween_property(_arm, "rotation_degrees:x", 0.0, 0.35)


func play_death() -> void:
	_dying = true
	var tween := create_tween()
	tween.tween_property(_body, "rotation_degrees:x", 85.0, 0.6).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_glow, "light_energy", 0.0, 0.6)
	tween.parallel().tween_property(_body, "position:y", -0.2, 0.6)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, outline: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = ToonMaterials.toon(color, 0.3, 0.015 if outline else 0.0)
	mi.position = pos
	parent.add_child(mi)
	return mi
