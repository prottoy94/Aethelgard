class_name ConsumableData
extends ItemData
## An item used up from the inventory (FR-ITM-07): healing potions, stamina tonics, dragon treats, later oils.
## Dragon food (dragon_bond or dragon_heal above 0) is fed to the pet dragon instead (DragonManager.feed).

@export var heal := 0.0       ## HP restored
@export var stamina := 0.0    ## stamina restored (also ends Exhausted once past the recovery threshold)

@export_group("Dragon food")
@export var dragon_bond := 0      ## bond XP when fed to the dragon (FR-DRG-05)
@export var dragon_heal := 0.0    ## the dragon's HP restored


func _init() -> void:
	category = Category.CONSUMABLE


func effect_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if heal > 0.0:
		lines.append("Restores %d HP" % roundi(heal))
	if stamina > 0.0:
		lines.append("Restores %d stamina" % roundi(stamina))
	if dragon_bond > 0:
		lines.append("Your dragon: +%d bond" % dragon_bond)
	if dragon_heal > 0.0:
		lines.append("Your dragon: restores %d HP" % roundi(dragon_heal))
	return lines
