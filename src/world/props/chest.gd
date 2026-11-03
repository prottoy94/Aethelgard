class_name Chest
extends StaticBody3D
## A chest (FR-WLD-09): press E to open it and take what's inside. A locked chest (e.g. a Puzzle target) opens only
## after activate(). Opened and unlocked states are remembered through GameState (persist_id).

signal opened

const WOOD := Color(0.5, 0.33, 0.2)
const TRIM := Color(0.85, 0.68, 0.3)

@export var persist_id: StringName
@export var contents: Array[ItemData] = []  ## one entry per unit
@export var locked := false

var is_opened := false
var _lid: Node3D
var _interactable: InteractableComponent


func _ready() -> void:
	collision_layer = 1  # world
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.6, 0.6)
	shape.shape = box
	shape.position = Vector3(0, 0.3, 0)
	add_child(shape)
	_build_visual()
	var saved := GameState.get_object_state(persist_id)
	locked = locked and not saved.get("unlocked", false)
	_interactable = InteractableComponent.new()
	_interactable.prompt_verb = "Open the chest"
	_interactable.prompt_height = 1.3
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	reach.shape = sphere
	reach.position = Vector3(0, 0.4, 0.3)
	_interactable.add_child(reach)
	add_child(_interactable)
	_interactable.interacted.connect(func(_by: Node) -> void: open())
	if saved.get("opened", false):
		is_opened = true
		_lid.rotation.x = -1.9
	_interactable.monitorable = not (locked or is_opened)


## Unlocks the chest (Puzzle target).
func activate(_instant: bool) -> void:
	if not locked:
		return
	locked = false
	GameState.set_object_state(persist_id, {"unlocked": true})
	_interactable.set_deferred(&"monitorable", not is_opened)


## Opens it and puts the contents in the bag. Returns false if locked or already open.
func open() -> bool:
	if locked or is_opened:
		return false
	is_opened = true
	GameState.set_object_state(persist_id, {"unlocked": true, "opened": true})
	_interactable.set_deferred(&"monitorable", false)
	create_tween().tween_property(_lid, "rotation:x", -1.9, 0.4).set_trans(Tween.TRANS_BACK)
	for item in contents:
		if Inventory.add(item) > 0:
			EventBus.item_collected.emit(item.id, 1)
	opened.emit()
	return true


func _build_visual() -> void:
	var wood := ToonMaterials.toon(WOOD, 0.25, 0.015)
	var trim := ToonMaterials.toon(TRIM, 0.4, 0.01)
	_box(Vector3(0.9, 0.42, 0.6), wood, Vector3(0, 0.21, 0), self)
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.42, -0.3)  # hinge at the back
	add_child(_lid)
	_box(Vector3(0.92, 0.18, 0.62), wood, Vector3(0, 0.09, 0.3), _lid)
	_box(Vector3(0.94, 0.06, 0.08), trim, Vector3(0, 0.12, 0.6), _lid)
	_box(Vector3(0.14, 0.16, 0.04), trim, Vector3(0, 0.34, 0.31), self)  # lock plate


func _box(size: Vector3, material: Material, pos: Vector3, parent: Node3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
