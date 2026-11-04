class_name RecipeScroll
extends Node3D
## A crafting recipe lying in the world (FR-ITM-05). Take it (E) to learn the recipe. Remembers being taken
## through GameState (persist_id).

const HOVER := 0.8
const BOB_HEIGHT := 0.06
const SPIN_SPEED := 0.7
const PAPER := Color("f1ead2")

@export var recipe: RecipeData
@export var persist_id: StringName

var _scroll: Node3D
var _time := 0.0


func _ready() -> void:
	if GameState.get_object_state(persist_id).get("taken", false) or Inventory.knows_recipe(recipe.id):
		queue_free()
		return
	_build_scroll()
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = "Take recipe: %s" % recipe.display_name()
	interactable.prompt_height = 1.6
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	shape.shape = sphere
	shape.position = Vector3(0, HOVER, 0)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(_on_taken)


func _process(delta: float) -> void:
	_time += delta
	if _scroll:
		_scroll.position.y = HOVER + sin(_time * 2.0) * BOB_HEIGHT
		_scroll.rotation.y += SPIN_SPEED * delta


func _on_taken(_by: Node) -> void:
	Inventory.learn_recipe(recipe)
	AudioManager.play(&"ui_quest_update")
	GameState.set_object_state(persist_id, {"taken": true})
	var tween := create_tween()
	tween.tween_property(_scroll, "scale", Vector3.ONE * 1.5, 0.15)
	tween.tween_property(_scroll, "scale", Vector3.ZERO, 0.2)
	tween.tween_callback(queue_free)


func _build_scroll() -> void:
	_scroll = Node3D.new()
	add_child(_scroll)
	var roll := CylinderMesh.new()
	roll.top_radius = 0.07
	roll.bottom_radius = 0.07
	roll.height = 0.42
	var paper := MeshInstance3D.new()
	paper.mesh = roll
	paper.material_override = ToonMaterials.toon(PAPER, 0.4)
	paper.rotation.z = PI * 0.5
	_scroll.add_child(paper)
	var ribbon_mesh := CylinderMesh.new()
	ribbon_mesh.top_radius = 0.075
	ribbon_mesh.bottom_radius = 0.075
	ribbon_mesh.height = 0.06
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = ribbon_mesh
	ribbon.material_override = ToonMaterials.glow(recipe.output.color, 1.5)
	ribbon.rotation.z = PI * 0.5
	_scroll.add_child(ribbon)
	var light := OmniLight3D.new()
	light.light_color = recipe.output.color
	light.light_energy = 0.7
	light.omni_range = 2.2
	_scroll.add_child(light)
