class_name ItemData
extends Resource
## One kind of item (TECHNICAL_DESIGN.md §4.4). Materials use this class directly; consumables and equipment
## extend it. Files: data/items/*.tres. Saves refer to items by `id`.

enum Category { MATERIAL, CONSUMABLE, EQUIPMENT, KEY }

const CATEGORY_NAMES: Array[String] = ["Materials", "Consumables", "Equipment", "Key items"]

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category := Category.MATERIAL
@export var color := Color.WHITE        ## placeholder icon and pickup colour
@export var max_stack := 99


## Short lines describing what the item does (shown in menus). Subclasses add their effects.
func effect_lines() -> PackedStringArray:
	return PackedStringArray()
