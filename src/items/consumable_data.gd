class_name ConsumableData
extends ItemData
## An item used up from the inventory (FR-ITM-07): healing potions, stamina tonics, later oils and treats.

@export var heal := 0.0       ## HP restored
@export var stamina := 0.0    ## stamina restored (also ends Exhausted once past the recovery threshold)


func _init() -> void:
	category = Category.CONSUMABLE


func effect_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if heal > 0.0:
		lines.append("Restores %d HP" % roundi(heal))
	if stamina > 0.0:
		lines.append("Restores %d stamina" % roundi(stamina))
	return lines
