class_name Sylvaris
extends CutsceneActor
## Sylvaris, the elder dragon who guards the World Tree (GAME_DESIGN.md §3.2, approved 2026-11-04). In the prologue he
## drives Ignis off and speaks to Aurelia. A placeholder of simple shapes until a real model exists: a long moss-green
## body with a bark-brown belly, antler-like horns branching like old wood, a mane of leaves, amber eyes, gold-leaf
## scales on his back and broad wings veined like leaves. About 4.5 m to the top of his head, 9 m nose to tail.
## Cutscene animations (play_anim): &"land", &"roar", &"breath", &"breath_end", &"bow", &"rise", &"take_off";
## a cutscene move flaps his wings (set_walking).

const SCALES := Color(0.25, 0.4, 0.26)
const BELLY := Color(0.55, 0.45, 0.3)
const BARK := Color(0.4, 0.29, 0.2)
const GOLD := Color(0.88, 0.72, 0.34)
const LEAF := Color(0.42, 0.62, 0.33)
const MEMBRANE := Color(0.52, 0.68, 0.4)
const EYE := Color(1.0, 0.72, 0.3)
const BREATH := Color(1.0, 0.92, 0.6)
const OUTLINE := 0.03
const NECK_SEGMENTS := 3
const HEAD_SCALE := 1.45
const TAIL_SEGMENTS := 7
const BREATH_LENGTH := 9.0   ## m
const FLAP_RATE := 5.0
const IDLE_WING_DEG := 8.0

var _body: Node3D
var _neck: Array[Node3D] = []
var _head: Node3D
var _jaw: Node3D
var _wings: Array[Node3D] = []
var _tail: Array[Node3D] = []
var _breath: MeshInstance3D
var _breath_material: StandardMaterial3D
var _light: OmniLight3D
var _time := 0.0
var _flap := 0.0          ## 0 folded … 1 flapping hard
var _wing_open := 0.15    ## 0 folded … 1 spread
var _head_lift := 0.0     ## extra head angle from animations (degrees, + = up)


func _init() -> void:
	actor_id = &"sylvaris"
	emote_height = 5.0


func _ready() -> void:
	super()
	_build()


func _process(delta: float) -> void:
	_time += delta
	_body.scale = Vector3(1.0, 1.0 + sin(_time * 1.1) * 0.012, 1.0)  # slow breathing
	for i in _tail.size():
		_tail[i].rotation.y = sin(_time * 0.9 - i * 0.5) * 0.08
	for i in _neck.size():
		_neck[i].rotation.x = deg_to_rad(-7.0 + sin(_time * 0.8 + i * 0.3) * 1.5 + _head_lift / NECK_SEGMENTS)
	var beat := sin(_time * FLAP_RATE) * 55.0 * _flap
	for k in _wings.size():
		var side := -1.0 if k == 0 else 1.0
		# Folded, the wings sweep back along his body; spread, they reach out to the sides.
		var sweep := deg_to_rad(lerpf(72.0, 0.0, _wing_open))
		var tilt := lerpf(14.0, 6.0, _wing_open) + beat + sin(_time * 1.2) * IDLE_WING_DEG * (1.0 - _flap)
		_wings[k].rotation = Vector3(0, -side * sweep, deg_to_rad(side * tilt))
	if _breath.visible:
		_breath_material.albedo_color.a = 0.55 + sin(_time * 30.0) * 0.1


func set_walking(speed: float) -> void:
	_flap = clampf(speed / 4.0, 0.0, 1.0)
	_wing_open = 1.0 if speed > 0.1 else _wing_open


