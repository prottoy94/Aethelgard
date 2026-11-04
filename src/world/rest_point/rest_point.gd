class_name RestPoint
extends StaticBody3D
## A Lantern Shrine (FR-WLD-05): rest here (E) to restore health and stamina, clear status effects, set the
## respawn point, and read carried spell tomes (FR-MAG-08). A crafting kit beside it makes potions (GAME_DESIGN.md §9.3).
## Saving and fast travel are added in Phase 6. Placeholder look: a stone base and post with a glowing lantern.

signal rested(player: Player, result: Dictionary)

const STONE := Color(0.66, 0.64, 0.6)
const LAMP := Color(1.0, 0.75, 0.4)
const SPAWN_OFFSET := Vector3(0, 0, 1.6)  ## where Aurelia respawns, in front of the shrine
const KIT_OFFSET := Vector3(-1.5, 0, 0.3)

@export var display_name := "Lantern Shrine"

var kit: CraftingStation


func _ready() -> void:
	add_to_group(&"rest_point")
	Waypoint.mark(self, Waypoint.SHRINE)
	collision_layer = 1  # world
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.5
	cylinder.height = 1.2
	shape.shape = cylinder
	shape.position = Vector3(0, 0.6, 0)
	add_child(shape)
	_build_visual()
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = "Rest at the %s" % display_name
	interactable.prompt_height = 2.3
	var range_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	range_shape.shape = sphere
	range_shape.position = Vector3(0, 0.8, 0)
	interactable.add_child(range_shape)
	add_child(interactable)
	interactable.interacted.connect(_on_interacted)
	kit = CraftingStation.new()
	kit.station = RecipeData.Station.KIT
	kit.position = KIT_OFFSET
	kit.rotation.y = 0.4
	add_child(kit)


func respawn_position() -> Vector3:
	return global_transform * SPAWN_OFFSET


func _on_interacted(by: Node) -> void:
	var player := by as Player
	if player == null:
		return
	var result := player.rest(respawn_position())
	AudioManager.play(&"world_rest_point_activate")
	rested.emit(player, result)


func _build_visual() -> void:
	var base := CylinderMesh.new()
	base.top_radius = 0.45
	base.bottom_radius = 0.6
	base.height = 0.6
	_add(base, ToonMaterials.toon(STONE, 0.2, 0.015), Vector3(0, 0.3, 0))
	var post := BoxMesh.new()
	post.size = Vector3(0.18, 1.0, 0.18)
	_add(post, ToonMaterials.toon(STONE, 0.2, 0.015), Vector3(0, 1.1, 0))
	var lamp := BoxMesh.new()
	lamp.size = Vector3(0.26, 0.3, 0.26)
	_add(lamp, ToonMaterials.glow(LAMP, 3.0), Vector3(0, 1.75, 0))
	var light := OmniLight3D.new()
	light.light_color = LAMP
	light.light_energy = 1.2
	light.omni_range = 5.0
	light.position = Vector3(0, 1.75, 0)
	add_child(light)


func _add(mesh: Mesh, material: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	add_child(mi)
