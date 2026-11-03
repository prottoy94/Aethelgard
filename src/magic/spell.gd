class_name Spell
extends Node3D
## Base class for spell behaviours. SpellCaster instantiates `SpellData.scene`, adds it to the world,
## and calls cast(). The spell then runs on its own and frees itself when done.

var data: SpellData
var caster: Node3D


func cast(caster_: Node3D, aim: Vector3, data_: SpellData) -> void:
	caster = caster_
	data = data_
	_on_cast(aim)


## Override: aim is a horizontal unit direction.
func _on_cast(_aim: Vector3) -> void:
	pass
