class_name SpellLibrary
extends Resource
## Every spell in the game, so saves and tomes can refer to spells by id. File: data/spells/spell_library.tres.

@export var spells: Array[SpellData] = []


func find(id: StringName) -> SpellData:
	for spell in spells:
		if spell.id == id:
			return spell
	return null