func play_anim(anim_name: StringName) -> float:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if Cutscene.skipping:
		tween.set_speed_scale(CutsceneScene.SKIP_SPEED)
	match anim_name:
		&"land":  # wings spread wide, then fold
			_flap = 0.0
			tween.tween_property(self, "_wing_open", 1.0, 0.3)
			tween.tween_property(self, "_wing_open", 0.15, 1.0).set_delay(0.4)
			AudioManager.play(&"world_sylvaris_wings", global_position)
			return 1.7
		&"roar":
			tween.tween_property(self, "_head_lift", 35.0, 0.35).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_jaw, "rotation_degrees:x", 28.0, 0.35)
			tween.tween_interval(0.8)
			tween.tween_property(self, "_head_lift", 0.0, 0.5)
			tween.parallel().tween_property(_jaw, "rotation_degrees:x", 0.0, 0.5)
			AudioManager.play(&"world_sylvaris_roar", global_position)
			return 1.65
		&"breath":  # a stream of golden light from his jaws
			_breath.visible = true
			_breath.scale = Vector3(0.2, 0.02, 0.2)
			tween.tween_property(self, "_head_lift", -12.0, 0.25)
			tween.parallel().tween_property(_jaw, "rotation_degrees:x", 32.0, 0.25)
			tween.tween_property(_breath, "scale", Vector3.ONE, 0.35).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(_light, "light_energy", 4.0, 0.35)
			AudioManager.play(&"world_sylvaris_breath", global_position)
			return 0.6
		&"breath_end":
			tween.tween_property(_breath, "scale", Vector3(0.05, 1.0, 0.05), 0.3)
			tween.parallel().tween_property(_light, "light_energy", 0.6, 0.5)
			tween.parallel().tween_property(_jaw, "rotation_degrees:x", 0.0, 0.4)
			tween.parallel().tween_property(self, "_head_lift", 0.0, 0.5)
			tween.tween_callback(_breath.hide)
			return 0.5
		&"bow":  # lowers his head towards the little light
			tween.tween_property(self, "_head_lift", -28.0, 0.9).set_trans(Tween.TRANS_SINE)
			return 0.9
		&"rise":
			tween.tween_property(self, "_head_lift", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
			return 0.7
		&"take_off":  # wings beat and he climbs away
			_wing_open = 1.0
			tween.tween_property(self, "_flap", 1.0, 0.3)
			tween.tween_property(self, "position", position + Vector3(0, 14, 0) - global_basis.z * 10.0, 2.2) \
					.set_ease(Tween.EASE_IN)
			tween.tween_callback(hide)
			AudioManager.play(&"world_sylvaris_wings", global_position)
			return 2.5
	return 0.0


## Where his breath comes from (cues aim effects with it).
func mouth_position() -> Vector3:
	return _jaw.global_position


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	# Body: a long barrel with a lighter belly, gold-leaf scales along the spine.
	var torso := _capsule(_body, 1.05, 4.6, Vector3(0, 1.75, 0.2), SCALES)
	torso.rotation_degrees.x = 90.0
	var belly := _capsule(_body, 0.85, 3.6, Vector3(0, 1.45, 0.1), BELLY)
	belly.rotation_degrees.x = 90.0
	for i in 6:
		var plate := _sphere(_body, 0.28 - i * 0.02, Vector3(0, 2.8 - i * 0.05, -1.4 + i * 0.7), GOLD)
		plate.scale = Vector3(1.0, 0.45, 1.3)
	# Legs: thick and clawed.
	for corner: Vector3 in [Vector3(-0.75, 0, -1.3), Vector3(0.75, 0, -1.3), Vector3(-0.8, 0, 1.5), Vector3(0.8, 0, 1.5)]:
		_capsule(_body, 0.33, 1.6, corner + Vector3(0, 0.8, 0), SCALES.darkened(0.15))
		var foot := _sphere(_body, 0.36, corner + Vector3(0, 0.15, -0.15), BARK)
		foot.scale = Vector3(1.0, 0.45, 1.4)
	# Neck: segments rising forward, with a leafy mane.
	var parent := _body
	var at := Vector3(0, 2.2, -2.0)
	for i in NECK_SEGMENTS:
		var joint := Node3D.new()
		joint.position = at
		parent.add_child(joint)
		_neck.append(joint)
		var segment := _sphere(joint, 0.7 - i * 0.08, Vector3(0, 0.25, -0.3), SCALES)
		segment.scale = Vector3(1.0, 1.1, 1.35)
		var leaf := _sphere(joint, 0.24, Vector3(0, 0.82 - i * 0.06, -0.15), LEAF)
		leaf.scale = Vector3(0.35, 1.0, 1.5)
		parent = joint
		at = Vector3(0, 0.45, -0.5)
	# Head: a long snout, a jaw that opens, amber eyes and branching horns like old wood.
	_head = Node3D.new()
	_head.position = Vector3(0, 0.5, -0.55)
	_head.scale = Vector3.ONE * HEAD_SCALE
	parent.add_child(_head)
	var skull := _box(_head, Vector3(0.8, 0.55, 1.0), Vector3(0, 0.1, -0.2), SCALES)
	skull.rotation_degrees.x = 5.0
	_box(_head, Vector3(0.55, 0.35, 0.9), Vector3(0, 0.0, -0.95), SCALES.lightened(0.05))  # snout
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, -0.15, -0.55)
	_head.add_child(_jaw)
	_box(_jaw, Vector3(0.5, 0.16, 0.95), Vector3(0, -0.06, -0.4), BELLY)
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.09
		eye_mesh.height = 0.14
		eye.mesh = eye_mesh
		eye.material_override = ToonMaterials.glow(EYE, 2.5)
		eye.position = Vector3(side * 0.36, 0.22, -0.55)
		_head.add_child(eye)
		var horn := _cylinder(_head, 0.03, 0.12, 1.3, Vector3(side * 0.3, 0.75, 0.15), BARK)
		horn.rotation_degrees = Vector3(-35.0, 0, -side * 22.0)
		for k in 2:  # tines
			var tine := _cylinder(horn, 0.02, 0.06, 0.55, Vector3(side * 0.15, -0.1 + k * 0.35, 0), BARK.lightened(0.08))
			tine.rotation_degrees.z = -side * 50.0
		var whisker := _cylinder(_head, 0.01, 0.04, 0.8, Vector3(side * 0.28, -0.05, -1.3), GOLD)
		whisker.rotation_degrees = Vector3(70.0, 0, side * 30.0)
	# Breath: a cone of golden light from the jaws, pointing ahead.
	_breath_material = StandardMaterial3D.new()
	_breath_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_breath_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_breath_material.albedo_color = Color(BREATH, 0.6)
	_breath_material.emission_enabled = true
	_breath_material.emission = BREATH
	_breath_material.emission_energy_multiplier = 3.0
	_breath_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_breath = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.15
	cone.bottom_radius = 1.4
	cone.height = BREATH_LENGTH
	_breath.mesh = cone
	_breath.material_override = _breath_material
	_breath.rotation_degrees.x = -90.0
	_breath.position = Vector3(0, 0, -BREATH_LENGTH * 0.5 - 0.8)
	_breath.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_breath.visible = false
	_jaw.add_child(_breath)
	# Tail: tapering, swaying.
	parent = _body
	at = Vector3(0, 1.6, 2.6)
	for i in TAIL_SEGMENTS:
		var joint := Node3D.new()
		joint.position = at
		parent.add_child(joint)
		_tail.append(joint)
		var r := 0.55 * (1.0 - float(i) / TAIL_SEGMENTS) + 0.1
		var segment := _sphere(joint, r, Vector3(0, -0.08, 0.35), SCALES)
		segment.scale = Vector3(1.0, 0.9, 1.5)
		if i == TAIL_SEGMENTS - 1:
			var tip := _sphere(joint, 0.3, Vector3(0, 0, 0.8), LEAF)
			tip.scale = Vector3(0.3, 1.0, 1.6)
		parent = joint
		at = Vector3(0, -0.06, 0.7)
	# Wings: hinged at the shoulders, a bone along the top and a leaf-veined membrane.
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(side * 0.85, 2.55, -0.9)
		_body.add_child(hinge)
		_wings.append(hinge)
		var bone := _cylinder(hinge, 0.06, 0.13, 4.2, Vector3(side * 2.1, 0.2, 0), BARK)
		bone.rotation_degrees.z = 90.0
		var membrane := _box(hinge, Vector3(4.0, 0.05, 2.6), Vector3(side * 2.1, 0.1, 1.2), MEMBRANE)
		membrane.rotation_degrees.y = side * 8.0
		for k in 3:  # veins
			var vein := _box(hinge, Vector3(0.05, 0.07, 2.4), Vector3(side * (0.9 + k * 1.2), 0.13, 1.2), LEAF.darkened(0.2))
			vein.rotation_degrees.y = side * (15.0 - k * 10.0)
	_light = OmniLight3D.new()
	_light.light_color = BREATH
	_light.light_energy = 0.6
	_light.omni_range = 8.0
	_light.position = Vector3(0, 3.5, -2.5)
	add_child(_light)


func _material(color: Color) -> Material:
	return ToonMaterials.toon(color, 0.3, OUTLINE)


func _add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add(parent, mesh, pos, color)


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return _add(parent, mesh, pos, color)


func _cylinder(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	return _add(parent, mesh, pos, color)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, color)
