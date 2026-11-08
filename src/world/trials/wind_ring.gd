class_name WindRing
extends Node3D
## The ring of wind that seals a Trial's courtyard during its fight: a circle of pale, turning wind streaks with
## walls nobody can pass (like the boss arena's fire ring, in the Trial's colours). Up or down with set_up().

const WORLD_LAYER := 1 << 0
const SEGMENTS := 30
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.6
const STREAK_HEIGHT := 2.2   ## m: low enough for the high camera to see over the near side
const WIND := Color(0.75, 1.0, 0.88)
const SPIN := 1.6            ## rad/s the streaks turn

@export var radius := 9.0

var is_up := false
var _shapes: Array[CollisionShape3D] = []
var _streaks: Node3D
var _material: StandardMaterial3D


func _ready() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	add_child(body)
	var segment := TAU * radius / SEGMENTS
	for i in SEGMENTS:
		var a := TAU * i / SEGMENTS
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(segment + 0.2, WALL_HEIGHT, WALL_THICKNESS)
		shape.shape = box
		shape.position = Vector3(cos(a), 0, sin(a)) * radius + Vector3(0, WALL_HEIGHT * 0.5, 0)
		shape.rotation.y = -a + PI * 0.5
		shape.disabled = true
		body.add_child(shape)
		_shapes.append(shape)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(WIND, 0.0)
	_material.emission_enabled = true
	_material.emission = WIND
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_streaks = Node3D.new()
	add_child(_streaks)
	for i in SEGMENTS:
		var a := TAU * i / SEGMENTS
		var streak := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(segment * 0.8, 0.12)
		streak.mesh = quad
		streak.material_override = _material
		streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		streak.position = Vector3(cos(a), 0, sin(a)) * radius + Vector3(0, 0.3 + fmod(i * 0.73, 1.0) * STREAK_HEIGHT, 0)
		streak.rotation.y = -a + PI * 0.5
		streak.rotation.z = 0.15
		_streaks.add_child(streak)
	visible = false


func _process(delta: float) -> void:
	if visible:
		_streaks.rotation.y += SPIN * delta


func set_up(up: bool) -> void:
	is_up = up
	for shape in _shapes:
		shape.set_deferred(&"disabled", not up)
	visible = true
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color:a", 0.6 if up else 0.0, 0.5)
	if not up:
		tween.tween_callback(hide)
