class_name RecipeData
extends Resource
## A crafting recipe (FR-ITM-04, GAME_DESIGN.md §9.3): materials in, one item out, at a station.
## The crafting kit at rest points makes potions; the workbench makes everything. Files: data/recipes/*.tres.

enum Station { KIT, WORKBENCH }

const STATION_NAMES: Array[String] = ["Crafting kit", "Workbench"]

@export var id: StringName
@export var output: ItemData
@export var output_count := 1
@export var inputs: Array[ItemData] = []
@export var input_counts: PackedInt32Array = []   ## how many of each input, same order as `inputs`
@export var station := Station.WORKBENCH


func display_name() -> String:
	return output.display_name if output else String(id)


## The workbench can make every recipe; a crafting kit only kit recipes.
func can_make_at(at: Station) -> bool:
	return at == Station.WORKBENCH or station == Station.KIT


func needed(index: int) -> int:
	return input_counts[index] if index < input_counts.size() else 1
