extends SceneTree
## Dev tool: (re)builds data/spells/spell_library.tres from every SpellData in data/spells/, and sets Aurelia's
## starting spells (GAME_DESIGN.md §6.4: Light Mote + Lantern Glow). Run after adding a spell:
##   godot --headless --path . --script res://tools/dev/build_spell_library.gd

const STARTING := [&"light_mote", &"lantern_glow"]


func _init() -> void:
	var library := SpellLibrary.new()
	for file in DirAccess.get_files_at("res://data/spells"):
		if file.ends_with(".tres") and file != "spell_library.tres":
			var spell := load("res://data/spells/" + file) as SpellData
			if spell:
				library.spells.append(spell)
	print("spells: ", library.spells.map(func(s: SpellData) -> StringName: return s.id))
	print("library save: ", error_string(ResourceSaver.save(library, "res://data/spells/spell_library.tres")))
	var combat: PlayerCombatStats = load("res://data/player/aurelia_combat.tres")
	var starting: Array[SpellData] = []
	for id in STARTING:
		starting.append(library.find(id))
	combat.starting_spells = starting
	print("combat save: ", error_string(ResourceSaver.save(combat)))
	quit()
