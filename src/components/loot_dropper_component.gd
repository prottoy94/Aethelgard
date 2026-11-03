class_name LootDropperComponent
extends Node
## Rolls a LootTable when its owner is defeated and scatters ItemPickups around the spot (TECHNICAL_DESIGN.md §4.2).

const SCATTER_MIN := 0.4   ## m from the drop point
const SCATTER_MAX := 1.0

@export var table: LootTable

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


## Drops one defeat's items at `origin` into `container`. Returns the new pickups.
func drop(origin: Vector3, container: Node) -> Array[ItemPickup]:
	var pickups: Array[ItemPickup] = []
	if table == null:
		return pickups
	var drops := table.roll(rng)
	for item in drops:
		var pickup := ItemPickup.new()
		pickup.item = item
		pickup.amount = drops[item]
		container.add_child(pickup)
		var angle := rng.randf() * TAU
		pickup.global_position = origin + Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(SCATTER_MIN, SCATTER_MAX)
		pickup.pop_from(origin)
		pickups.append(pickup)
	return pickups
