class_name PressurePlate
extends Node3D
## A stone plate that a PushBlock holds down (FR-PUZ-01). Too heavy for Aurelia alone. A part of a Puzzle.

signal state_changed

const STONE := Color(0.55, 0.53, 0.5)
const RUNE := Color(0.6, 0.95, 0.85)
const SIZE := 1.8

var is_pressed := false
var _plate: MeshInstance3D
var _rune: MeshInstance3D
var _area: Area3D


func _ready() -> void:
	var frame := BoxMesh.new()
	frame.size = Vector3(SIZE + 0.3, 0.06, SIZE + 0.3)
	_add(frame, ToonMaterials.toon(STONE.darkened(0.25), 0.2), Vector3(0, 0.03, 0))
	var plate := BoxMesh.new()
	plate.size = Vector3(SIZE, 0.12, SIZE)
	_plate = _add(plate, ToonMaterials.toon(STONE, 0.2, 0.01), Vector3(0, 0.08, 0))
	var rune := BoxMesh.new()
	rune.size = Vector3(0.6, 0.02, 0.6)
	_rune = _add(rune, ToonMaterials.glow(RUNE, 0.3), Vector3(0, 0.15, 0))
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = 1  # world bodies (push blocks)
	_area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE * 0.6, 0.6, SIZE * 0.6)
	shape.shape = box
	shape.position = Vector3(0, 0.4, 0)
	_area.add_child(shape)
	add_child(_area)
	_area.body_entered.connect(func(_body: Node3D) -> void: _update())
	_area.body_exited.connect(func(_body: Node3D) -> void: _update())


func is_on() -> bool:
	return is_pressed


func _update() -> void:
	var pressed := _area.get_overlapping_bodies().any(func(body: Node3D) -> bool: return body is PushBlock)
	if pressed == is_pressed:
		return
	is_pressed = pressed
	_plate.position.y = 0.03 if pressed else 0.08
	_rune.material_override = ToonMaterials.glow(RUNE, 3.0 if pressed else 0.3)
	state_changed.emit()


func _add(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	add_child(mi)
	return mi
