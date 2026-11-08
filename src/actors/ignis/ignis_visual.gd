class_name IgnisVisual
extends Node3D
## Placeholder Ignis Varos, Herald of the Final Ember (GAME_DESIGN.md §3.2: a powerful fire mage-general), made of
## simple shapes until a real model exists: a long ash-black coat over dark armour, a high crimson collar, swept-back
## dark red hair, a crown of floating ember spikes, glowing ember eyes, a burning cape and a sceptre with a fire orb;
## embers circle him. He glides rather than walks. Faces -Z.
## As an enemy: set_telegraph(0–1 / -1), play_attack(), play_death(), play_shield() (a hit that does nothing).
## In cutscenes: play_anim(&"gather" | &"release" | &"recoil" | &"vanish" | &"idle"), set_walking(speed).

const HEIGHT := 1.95
const COAT := Color(0.12, 0.08, 0.08)
const ARMOUR := Color(0.2, 0.15, 0.15)
const CRIMSON := Color(0.5, 0.08, 0.07)
const GOLD := Color(0.78, 0.56, 0.26)
const SKIN := Color(0.88, 0.8, 0.74)
const HAIR := Color(0.36, 0.07, 0.06)
const EMBER := Color(1.0, 0.42, 0.12)
const EMBER_COUNT := 7
const CROWN_SPIKES := 5
const GATHER_SIZE := 1.1   ## m radius of the ember sphere he raises for the final blow
const OUTLINE := 0.014

var _body: Node3D
var _arm: Node3D
var _cape: Node3D
var _orb_material: StandardMaterial3D
var _eye_material: StandardMaterial3D
var _crown: Node3D
var _embers: Array[MeshInstance3D] = []
var _glow: OmniLight3D
var _shield: MeshInstance3D
var _shield_material: StandardMaterial3D
var _gather: MeshInstance3D
var _time := 0.0
var _speed := 0.0
var _gone := false


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	_time += delta
	var parent := get_parent() as CharacterBody3D
	var speed := _speed
	if parent and speed <= 0.0:
		speed = Vector2(parent.velocity.x, parent.velocity.z).length()
	_body.position.y = 0.04 + sin(_time * 1.6) * 0.03 + minf(speed, 3.0) * 0.015
	_body.rotation.x = -minf(speed, 4.0) * 0.03
	_cape.rotation.x = 0.12 + sin(_time * 1.3) * 0.05 + minf(speed, 4.0) * 0.1
	_crown.rotation.y = sin(_time * 0.7) * 0.15
	for i in _embers.size():
		var a := _time * (0.6 + 0.07 * i) + TAU * i / _embers.size()
		_embers[i].position = Vector3(cos(a) * (0.75 + 0.1 * (i % 3)), 0.5 + 0.22 * i + sin(_time * 2.0 + i) * 0.1,
				sin(a) * (0.75 + 0.1 * (i % 3)))
	if _gather.visible:
		_gather.rotation.y += delta * 2.0


## Wind-up: the sceptre rises, the orb, eyes and light burn brighter. -1 relaxes.
func set_telegraph(progress: float) -> void:
	if _gone:
		return
	var p := clampf(progress, 0.0, 1.0) if progress >= 0.0 else 0.0
	_arm.rotation_degrees.x = 140.0 * p
	_orb_material.emission_energy_multiplier = 3.0 + 6.0 * p
	_eye_material.emission_energy_multiplier = 3.0 + 3.0 * p
	_glow.light_energy = 0.8 + 2.5 * p


func play_attack() -> void:
	var tween := create_tween()
	tween.tween_property(_arm, "rotation_degrees:x", 60.0, 0.08)
	tween.tween_property(_arm, "rotation_degrees:x", 0.0, 0.4)


func play_death() -> void:
	play_anim(&"vanish")


## A hit that does nothing: an ember shell flares around him.
func play_shield() -> void:
	_shield.visible = true
	_shield.scale = Vector3.ONE * 0.9
	_shield_material.albedo_color.a = 0.45
	var tween := create_tween()
	tween.tween_property(_shield, "scale", Vector3.ONE * 1.1, 0.25)
	tween.parallel().tween_property(_shield_material, "albedo_color:a", 0.0, 0.35)
	tween.tween_callback(_shield.hide)


func set_walking(speed: float) -> void:
	_speed = speed


