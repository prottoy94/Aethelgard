class_name GatherNodeData
extends Resource
## One kind of gather node (FR-ITM-03): what it gives and how fast it grows back. Files: data/items/gather/*.tres.

enum Look { FLOWER, ORE, WOOD, CRYSTAL }

@export var display_name: String
@export var item: ItemData
@export var look := Look.FLOWER
@export var min_amount := 1
@export var max_amount := 2
## Game hours until it can be gathered again (1 game hour ≈ 50 real seconds, data/world/time_settings.tres).
@export var regrow_hours := 1.0
