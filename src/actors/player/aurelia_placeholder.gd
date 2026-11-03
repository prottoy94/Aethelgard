extends Node3D
## Placeholder Aurelia built from simple shapes, following her character art (Game Images/white_hair_girl_character.jpeg):
## silver hair with crown braid + beaded side braids, pointed ears, red teardrop earrings, plum hooded capelet with
## gold trim over a long cape, knee-length green coat over a cream dress, brown belts, satchel on the left hip,
## fingerless gloves, dark leggings, and her staff (AureliaStaff) in her right hand.
## Faces -Z, feet at the origin, ~1.6 m tall. Replaced by the VRoid model in Phase 2b; Player only calls update_motion().

const HAIR := Color("dcdce6")
const SKIN := Color("f5dccb")
const EYES := Color("c98a3a")
const CAPE := Color("4b2840")
const GOLD := Color("d4a849")
const COAT := Color("2f5a3a")
const DRESS := Color("e8e0c8")
const SLEEVE := Color("f1ede2")
const LEATHER := Color("5a3a24")
const LEGGINGS := Color("3a2a28")
const BEAD := Color("8fd3ff")
const EARRING := Color("c0392b")
const OUTLINE := 0.012

## Procedural animation strength
const BOB_HEIGHT := 0.035
const BOB_RATE := 11.0
const LEAN_DEG := 9.0
const DASH_LEAN_DEG := 20.0
const CAPE_SWING_DEG := 22.0
const DASH_CAPE_DEG := 50.0

var _body: Node3D        # everything above the feet: leans and bobs
var _cape: Node3D        # long cape, pivots at the shoulders
var _hair_back: Node3D   # long hair, pivots at the head
var _staff: AureliaStaff
var _time := 0.0
var _lean := 0.0
var _cape_angle := 0.0


func _ready() -> void:
	_body = _pivot(self, Vector3.ZERO)
	_build_legs()
	_build_clothes()
	_build_arms()
	_build_head()
	_build_staff()


## Called every frame by the Player. speed_ratio = current speed / walk speed.
func update_motion(speed_ratio: float, dashing: bool, delta: float, _speed := 0.0) -> void:
	_time += delta
	var moving := clampf(speed_ratio, 0.0, 1.0)
	var target_lean := DASH_LEAN_DEG if dashing else LEAN_DEG * moving
	_lean = lerpf(_lean, target_lean, 1.0 - exp(-12.0 * delta))
	_body.rotation_degrees.x = -_lean
	_body.position.y = absf(sin(_time * BOB_RATE)) * BOB_HEIGHT * moving
	var breathe := sin(_time * 2.2) * 2.0
	var target_cape := (DASH_CAPE_DEG if dashing else CAPE_SWING_DEG * moving) + breathe
	_cape_angle = lerpf(_cape_angle, target_cape, 1.0 - exp(-6.0 * delta))
	_cape.rotation_degrees.x = _cape_angle
	_hair_back.rotation_degrees.x = _cape_angle * 0.6
	_staff.set_swing(moving)


# --- Building ------------------------------------------------------------------------------

func _build_legs() -> void:
	for side: float in [-1.0, 1.0]:
		_capsule(_body, 0.055, 0.6, Vector3(side * 0.07, 0.3, 0), LEGGINGS, OUTLINE)
		_box(_body, Vector3(0.1, 0.12, 0.17), Vector3(side * 0.07, 0.06, -0.02), LEATHER, OUTLINE)


