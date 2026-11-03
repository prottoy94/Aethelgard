class_name GatherNodeData
extends Resource
## One kind of gather node (FR-ITM-03): what it gives and how fast it grows back. Files: data/items/gather/*.tres.

enum Look { FLOWER, ORE, WOOD, CRYSTAL }

@export var display_name: String
@export var item: ItemData
@export var look := Look.FLOWER
@export var min_amount := 1
@export var max_amount := 2
## s until it can be gathered again. Becomes in-game hours once the TimeOfDay clock exists (Phase 6).
@export var regrow_time := 60.0
