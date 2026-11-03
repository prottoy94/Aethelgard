class_name Spell
extends Node3D
## Base class for spell behaviours. SpellCaster instantiates `SpellData.scene`, adds it to the world,
## and calls cast(). The spell then runs on its own and frees itself when done.

## Emitted each time the spell affects an enemy (used for mastery XP).
signal landed(target: Node)

var data: SpellData
var caster: Node3D
## Damage/heal multiplier from the caster's mastery and Magic Power (1.0 = base).
var power := 1.0


func cast(caster_: Node3D, aim: Vector3, data_: SpellData, power_ := 1.0) -> void:
	caster = caster_
	data = data_
	power = power_
	_on_cast(aim)


## The spell's damage after mastery and Magic Power.
func damage() -> float:
	return data.base_damage * power


## Override: aim is a horizontal unit direction.
func _on_cast(_aim: Vector3) -> void:
	pass
