class_name GearBonus
extends RefCounted
## The summed bonuses of everything Aurelia has equipped (FR-ITM-02). Built by Inventory.gear_bonus().

const MAX_RESIST := 0.9

var magic_power := 0
var max_health := 0.0
var max_stamina := 0.0
var defense := 0.0
var stamina_regen := 0.0
var strike_damage := 0.0
var move_speed := 0.0       ## +fraction
var spell_cooldown := 0.0   ## −fraction
var resistances: Dictionary[Elements.Type, float] = {}


static func total(items: Array[EquipmentData]) -> GearBonus:
	var sum := GearBonus.new()
	for item in items:
		sum.magic_power += item.magic_power
		sum.max_health += item.max_health
		sum.max_stamina += item.max_stamina
		sum.defense += item.defense
		sum.stamina_regen += item.stamina_regen
		sum.strike_damage += item.strike_damage
		sum.move_speed += item.move_speed
		sum.spell_cooldown += item.spell_cooldown
		if item.resist_element != Elements.Type.NONE and item.resist > 0.0:
			sum.resistances[item.resist_element] = minf(sum.resistances.get(item.resist_element, 0.0) + item.resist, MAX_RESIST)
	return sum
