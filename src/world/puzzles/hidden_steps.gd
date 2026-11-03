class_name HiddenSteps
extends Node3D
## Old spirit steps up to a ledge (FR-PUZ-02): a faint shimmer until Lantern Glow reveals them, then solid
## stone you can climb. Built along -Z (the top step is furthest). Stays revealed (GameState by persist_id).
## Like all stairs: visible steps plus one sloped collision box. Can be a Puzzle part (on once revealed).

signal state_changed

const STONE := Color(0.66, 0.64, 0.6)
const SPIRIT := Color(0.55, 0.8, 1.0)
const HINT_ALPHA := 0.12

@export var persist_id: StringName
@export var height := 1.4       ## m, the ledge it climbs
@export var steps := 4
@export var step_depth := 0.6   ## m
@export var width := 1.8        ## m

var hidden := true
var _ramp: CollisionShape3D
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1  # world
	add_child(body)
	var run := steps * step_depth
	_ramp = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.1, Vector2(run, height).length())
	_ramp.shape = box
	_ramp.position = Vector3(0, height * 0.5, -run * 0.5)
	_ramp.rotation.x = atan2(height, run)
	_ramp.disabled = true
	body.add_child(_ramp)
	for i in steps:
		var rise := height * (i + 1) / steps
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width, rise, step_depth)
		var material := StandardMaterial3D.new()
		material.albedo_color = STONE
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = SPIRIT
		_materials.append(material)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = material
		mi.position = Vector3(0, rise * 0.5, -(i + 0.5) * step_depth)
		add_child(mi)
	if GameState.get_object_state(persist_id).get("revealed", false):
		_show(1.0)
		hidden = false
		_ramp.disabled = false
	else:
		add_to_group(&"revealable")
		_show(0.0)


func is_on() -> bool:
	return not hidden


## Called by light spells (Lantern Glow).
func reveal() -> void:
	if not hidden:
		return
	hidden = false
	remove_from_group(&"revealable")
	_ramp.set_deferred(&"disabled", false)
	GameState.set_object_state(persist_id, {"revealed": true})
	create_tween().tween_method(_show, 0.0, 1.0, 0.8)
	state_changed.emit()


## 0 = a faint spirit shimmer, 1 = solid stone.
func _show(amount: float) -> void:
	for material in _materials:
		material.albedo_color.a = lerpf(HINT_ALPHA, 1.0, amount)
		material.emission_energy_multiplier = lerpf(1.2, 0.0, amount)
