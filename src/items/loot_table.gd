class_name LootTable
extends Resource
## What an enemy can drop (TECHNICAL_DESIGN.md §4.4). Each entry rolls on its own:
## `chances[i]` (0–1) to drop between `min_counts[i]` and `max_counts[i]` of `items[i]`. Files: data/loot_tables/*.tres.

@export var items: Array[ItemData] = []
@export var chances: PackedFloat32Array = []
@export var min_counts: PackedInt32Array = []
@export var max_counts: PackedInt32Array = []


## Returns item → amount for one defeat.
func roll(rng: RandomNumberGenerator) -> Dictionary[ItemData, int]:
	var drops: Dictionary[ItemData, int] = {}
	for i in items.size():
		if rng.randf() >= chances[i]:
			continue
		var amount := rng.randi_range(min_counts[i], max_counts[i])
		if amount > 0:
			drops[items[i]] = drops.get(items[i], 0) + amount
	return drops
