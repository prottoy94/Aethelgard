class_name Waypoint
extends RefCounted
## Places "show the way" and the map can point at (owner request 2026-11-04). Objects mark themselves with an id:
## NPCs by npc_id, gather spots and placed items by item id, Lantern Shrines as "lantern_shrine". The special id
## "enemy" means the nearest enemy that is still standing. Quest steps name a waypoint (QuestStep.waypoint).

const GROUP: StringName = &"waypoint"
const META: StringName = &"waypoint_id"
const SHRINE: StringName = &"lantern_shrine"
const ENEMY: StringName = &"enemy"


static func mark(node: Node3D, id: StringName) -> void:
	if id == &"":
		return
	node.add_to_group(GROUP)
	node.set_meta(META, id)


## The nearest node marked `id` to `from` in the current scene, or null. Gather spots that are picked don't count.
static func find(tree: SceneTree, id: StringName, from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	var candidates: Array[Node] = tree.get_nodes_in_group(&"enemy") if id == ENEMY else tree.get_nodes_in_group(GROUP)
	for node in candidates:
		var spot := node as Node3D
		if spot == null or not is_instance_valid(spot) or spot.is_queued_for_deletion():
			continue
		if id == ENEMY:
			if not Enemy.is_alive(spot):
				continue
		elif spot.get_meta(META, &"") != id or (spot.has_method(&"can_gather") and not spot.call(&"can_gather")):
			continue
		var distance := spot.global_position.distance_to(from)
		if distance < best_distance:
			best = spot
			best_distance = distance
	return best
