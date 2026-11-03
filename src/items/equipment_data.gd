class_name EquipmentData
extends ItemData
## Gear for one of Aurelia's 5 slots (FR-ITM-02, GAME_DESIGN.md §9.1): 1 staff, 1 cloak, 3 accessories.
## Bonuses are added up by GearBonus and applied straight away when equipped.

enum Slot { STAFF, CLOAK, ACCESSORY }

@export var slot := Slot.ACCESSORY

@export_group("Bonuses")
@export var magic_power := 0
@export var max_health := 0.0
@export var max_stamina := 0.0
@export var defense := 0.0
@export var stamina_regen := 0.0          ## per second
@export var strike_damage := 0.0
@export_range(0.0, 0.5) var move_speed := 0.0      ## +fraction of walk/run speed
@export_range(0.0, 0.5) var spell_cooldown := 0.0  ## −fraction of every spell's cooldown
@export var resist_element := Elements.Type.NONE
@export_range(0.0, 0.9) var resist := 0.0          ## −fraction of damage taken from resist_element


func _init() -> void:
	category = Category.EQUIPMENT


func effect_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if magic_power != 0:
		lines.append("+%d Magic Power" % magic_power)
	if max_health != 0.0:
		lines.append("+%d max HP" % roundi(max_health))
	if max_stamina != 0.0:
		lines.append("+%d max stamina" % roundi(max_stamina))
	if defense != 0.0:
		lines.append("+%d defense" % roundi(defense))
	if stamina_regen != 0.0:
		lines.append("+%.1f stamina per second" % stamina_regen)
	if strike_damage != 0.0:
		lines.append("+%d staff strike damage" % roundi(strike_damage))
	if move_speed != 0.0:
		lines.append("+%d%% move speed" % roundi(move_speed * 100.0))
	if spell_cooldown != 0.0:
		lines.append("−%d%% spell cooldowns" % roundi(spell_cooldown * 100.0))
	if resist > 0.0 and resist_element != Elements.Type.NONE:
		lines.append("−%d%% %s damage taken" % [roundi(resist * 100.0),
				String(Elements.Type.find_key(resist_element)).capitalize()])
	return lines
