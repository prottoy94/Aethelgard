class_name ElementalReceiver
extends Node3D
## Lets a puzzle object react to spells (FR-PUZ-01). Spells look for receivers (group "elemental") within reach
## and call on_element_hit(); the owner listens to `element_hit` and decides what each element does.
## Puzzle code never checks for particular spells, only elements.

signal element_hit(element: Elements.Type, from: Vector3)

@export var radius := 0.6  ## m: how close a spell must come


func _ready() -> void:
	add_to_group(&"elemental")


## Called by spells. `from` is where the magic came from (the caster), used e.g. to push blocks away from it.
func on_element_hit(element: Elements.Type, from := Vector3.INF) -> void:
	element_hit.emit(element, from)


## Receivers within `reach` (+ their own radius) of `point`.
static func near(tree: SceneTree, point: Vector3, reach: float) -> Array[ElementalReceiver]:
	var result: Array[ElementalReceiver] = []
	for node in tree.get_nodes_in_group(&"elemental"):
		var receiver := node as ElementalReceiver
		if receiver and receiver.global_position.distance_to(point) <= reach + receiver.radius:
			result.append(receiver)
	return result
