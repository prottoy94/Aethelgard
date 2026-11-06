class_name LoreStone
extends StaticBody3D
## Something to read (owner request 2026-11-05): an old carved stone, a sign or a notice board. E opens its text in
## the dialogue box (a cue of dialogue/world/elderroot_lore.dialogue); RegionRuntime links the request to the box.

signal read_requested(resource: DialogueResource, cue: String)

enum Look { STONE, BOARD }

const LORE: DialogueResource = preload("res://dialogue/world/elderroot_lore.dialogue")
const STONE := Color(0.55, 0.56, 0.52)
const RUNE := Color(0.55, 0.85, 1.0)

@export var cue := ""
@export var look := Look.STONE
@export var verb := "Read"


func _ready() -> void:
	add_to_group(&"lore")
	collision_layer = PropKit.WORLD_LAYER
	set_meta(&"surface", "stone")
	if look == Look.STONE:
		PropKit.add_box_shape(self, Vector3(0.9, 1.5, 0.4), Vector3(0, 0.75, 0))
		var slab := PropKit.mesh(self, PropKit.box_mesh(Vector3(0.9, 1.5, 0.35)), STONE, Vector3(0, 0.75, 0), 0.015, 0.2)
		slab.rotation.z = 0.04
		var rune := MeshInstance3D.new()
		rune.mesh = PropKit.box_mesh(Vector3(0.5, 0.7, 0.02))
		rune.material_override = ToonMaterials.glow(RUNE, 1.2)
		rune.position = Vector3(0, 0.85, 0.18)
		add_child(rune)
	else:
		PropKit.add_box_shape(self, Vector3(1.6, 2.0, 0.3), Vector3(0, 1.0, 0))
		for side: float in [-0.7, 0.7]:
			PropKit.mesh(self, PropKit.box_mesh(Vector3(0.12, 2.0, 0.12)), PropKit.WOOD.darkened(0.2), Vector3(side, 1.0, 0), 0.01)
		PropKit.mesh(self, PropKit.box_mesh(Vector3(1.5, 1.0, 0.08)), PropKit.WOOD, Vector3(0, 1.4, 0), 0.015)
		for i in 3:
			PropKit.mesh(self, PropKit.box_mesh(Vector3(0.35, 0.45, 0.02)), Color(0.95, 0.92, 0.82),
					Vector3(-0.45 + i * 0.45, 1.42 + 0.06 * (i % 2), 0.05), 0.0)
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = verb
	interactable.prompt_height = 2.0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	shape.position = Vector3(0, 0.8, 0.6)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_by: Node) -> void: read_requested.emit(LORE, cue))
