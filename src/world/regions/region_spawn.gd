class_name RegionSpawn
extends Marker3D
## A named place where Aurelia can appear in a region: "start", arrival points from exits ("from_village"), and
## test spots (`-- --spawn=<id>`). Faces the way the marker's -Z points.

@export var spawn_id: StringName = &"start"


func _ready() -> void:
	add_to_group(&"region_spawn")


## The spawn with `id` in the current scene, or null.
static func find(tree: SceneTree, id: StringName) -> RegionSpawn:
	for node in tree.get_nodes_in_group(&"region_spawn"):
		var spawn := node as RegionSpawn
		if spawn and spawn.spawn_id == id:
			return spawn
	return null
