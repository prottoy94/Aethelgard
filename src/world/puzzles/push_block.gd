class_name PushBlock
extends AnimatableBody3D
## A heavy stone block (FR-PUZ-01) that Wind magic (Gust) pushes one cell straight away from the caster,
## along the nearest grid axis, if nothing is in the way. Its position is remembered through GameState.

signal moved

const STONE := Color(0.6, 0.58, 0.54)
const SIZE := 1.6  ## m, a cube

@export var persist_id: StringName
@export var cell := 2.0           ## m per push
@export var slide_time := 0.4     ## s
@export var pushed_by: Array[Elements.Type] = [Elements.Type.WIND]

var is_sliding := false


func _ready() -> void:
	collision_layer = 1  # world: blocks Aurelia and enemies
	sync_to_physics = true
	set_meta(&"surface", "stone")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * SIZE
	shape.shape = box
	shape.position = Vector3(0, SIZE * 0.5, 0)
	add_child(shape)
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * SIZE
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterials.toon(STONE, 0.2, 0.02)
	mi.position = Vector3(0, SIZE * 0.5, 0)
	add_child(mi)
	var rune := BoxMesh.new()  # a wind rune on top, so players guess what moves it
	rune.size = Vector3(0.5, 0.02, 0.5)
	var rune_mi := MeshInstance3D.new()
	rune_mi.mesh = rune
	rune_mi.material_override = ToonMaterials.glow(Elements.color(Elements.Type.WIND), 1.2)
	rune_mi.position = Vector3(0, SIZE + 0.01, 0)
	add_child(rune_mi)
	var receiver := ElementalReceiver.new()
	receiver.position = Vector3(0, SIZE * 0.5, 0)
	receiver.radius = SIZE * 0.6
	add_child(receiver)
	receiver.element_hit.connect(_on_element_hit)
	var saved := GameState.get_object_state(persist_id)
	if saved.has("x"):
		position = Vector3(float(saved["x"]), position.y, float(saved["z"]))


## Pushes one cell along `direction` (snapped to the x or z axis). Returns false if blocked or already sliding.
func push(direction: Vector3) -> bool:
	if is_sliding:
		return false
	var step := axis_of(direction) * cell
	if step == Vector3.ZERO or not _is_free(global_position + step):
		return false
	is_sliding = true
	AudioManager.play(&"puzzle_block_push", global_position)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", global_position + step, slide_time).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		is_sliding = false
		GameState.set_object_state(persist_id, {"x": position.x, "z": position.z})
		moved.emit())
	return true


func _on_element_hit(element: Elements.Type, from: Vector3) -> void:
	if element in pushed_by and from != Vector3.INF:
		push(global_position - from)


## The nearest horizontal axis direction (±x or ±z) of `direction`.
static func axis_of(direction: Vector3) -> Vector3:
	if Vector2(direction.x, direction.z).length() < 0.001:
		return Vector3.ZERO
	if absf(direction.x) >= absf(direction.z):
		return Vector3(signf(direction.x), 0, 0)
	return Vector3(0, 0, signf(direction.z))


func _is_free(target: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE - 0.2, SIZE - 0.3, SIZE - 0.2)
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY, target + Vector3(0, SIZE * 0.5 + 0.1, 0))
	query.collision_mask = 1 | 2 | 4  # world, player, enemies
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
