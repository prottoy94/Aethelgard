class_name PuzzleGate
extends StaticBody3D
## Iron-banded wooden bars closing a gap in a wall. A Puzzle target: activate() sinks the bars into the ground.

const WOOD := Color(0.42, 0.3, 0.2)
const IRON := Color(0.35, 0.36, 0.4)
const OPEN_TIME := 1.2

@export var width := 2.2
@export var height := 2.4

var is_open := false
var _bars: Node3D
var _shape: CollisionShape3D


func _ready() -> void:
	collision_layer = 1  # world
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, 0.3)
	_shape.shape = box
	_shape.position = Vector3(0, height * 0.5, 0)
	add_child(_shape)
	_bars = Node3D.new()
	add_child(_bars)
	var wood := ToonMaterials.toon(WOOD, 0.2, 0.015)
	var iron := ToonMaterials.toon(IRON, 0.35, 0.015)
	var count := maxi(roundi(width / 0.45), 2)
	for i in count:
		var bar := BoxMesh.new()
		bar.size = Vector3(0.16, height, 0.16)
		_add(bar, wood, Vector3(-width * 0.5 + (i + 0.5) * width / count, height * 0.5, 0))
	for y: float in [0.5, height - 0.35]:
		var band := BoxMesh.new()
		band.size = Vector3(width, 0.12, 0.22)
		_add(band, iron, Vector3(0, y, 0))


## Opens the gate (Puzzle target). `instant` skips the animation (loading a solved puzzle).
func activate(instant: bool) -> void:
	if is_open:
		return
	is_open = true
	_shape.set_deferred(&"disabled", true)
	if instant:
		_bars.position.y = -height
		_bars.visible = false
		return
	var tween := create_tween()
	tween.tween_property(_bars, "position:y", -height, OPEN_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_bars.hide)


func _add(mesh: Mesh, material: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	_bars.add_child(mi)
