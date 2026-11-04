class_name DragonPlaceholder
extends Node3D
## Placeholder hatchling of simple shapes at real size (about 0.6 m tall; NFR-ART-01): round body, big head and eyes,
## stubby legs, little wings, horns, back spines and a tail. One body for every element, recoloured from the
## species (GAME_DESIGN.md §8.2). Faces -Z. The Dragon calls update_motion() every frame and the play_* reactions.

const OUTLINE := 0.012
const BOB_HEIGHT := 0.025
const LEG_SWING := 35.0          ## degrees at full speed
const WING_IDLE := 12.0          ## degrees of the idle flutter
const TAIL_SWAY := 18.0          ## degrees
const HAPPY_HOP := 0.18          ## m

var species: DragonSpeciesData
var _body: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _wings: Array[Node3D] = []
var _tail: Array[Node3D] = []
var _eyes: Array[Node3D] = []
var _parts: Dictionary[StringName, Array] = {}   ## colour role → meshes
var _glow: OmniLight3D
var _time := 0.0
var _speed_ratio := 0.0
var _flap_boost := 0.0
var _knocked_out := false


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_build()
	if species:
		apply_species(species)


## Recolours the body for `kind` (and sets its glow from the Lantern Heart trait later via set_glow).
func apply_species(kind: DragonSpeciesData) -> void:
	species = kind
	if _body == null or kind == null:
		return
	var colors := {&"body": kind.body_color, &"belly": kind.belly_color, &"wing": kind.wing_color,
			&"horn": kind.horn_color, &"eye": kind.eye_color}
	# One shared material per colour; only the main body shapes get an outline (cheap on the Intel GPU).
	for role: StringName in _parts:
		var material := ToonMaterials.toon(colors.get(role, kind.body_color), 0.35, OUTLINE if role == &"body" else 0.0)
		for mesh: MeshInstance3D in _parts[role]:
			mesh.material_override = material


## A soft light around it (the Light dragon's Lantern Heart). 0 switches it off.
func set_glow(energy: float) -> void:
	_glow.visible = energy > 0.0
	_glow.light_energy = energy
	if species:
		_glow.light_color = species.breath_color


func update_motion(speed_ratio: float, delta: float) -> void:
	_time += delta
	_speed_ratio = lerpf(_speed_ratio, clampf(speed_ratio, 0.0, 1.6), 1.0 - exp(-10.0 * delta))
	_flap_boost = maxf(_flap_boost - delta, 0.0)
	if _knocked_out:
		return
	var stride := _time * (6.0 + 8.0 * _speed_ratio)
	_body.position.y = absf(sin(stride)) * BOB_HEIGHT * (0.4 + _speed_ratio)
	for i in _legs.size():
		var phase := 0.0 if i % 3 == 0 else PI  # legs are front-left, back-left, front-right, back-right: diagonals together
		_legs[i].rotation_degrees.x = sin(stride + phase) * LEG_SWING * minf(_speed_ratio, 1.0)
	var flap := sin(_time * (5.0 + 20.0 * _flap_boost)) * (WING_IDLE + 45.0 * _flap_boost)
	_wings[0].rotation_degrees.z = -20.0 - flap  # left wing: negative lifts its tip
	_wings[1].rotation_degrees.z = 20.0 + flap
	for i in _tail.size():
		_tail[i].rotation_degrees.y = sin(_time * 2.4 - i * 0.7) * TAIL_SWAY * (1.0 - 0.5 * _speed_ratio)


## Snaps the head forward (a bite).
func play_bite() -> void:
	var tween := create_tween()
	tween.tween_property(_head, "position:z", -0.36, 0.07)
	tween.tween_property(_head, "position:z", -0.2, 0.15)


## Rears the head back and puffs up for `seconds` before a breath.
func play_inhale(seconds: float) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_head, "rotation_degrees:x", 25.0, seconds)
	tween.tween_property(_body, "scale", Vector3(1.12, 1.12, 1.05), seconds)
	tween.chain().tween_property(_head, "rotation_degrees:x", -15.0, 0.08)
	tween.chain().tween_property(_body, "scale", Vector3.ONE, 0.25)
	tween.parallel().tween_property(_head, "rotation_degrees:x", 0.0, 0.25)


## A happy hop with flapping wings (treats, petting, hatching). Keeps running while paused (cutscenes).
func play_happy() -> void:
	_flap_boost = 1.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_body, "position:y", HAPPY_HOP, 0.14).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
	tween.tween_property(_body, "position:y", HAPPY_HOP * 0.5, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)


## Curled up on its side with closed eyes (knocked out), or back on its feet.
func set_knocked_out(on: bool) -> void:
	_knocked_out = on
	var tween := create_tween().set_parallel()
	tween.tween_property(_body, "rotation_degrees:z", 75.0 if on else 0.0, 0.35)
	tween.tween_property(_body, "position:y", -0.08 if on else 0.0, 0.35)
	for eye in _eyes:
		tween.tween_property(eye, "scale:y", 0.15 if on else 1.0, 0.2)


## Grows out of nothing (hatching). Runs while paused.
func pop_in(seconds := 0.45) -> void:
	scale = Vector3.ONE * 0.05
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", Vector3.ONE, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Shapes ----------------------------------------------------------------------------------------

