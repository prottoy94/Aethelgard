class_name CraftingStation
extends StaticBody3D
## Where Aurelia crafts (FR-ITM-04, GAME_DESIGN.md §9.3): the workbench makes everything; the crafting kit beside
## each Lantern Shrine makes potions. Press E to use it; the level connects `used` to the crafting menu.

signal used(player: Player, station: RecipeData.Station)

const WOOD := Color(0.55, 0.38, 0.24)
const DARK_WOOD := Color(0.38, 0.26, 0.17)
const LEATHER := Color(0.48, 0.3, 0.22)
const METAL := Color(0.6, 0.6, 0.65)

@export var station := RecipeData.Station.WORKBENCH


func _ready() -> void:
	add_to_group(&"crafting_station")
	collision_layer = 1  # world
	var workbench := station == RecipeData.Station.WORKBENCH
	var size := Vector3(1.6, 0.9, 0.8) if workbench else Vector3(0.6, 0.35, 0.45)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0, size.y * 0.5, 0)
	add_child(shape)
	if workbench:
		_build_workbench()
	else:
		_build_kit()
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = "Use the %s" % RecipeData.STATION_NAMES[station].to_lower()
	interactable.prompt_height = size.y + 1.0
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(size.x, size.z) * 0.5 + 0.5
	reach.shape = sphere
	reach.position = Vector3(0, 0.5, 0)
	interactable.add_child(reach)
	add_child(interactable)
	interactable.interacted.connect(func(by: Node) -> void:
		if by is Player:
			used.emit(by, station))


func _build_workbench() -> void:
	var wood := ToonMaterials.toon(WOOD, 0.25, 0.015)
	var dark := ToonMaterials.toon(DARK_WOOD, 0.2, 0.015)
	_box(Vector3(1.6, 0.1, 0.8), wood, Vector3(0, 0.85, 0))
	for x in [-0.7, 0.7]:
		for z in [-0.32, 0.32]:
			_box(Vector3(0.1, 0.8, 0.1), dark, Vector3(x, 0.4, z))
	_box(Vector3(1.4, 0.06, 0.06), dark, Vector3(0, 0.25, 0.32))  # foot rail
	_box(Vector3(0.3, 0.12, 0.2), ToonMaterials.toon(METAL, 0.4, 0.015), Vector3(-0.5, 0.96, 0.1))  # vice
	_box(Vector3(0.35, 0.03, 0.25), ToonMaterials.toon(Color("f1ead2"), 0.3), Vector3(0.25, 0.915, -0.1))  # plans
	var jar := CylinderMesh.new()
	jar.top_radius = 0.07
	jar.bottom_radius = 0.08
	jar.height = 0.18
	_add(jar, ToonMaterials.glow(Color("a8f0e8"), 1.2), Vector3(0.6, 0.99, -0.2))


func _build_kit() -> void:
	_box(Vector3(0.5, 0.28, 0.34), ToonMaterials.toon(LEATHER, 0.3, 0.015), Vector3(0, 0.14, 0))
	_box(Vector3(0.52, 0.06, 0.36), ToonMaterials.toon(LEATHER.darkened(0.25), 0.3), Vector3(0, 0.3, 0))  # flap
	var mortar := CylinderMesh.new()
	mortar.top_radius = 0.1
	mortar.bottom_radius = 0.07
	mortar.height = 0.12
	_add(mortar, ToonMaterials.toon(Color(0.7, 0.68, 0.64), 0.2, 0.015), Vector3(0.38, 0.06, 0.05))
	for i in 2:
		var bottle := CylinderMesh.new()
		bottle.top_radius = 0.025
		bottle.bottom_radius = 0.045
		bottle.height = 0.16
		var color := Color("ff8fa3") if i == 0 else Color("6fd3e8")
		_add(bottle, ToonMaterials.glow(color, 1.2), Vector3(-0.35, 0.08, -0.06 + i * 0.12))


func _box(size: Vector3, material: Material, pos: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add(mesh, material, pos)


func _add(mesh: Mesh, material: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	add_child(mi)
