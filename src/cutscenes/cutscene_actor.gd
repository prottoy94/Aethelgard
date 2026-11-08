class_name CutsceneActor
extends Node3D
## Something a cutscene can move about by id (DIALOGUE_DESIGN.md §5.2): `do Cutscene.move("sylvaris", "marker_square",
## 2.0)`. Most actors are ordinary game nodes tagged with an id (Aurelia is "aurelia", NPCs use their npc_id, Ignis
## is tagged by his encounter); this class is for figures that only appear in scenes (Sylvaris). Subclasses build a
## visual and answer play_anim(name) and set_walking(speed). Hidden until spawned unless `starts_visible`.

const GROUP: StringName = &"cutscene_actor"
const META: StringName = &"actor_id"

@export var actor_id: StringName
@export var starts_visible := false
@export var emote_height := 2.2   ## m above its feet where emote bubbles appear


## Marks any node as cutscene actor `id` (like Waypoint.mark).
static func tag(node: Node3D, id: StringName) -> void:
	if id == &"":
		return
	node.add_to_group(GROUP)
	node.set_meta(META, id)


## The actor tagged `id` in the current scene, or null.
static func find(tree: SceneTree, id: StringName) -> Node3D:
	for node in tree.get_nodes_in_group(GROUP):
		if node.get_meta(META, &"") == id and is_instance_valid(node) and not node.is_queued_for_deletion():
			return node as Node3D
	return null


func _ready() -> void:
	tag(self, actor_id)
	visible = starts_visible


## Plays a named animation (override): "roar", "land", "breath"...; returns how long it takes.
func play_anim(_anim_name: StringName) -> float:
	return 0.0


## Walking speed in m/s while a cutscene moves it (0 = standing). Override to animate legs or wings.
func set_walking(_speed: float) -> void:
	pass