func _build() -> void:
	var torso := _sphere(_body, 0.2, Vector3(0, 0.3, 0.02), &"body")
	torso.scale = Vector3(1.0, 0.9, 1.25)
	var belly := _sphere(_body, 0.16, Vector3(0, 0.26, -0.08), &"belly")
	belly.scale = Vector3(0.95, 0.9, 1.0)
	for i in 3:  # back spines
		var spine := _cone(_body, 0.0, 0.035, 0.08, Vector3(0, 0.49 - i * 0.03, -0.02 + i * 0.1), &"horn")
		spine.rotation_degrees.x = 20.0
	_head = _pivot(_body, Vector3(0, 0.0, -0.2))
	var skull := _sphere(_head, 0.16, Vector3(0, 0.52, 0.0), &"body")
	skull.scale = Vector3(1.05, 0.95, 1.0)
	var snout := _capsule(_head, 0.07, 0.28, Vector3(0, 0.47, -0.17), &"body")
	snout.rotation_degrees.x = 90.0
	for side: float in [-1.0, 1.0]:  # nostrils
		_sphere(_head, 0.013, Vector3(side * 0.03, 0.5, -0.305), &"eye")
	var chin := _sphere(_head, 0.06, Vector3(0, 0.43, -0.2), &"belly")
	chin.scale = Vector3(1.1, 0.6, 1.2)
	for side: float in [-1.0, 1.0]:
		var eye := _pivot(_head, Vector3(side * 0.08, 0.55, -0.13))
		_sphere(eye, 0.045, Vector3.ZERO, &"eye")
		var glint := MeshInstance3D.new()
		glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var glint_mesh := SphereMesh.new()
		glint_mesh.radius = 0.013
		glint_mesh.height = 0.026
		glint.mesh = glint_mesh
		glint.material_override = ToonMaterials.glow(Color.WHITE, 1.5)
		glint.position = Vector3(side * 0.01, 0.018, -0.035)
		eye.add_child(glint)
		_eyes.append(eye)
		var horn := _cone(_head, 0.0, 0.032, 0.13, Vector3(side * 0.07, 0.67, 0.05), &"horn")
		horn.rotation_degrees = Vector3(35.0, 0.0, -side * 12.0)  # swept back and a little outward
		var leg_front := _pivot(_body, Vector3(side * 0.12, 0.17, -0.12))
		_capsule(leg_front, 0.048, 0.18, Vector3(0, -0.07, 0), &"body")
		_sphere(leg_front, 0.05, Vector3(0, -0.15, -0.02), &"belly")
		var leg_back := _pivot(_body, Vector3(side * 0.13, 0.17, 0.14))
		_capsule(leg_back, 0.055, 0.18, Vector3(0, -0.07, 0), &"body")
		_sphere(leg_back, 0.055, Vector3(0, -0.15, -0.02), &"belly")
		_legs.append_array([leg_front, leg_back])
		var wing := _pivot(_body, Vector3(side * 0.14, 0.42, 0.02))
		var membrane := MeshInstance3D.new()
		membrane.mesh = _wing_mesh(side)
		membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wing.add_child(membrane)
		_parts.get_or_add(&"wing", []).append(membrane)
		_wings.append(wing)
	var root := _pivot(_body, Vector3(0, 0.28, 0.24))
	var lengths := [0.16, 0.14, 0.12]
	var radii := [0.075, 0.055, 0.035]
	for i in lengths.size():
		var segment := _pivot(root, Vector3.ZERO)
		var piece := _cone(segment, radii[i] * 0.7, radii[i], lengths[i], Vector3(0, 0, lengths[i] * 0.5), &"body")
		piece.rotation_degrees.x = 90.0
		_tail.append(segment)
		root = _pivot(segment, Vector3(0, 0.0, lengths[i]))
		if i == 0:
			segment.rotation_degrees.x = -12.0
	var tip := _cone(root, 0.0, 0.06, 0.09, Vector3(0, 0.0, 0.04), &"horn")
	tip.rotation_degrees.x = 90.0
	_glow = OmniLight3D.new()
	_glow.position = Vector3(0, 0.5, 0)
	_glow.omni_range = 4.0
	_glow.visible = false
	add_child(_glow)


## A triangle-ish membrane, both sides, spreading outward (+X for the right wing, −X for the left).
static func _wing_mesh(side: float) -> ArrayMesh:
	var points := [Vector3(0, 0, -0.06), Vector3(side * 0.3, 0.1, 0.02), Vector3(side * 0.2, 0.0, 0.16), Vector3(0, 0, 0.1)]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)  # flat normals: the two sides share positions
	for face: Array in [[0, 1, 2], [0, 2, 3]]:
		var a: Vector3 = points[face[0]]
		var b: Vector3 = points[face[1]]
		var c: Vector3 = points[face[2]]
		for triangle: Array in [[a, b, c], [a, c, b]]:  # front and back
			for vertex: Vector3 in triangle:
				tool.add_vertex(vertex)
	tool.generate_normals()
	return tool.commit()


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	parent.add_child(node)
	return node


func _add(parent: Node3D, mesh: Mesh, pos: Vector3, role: StringName) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	if role != &"body":  # small details cast no shadow
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_parts.get_or_add(role, []).append(mi)
	return mi


func _sphere(parent: Node3D, radius: float, pos: Vector3, role: StringName) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	return _add(parent, m, pos, role)


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, role: StringName) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	return _add(parent, m, pos, role)


func _cone(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, role: StringName) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	return _add(parent, m, pos, role)