func _build_clothes() -> void:
	_cone(_body, 0.13, 0.25, 0.34, Vector3(0, 0.66, 0), DRESS, OUTLINE)            # cream dress
	_cone(_body, 0.135, 0.27, 0.62, Vector3(0, 0.82, 0.015), COAT, OUTLINE)         # green coat
	_cone(_body, 0.272, 0.275, 0.025, Vector3(0, 0.52, 0.015), GOLD, 0.0)           # coat hem trim
	_box(_body, Vector3(0.08, 0.36, 0.02), Vector3(0, 0.66, -0.245), DRESS, 0.0)    # dress showing at the open coat
	_torus(_body, 0.16, 0.19, Vector3(0, 0.9, 0), LEATHER)                          # belt
	_torus(_body, 0.165, 0.195, Vector3(0, 0.84, 0), LEATHER)                       # second belt
	_box(_body, Vector3(0.03, 0.5, 0.02), Vector3(0.0, 1.1, -0.15), LEATHER, 0.0).rotation_degrees.z = 35.0  # cross strap
	_box(_body, Vector3(0.06, 0.15, 0.17), Vector3(-0.22, 0.8, 0.0), LEATHER, OUTLINE)  # satchel, left hip
	_cone(_body, 0.1, 0.28, 0.2, Vector3(0, 1.28, 0.01), CAPE, OUTLINE)             # hooded capelet
	_torus(_body, 0.26, 0.29, Vector3(0, 1.185, 0.01), GOLD)                        # gold embroidered trim
	_sphere(_body, 0.11, Vector3(0, 1.36, 0.13), CAPE, 0.0).scale = Vector3(1.2, 0.75, 0.8)  # hood, down
	_cape = _pivot(_body, Vector3(0, 1.3, 0.12))
	_box(_cape, Vector3(0.52, 1.0, 0.035), Vector3(0, -0.5, 0.04), CAPE, OUTLINE)    # long cape
	_box(_cape, Vector3(0.53, 0.04, 0.04), Vector3(0, -1.0, 0.04), GOLD, 0.0)        # cape hem trim


func _build_arms() -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := _pivot(_body, Vector3(side * 0.2, 1.22, 0))
		shoulder.rotation_degrees.z = side * 12.0
		_capsule(shoulder, 0.05, 0.24, Vector3(0, -0.1, 0), SLEEVE, OUTLINE)       # white sleeve
		_capsule(shoulder, 0.04, 0.24, Vector3(0, -0.3, 0), LEATHER, OUTLINE)      # glove/forearm
		_sphere(shoulder, 0.042, Vector3(0, -0.43, -0.01), LEATHER, 0.0)           # hand


func _build_head() -> void:
	_sphere(_body, 0.13, Vector3(0, 1.47, 0), SKIN, OUTLINE)
	var hair := _sphere(_body, 0.14, Vector3(0, 1.52, 0.035), HAIR, OUTLINE)
	hair.scale = Vector3(1.08, 1.0, 0.95)
	_torus(_body, 0.11, 0.135, Vector3(0, 1.57, 0.02), HAIR).rotation_degrees.x = 12.0  # crown braid
	_hair_back = _pivot(_body, Vector3(0, 1.5, 0.08))
	var long_hair := _capsule(_hair_back, 0.1, 0.62, Vector3(0, -0.28, 0.02), HAIR, OUTLINE)
	long_hair.scale = Vector3(1.4, 1.0, 0.6)
	for side: float in [-1.0, 1.0]:
		for i in 5:  # side braids
			_sphere(_body, 0.028, Vector3(side * 0.12, 1.42 - i * 0.06, -0.03), HAIR, 0.0)
		_sphere(_body, 0.02, Vector3(side * 0.12, 1.12, -0.03), BEAD, 0.0)
		var ear := _cone(_body, 0.0, 0.025, 0.11, Vector3(side * 0.135, 1.49, 0.0), SKIN, 0.0)
		ear.rotation_degrees = Vector3(-15.0, 0.0, -side * 72.0)  # pointed elf ears, tilted back
		_sphere(_body, 0.018, Vector3(side * 0.045, 1.475, -0.118), EYES, 0.0)
		_sphere(_body, 0.012, Vector3(side * 0.128, 1.42, -0.01), EARRING, 0.0)


func _build_staff() -> void:
	_staff = AureliaStaff.new()
	_staff.position = Vector3(0.27, 0.85, -0.08)  # in her right hand
	_body.add_child(_staff)


# --- Shape helpers -------------------------------------------------------------------------

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	parent.add_child(node)
	return node


func _add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, outline: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterials.toon(color, 0.3, outline)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, outline: float) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	return _add(parent, m, pos, color, outline)


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, outline: float) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	return _add(parent, m, pos, color, outline)


func _cone(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, color: Color, outline: float) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	return _add(parent, m, pos, color, outline)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, outline: float) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add(parent, m, pos, color, outline)


func _torus(parent: Node3D, inner: float, outer: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	var mi := _add(parent, m, pos, color, 0.0)
	mi.scale = Vector3(1.0, 0.45, 1.0)
	return mi