## Cutscene animations. Returns how long they take.
func play_anim(anim_name: StringName) -> float:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if Cutscene.skipping:
		tween.set_speed_scale(CutsceneScene.SKIP_SPEED)
	match anim_name:
		&"gather":  # the sceptre rises and a great ember sphere grows above him
			_gather.visible = true
			_gather.scale = Vector3.ONE * 0.05
			tween.tween_property(_arm, "rotation_degrees:x", 170.0, 0.4)
			tween.parallel().tween_property(_gather, "scale", Vector3.ONE, 1.6).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_glow, "light_energy", 5.0, 1.6)
			return 1.6
		&"release":  # the sphere breaks apart
			tween.tween_property(_gather, "scale", Vector3.ONE * 1.6, 0.15)
			tween.tween_callback(_gather.hide)
			tween.tween_property(_arm, "rotation_degrees:x", 0.0, 0.4)
			tween.parallel().tween_property(_glow, "light_energy", 0.8, 0.6)
			return 0.6
		&"recoil":  # thrown back a step by a dragon's breath
			_gather.hide()
			tween.tween_property(_body, "rotation_degrees:x", 18.0, 0.15)
			tween.tween_property(_body, "rotation_degrees:x", 0.0, 0.6)
			tween.parallel().tween_property(_arm, "rotation_degrees:x", 30.0, 0.3)
			play_shield()
			return 0.75
		&"vanish":  # rises in a whirl of embers and is gone
			_gone = true
			tween.tween_property(_body, "position:y", 0.6, 0.9).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(_body, "scale", Vector3(0.2, 1.4, 0.2), 0.9).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(_glow, "light_energy", 6.0, 0.5)
			tween.tween_property(_glow, "light_energy", 0.0, 0.3)
			tween.tween_callback(hide)
			return 1.2
		_:
			_arm.rotation_degrees.x = 0.0
			_gather.hide()
			return 0.0


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	var h := HEIGHT
	# The long coat hides his legs: he glides.
	_cylinder(_body, 0.2, 0.46, h * 0.58, Vector3(0, h * 0.29, 0), COAT, true)
	_cylinder(_body, 0.47, 0.49, 0.06, Vector3(0, 0.03, 0), CRIMSON, false)  # burning hem
	_glow_box(_body, Vector3(0.05, h * 0.5, 0.02), Vector3(0, h * 0.3, -0.33), EMBER, 1.6)  # seam of ember light
	# Armoured chest, belt, ember heart.
	_box(_body, Vector3(0.5, h * 0.25, 0.32), Vector3(0, h * 0.66, 0), ARMOUR, true)
	_box(_body, Vector3(0.52, 0.06, 0.34), Vector3(0, h * 0.55, 0), GOLD, false)
	_glow_sphere(_body, 0.06, Vector3(0, h * 0.7, -0.17), EMBER, 4.0)
	for side: float in [-1.0, 1.0]:  # pauldrons with spikes
		var pauldron := _box(_body, Vector3(0.24, 0.08, 0.34), Vector3(side * 0.34, h * 0.78, 0), ARMOUR.lightened(0.1), true)
		pauldron.rotation_degrees.z = -side * 18.0
		var spike := _cone(_body, 0.0, 0.05, 0.22, Vector3(side * 0.42, h * 0.84, 0), GOLD, true)
		spike.rotation_degrees.z = -side * 35.0
	# A high collar standing up behind his head and at its sides (open at the front, so his face shows).
	var back := _box(_body, Vector3(0.36, 0.3, 0.04), Vector3(0, h * 0.9, 0.15), CRIMSON, true)
	back.rotation_degrees.x = -15.0
	for side: float in [-1.0, 1.0]:
		var wing := _box(_body, Vector3(0.04, 0.24, 0.2), Vector3(side * 0.19, h * 0.88, 0.05), CRIMSON, true)
		wing.rotation_degrees.y = side * 25.0
	# Head, hair swept back, ember eyes.
	_sphere(_body, 0.13, Vector3(0, h * 0.91, -0.02), SKIN, true)
	var hair := _sphere(_body, 0.14, Vector3(0, h * 0.93, 0.04), HAIR, true)
	hair.scale = Vector3(1.0, 0.9, 1.15)
	var tail := _cone(_body, 0.11, 0.0, 0.5, Vector3(0, h * 0.82, 0.16), HAIR, true)
	tail.rotation_degrees.x = 150.0
	_eye_material = ToonMaterials.glow(EMBER, 3.0)
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.022
		eye_mesh.height = 0.03
		eye.mesh = eye_mesh
		eye.material_override = _eye_material
		eye.position = Vector3(side * 0.045, h * 0.915, -0.135)
		_body.add_child(eye)
	# A crown of ember spikes floating over his head.
	_crown = Node3D.new()
	_crown.position = Vector3(0, h * 1.0, 0)
	_body.add_child(_crown)
	for i in CROWN_SPIKES:
		var a := PI * (0.2 + 0.6 * i / (CROWN_SPIKES - 1.0))
		var spike := _glow_cone(_crown, 0.035, 0.14 + 0.06 * (1 - absi(i - 2) / 2.0), Vector3(cos(a) * 0.13, 0, -sin(a) * 0.1 + 0.02), EMBER, 3.5)
		spike.rotation_degrees.z = (i - 2) * -12.0
	# Cape.
	_cape = Node3D.new()
	_cape.position = Vector3(0, h * 0.8, 0.16)
	_body.add_child(_cape)
	_box(_cape, Vector3(0.62, h * 0.74, 0.04), Vector3(0, -h * 0.37, 0.05), CRIMSON.darkened(0.3), true)
	_glow_box(_cape, Vector3(0.62, 0.05, 0.05), Vector3(0, -h * 0.74, 0.05), EMBER, 2.0)
	# Left arm at his side; right arm holds the sceptre.
	_box(_body, Vector3(0.11, h * 0.3, 0.11), Vector3(-0.33, h * 0.62, 0), COAT, true)
	_arm = Node3D.new()
	_arm.position = Vector3(0.33, h * 0.76, 0)
	_body.add_child(_arm)
	_box(_arm, Vector3(0.11, h * 0.3, 0.11), Vector3(0, -h * 0.14, 0), COAT, true)
	var sceptre := _cylinder(_arm, 0.02, 0.025, 1.3, Vector3(0, -h * 0.2, -0.35), Color(0.1, 0.08, 0.08), true)
	sceptre.rotation_degrees.x = -90.0
	_orb_material = ToonMaterials.glow(EMBER, 3.0)
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.1
	orb_mesh.height = 0.2
	orb.mesh = orb_mesh
	orb.material_override = _orb_material
	orb.position = Vector3(0, -h * 0.2, -1.0)
	_arm.add_child(orb)
	# Embers circling him.
	for i in EMBER_COUNT:
		_embers.append(_glow_sphere(self, 0.03 + 0.01 * (i % 3), Vector3.ZERO, EMBER, 3.0))
	_glow = OmniLight3D.new()
	_glow.light_color = EMBER
	_glow.light_energy = 0.8
	_glow.omni_range = 4.0
	_glow.position = Vector3(0, h * 0.8, -0.4)
	add_child(_glow)
	# The ember shell (hits that do nothing) and the great sphere of his final blow.
	_shield_material = StandardMaterial3D.new()
	_shield_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_material.albedo_color = Color(EMBER, 0.0)
	_shield_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield = MeshInstance3D.new()
	var shell := SphereMesh.new()
	shell.radius = 0.9
	shell.height = 2.2
	_shield.mesh = shell
	_shield.material_override = _shield_material
	_shield.position = Vector3(0, h * 0.5, 0)
	_shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield.visible = false
	add_child(_shield)
	_gather = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = GATHER_SIZE
	sphere.height = GATHER_SIZE * 2.0
	_gather.mesh = sphere
	_gather.material_override = ToonMaterials.glow(EMBER, 5.0)
	_gather.position = Vector3(0, h + GATHER_SIZE + 0.6, 0)
	_gather.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gather.visible = false
	add_child(_gather)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, outline: bool) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, ToonMaterials.toon(color, 0.3, OUTLINE if outline else 0.0))


func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, outline: bool) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add(parent, mesh, pos, ToonMaterials.toon(color, 0.3, OUTLINE if outline else 0.0))


func _cylinder(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, color: Color,
		outline: bool) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	return _add(parent, mesh, pos, ToonMaterials.toon(color, 0.3, OUTLINE if outline else 0.0))


func _cone(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, color: Color,
		outline: bool) -> MeshInstance3D:
	return _cylinder(parent, top, bottom, height, pos, color, outline)


func _glow_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, ToonMaterials.glow(color, energy))


func _glow_sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := _add(parent, mesh, pos, ToonMaterials.glow(color, energy))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _glow_cone(parent: Node3D, bottom: float, height: float, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = bottom
	mesh.height = height
	var mi := _add(parent, mesh, pos + Vector3(0, height * 0.5, 0), ToonMaterials.glow(color, energy))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _add(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi
