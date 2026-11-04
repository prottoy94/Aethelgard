class_name GatherNode
extends Node3D
## Something to gather (FR-ITM-03): a flower patch, ore vein, fallen branch or crystal cluster. Press E to collect
## a few of its item; it then shrinks and grows back after `data.regrow_hours` of game time (TimeOfDay). With a
## persist_id, GameState remembers when it grows back, so it survives region changes and saves (FR-WLD-09).
## Placeholder looks are simple shapes.

signal gathered(item: ItemData, amount: int)

const PICKED_SCALE := 0.3
const STONE := Color(0.55, 0.53, 0.5)
const STEM := Color(0.35, 0.55, 0.25)
const BARK := Color(0.45, 0.31, 0.2)
const GATHER_SOUNDS: Array[StringName] = [&"world_gather_herb", &"world_gather_ore", &"world_gather_wood",
		&"world_gather_crystal"]  ## by GatherNodeData.Look

@export var data: GatherNodeData
@export var persist_id: StringName

var _interactable: InteractableComponent
var _visual: Node3D
var _regrow_at := -1.0  ## TimeOfDay total minutes when it can be gathered again (-1 = ready)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Waypoint.mark(self, data.item.id)  # "show the way" skips it while it is picked (can_gather)
	_rng.randomize()
	_visual = Node3D.new()
	add_child(_visual)
	match data.look:
		GatherNodeData.Look.FLOWER: _build_flowers()
		GatherNodeData.Look.ORE: _build_ore()
		GatherNodeData.Look.WOOD: _build_wood()
		GatherNodeData.Look.CRYSTAL: _build_crystals()
	_interactable = InteractableComponent.new()
	_interactable.prompt_verb = "Gather %s" % data.display_name
	_interactable.prompt_height = 1.3
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	shape.shape = sphere
	shape.position = Vector3(0, 0.4, 0)
	_interactable.add_child(shape)
	add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)
	_regrow_at = float(GameState.get_object_state(persist_id).get("regrow_at", -1.0))
	if not can_gather():
		_visual.scale = Vector3.ONE * PICKED_SCALE
		_interactable.monitorable = false


func _process(_delta: float) -> void:
	if _regrow_at >= 0.0 and TimeOfDay.total_minutes() >= _regrow_at:
		_regrow_at = -1.0
		_remember()
		_interactable.monitorable = true
		create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.6)


func can_gather() -> bool:
	return _regrow_at < 0.0 or TimeOfDay.total_minutes() >= _regrow_at


## Collects the node's items. Returns how many were added (0 if it is still growing back or the bag is full).
func gather(by: Node = null) -> int:
	if not can_gather():
		return 0
	var added := Inventory.add(data.item, _rng.randi_range(data.min_amount, data.max_amount))
	if added <= 0:
		return 0
	EventBus.item_collected.emit(data.item.id, added)
	gathered.emit(data.item, added)
	AudioManager.play(GATHER_SOUNDS[data.look], global_position)
	if by is Player:
		(by as Player).play_role(&"interact")
	_regrow_at = TimeOfDay.total_minutes() + data.regrow_hours * 60.0
	_remember()
	_interactable.set_deferred(&"monitorable", false)
	create_tween().tween_property(_visual, "scale", Vector3.ONE * PICKED_SCALE, 0.25)
	return added


func _on_interacted(by: Node) -> void:
	gather(by)


func _remember() -> void:
	if persist_id != &"":
		GameState.set_object_state(persist_id, {"regrow_at": _regrow_at} if _regrow_at >= 0.0 else {})


# --- Placeholder looks ---------------------------------------------------------------------

func _build_flowers() -> void:
	var leaves := SphereMesh.new()
	leaves.radius = 0.32
	leaves.height = 0.18
	_add(leaves, ToonMaterials.toon(STEM, 0.3), Vector3(0, 0.06, 0))
	var bloom := ToonMaterials.toon(data.item.color, 0.5)
	for i in 6:
		var angle := TAU * i / 6.0 + _rng.randf() * 0.5
		var offset := Vector3(cos(angle), 0, sin(angle)) * _rng.randf_range(0.08, 0.3)
		var height := _rng.randf_range(0.3, 0.5)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.015
		stem.bottom_radius = 0.02
		stem.height = height
		_add(stem, ToonMaterials.toon(STEM, 0.2), offset + Vector3(0, height * 0.5, 0))
		var head := SphereMesh.new()
		head.radius = 0.08
		head.height = 0.11
		_add(head, bloom, offset + Vector3(0, height, 0))


func _build_ore() -> void:
	var rock := SphereMesh.new()
	rock.radius = 0.55
	rock.height = 0.7
	rock.radial_segments = 7
	rock.rings = 4
	_add(rock, ToonMaterials.toon(STONE, 0.2, 0.015), Vector3(0, 0.2, 0))
	for i in 4:
		var nugget := BoxMesh.new()
		nugget.size = Vector3.ONE * _rng.randf_range(0.1, 0.16)
		var angle := TAU * i / 4.0
		var spot := Vector3(cos(angle) * 0.42, _rng.randf_range(0.25, 0.45), sin(angle) * 0.42)
		var piece := _add(nugget, ToonMaterials.glow(data.item.color, 0.6), spot)
		piece.rotation = Vector3(0.6, angle, 0.3)


func _build_wood() -> void:
	var bark := ToonMaterials.toon(BARK, 0.2, 0.015)
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = 0.13
	log_mesh.bottom_radius = 0.16
	log_mesh.height = 1.3
	var trunk := _add(log_mesh, bark, Vector3(0, 0.15, 0))
	trunk.rotation = Vector3(0, 0.4, PI * 0.5)
	var twig := CylinderMesh.new()
	twig.top_radius = 0.03
	twig.bottom_radius = 0.06
	twig.height = 0.6
	var branch := _add(twig, bark, Vector3(0.2, 0.3, 0.15))
	branch.rotation = Vector3(0.5, 0.0, 0.9)
	var leaf := SphereMesh.new()
	leaf.radius = 0.12
	leaf.height = 0.08
	_add(leaf, ToonMaterials.toon(STEM, 0.3), Vector3(0.42, 0.5, 0.25))


func _build_crystals() -> void:
	var base := SphereMesh.new()
	base.radius = 0.35
	base.height = 0.3
	_add(base, ToonMaterials.toon(STONE, 0.2, 0.015), Vector3(0, 0.05, 0))
	var glow := ToonMaterials.glow(data.item.color, 1.4)
	for i in 3:
		var prism := CylinderMesh.new()
		prism.radial_segments = 6
		prism.top_radius = 0.02
		prism.bottom_radius = 0.1
		prism.height = _rng.randf_range(0.55, 0.9)
		var angle := TAU * i / 3.0
		var spot := Vector3(cos(angle) * 0.12, prism.height * 0.45, sin(angle) * 0.12)
		var shard := _add(prism, glow, spot)
		shard.rotation = Vector3(sin(angle) * 0.35, 0.0, -cos(angle) * 0.35)
	var light := OmniLight3D.new()
	light.light_color = data.item.color
	light.light_energy = 0.6
	light.omni_range = 2.2
	light.position = Vector3(0, 0.5, 0)
	_visual.add_child(light)


func _add(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	_visual.add_child(mi)
	return mi
