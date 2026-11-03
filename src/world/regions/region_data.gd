class_name RegionData
extends Resource
## One playable region (or area of a region): its id, name and scene (TECHNICAL_DESIGN.md §4.7).

@export var id: StringName
@export var display_name: String
@export_file("*.tscn") var scene_path: String
