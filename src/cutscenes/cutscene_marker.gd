class_name CutsceneMarker
extends Marker3D
## A named spot for cutscenes (DIALOGUE_DESIGN.md §5.2): where actors spawn or walk to, or where the cutscene camera
## goes (`do Cutscene.camera_to("cam_gate", 1.5)`: the camera takes the marker's place and looks along its -Z).
## Regions add them in code; they are found by id.

const GROUP: StringName = &"cutscene_marker"

@export var marker_id: StringName


## A marker at `at`. With `look_at_point` it faces that point (for camera spots).
static func make(id: StringName, at: Vector3, look_at_point: Variant = null) -> CutsceneMarker:
	var marker := CutsceneMarker.new()
	marker.marker_id = id
	marker.name = String(id)
	marker.position = at
	if look_at_point is Vector3 and (look_at_point as Vector3).distance_to(at) > 0.01:
		marker.basis = Basis.looking_at((look_at_point as Vector3) - at, Vector3.UP)
	return marker


## The marker called `id` in the current scene, or null.
static func find(tree: SceneTree, id: StringName) -> CutsceneMarker:
	for node in tree.get_nodes_in_group(GROUP):
		var marker := node as CutsceneMarker
		if marker and marker.marker_id == id:
			return marker
	return null


func _ready() -> void:
	add_to_group(GROUP)
