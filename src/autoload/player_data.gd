extends Node
## Aurelia's magical growth, kept across scenes and saved by SaveManager (GAME_DESIGN.md §5.2, §6.3):
## learned spells with mastery, unread spell tomes, the 4-slot loadout, Magic Power and Arcane Rank.
## Magic Power = Σ spell power × mastery bonus + equipment power + dragon bond power; rank follows from it.
## Equipment power and the gear's spell-cooldown bonus follow Inventory's equipped items (Phase 5).

signal spell_learned(spell: SpellData)
signal tome_found(spell: SpellData)
signal mastery_changed(spell_id: StringName, level: int)
signal magic_power_changed(magic_power: int)
signal rank_changed(rank: int, previous: int)
signal loadout_changed

const LIBRARY: SpellLibrary = preload("res://data/spells/spell_library.tres")
const PROGRESSION: MagicProgression = preload("res://data/progression/magic_progression.tres")
const SLOTS := 4

## spell id → {"level": int, "xp": int}
var learned: Dictionary[StringName, Dictionary] = {}
var tomes: Array[StringName] = []
var loadout: Array[StringName] = [&"", &"", &"", &""]
var equipment_power := 0  ## Magic Power from equipped gear
var dragon_power := 0     ## Magic Power from the dragon's bond (DragonManager; not saved here)
var gear_cooldown := 0.0  ## −fraction of every spell cooldown from equipped gear
var magic_power := 0
var rank := 0


func _ready() -> void:
	Inventory.equipment_changed.connect(_on_gear_changed)


## New game: only the starting spells, at mastery I.
func reset(starting_spells: Array[SpellData]) -> void:
	learned.clear()
	tomes.clear()
	loadout = [&"", &"", &"", &""]
	dragon_power = 0
	_read_gear()
	for spell in starting_spells:
		learned[spell.id] = {"level": 1, "xp": 0}
		_put_in_free_slot(spell.id)
	magic_power = 0
	rank = 0
	_recompute(false)
	loadout_changed.emit()


func knows(id: StringName) -> bool:
	return learned.has(id)


func learned_spells() -> Array[SpellData]:
	var result: Array[SpellData] = []
	for id in learned:
		var spell := LIBRARY.find(id)
		if spell:
			result.append(spell)
	return result


func loadout_spells() -> Array[SpellData]:
	var result: Array[SpellData] = []
	for id in loadout:
		result.append(LIBRARY.find(id) if id != &"" else null)
	return result


## Picks up a spell tome. Returns false if the spell is already known or the tome already carried.
func add_tome(spell: SpellData) -> bool:
	if knows(spell.id) or spell.id in tomes:
		return false
	tomes.append(spell.id)
	tome_found.emit(spell)
	return true


## Reads every carried tome whose Magic Power requirement is met (at a Lantern Shrine, FR-MAG-08).
## Learning one spell can raise Magic Power enough for another, so it repeats until nothing changes.
## Returns {"learned": Array[SpellData], "blocked": Array[SpellData]}.
func read_tomes() -> Dictionary:
	var newly: Array[SpellData] = []
	var progress := true
	while progress:
		progress = false
		for id in tomes.duplicate():
			var spell := LIBRARY.find(id)
			if spell and magic_power >= spell.required_magic_power:
				tomes.erase(id)
				learn(spell)
				newly.append(spell)
				progress = true
	var blocked: Array[SpellData] = []
	for id in tomes:
		var spell := LIBRARY.find(id)
		if spell:
			blocked.append(spell)
	return {"learned": newly, "blocked": blocked}


func learn(spell: SpellData) -> bool:
	if knows(spell.id):
		return false
	learned[spell.id] = {"level": 1, "xp": 0}
	_put_in_free_slot(spell.id)
	spell_learned.emit(spell)
	EventBus.spell_learned.emit(spell.id)
	loadout_changed.emit()
	_recompute()
	return true


func mastery_level(id: StringName) -> int:
	return int(learned[id]["level"]) if learned.has(id) else 0


## 0–1 progress towards the next mastery level (1 at max).
func mastery_progress(id: StringName) -> float:
	var level := mastery_level(id)
	var needed := PROGRESSION.xp_needed(level)
	return 1.0 if needed <= 0 else float(learned[id]["xp"]) / needed


func add_mastery_xp(id: StringName, amount: int) -> void:
	if not learned.has(id):
		return
	var entry := learned[id]
	var levelled := false
	entry["xp"] = int(entry["xp"]) + amount
	while int(entry["level"]) < PROGRESSION.max_mastery and int(entry["xp"]) >= PROGRESSION.xp_needed(int(entry["level"])):
		entry["xp"] = int(entry["xp"]) - PROGRESSION.xp_needed(int(entry["level"]))
		entry["level"] = int(entry["level"]) + 1
		levelled = true
	if int(entry["level"]) >= PROGRESSION.max_mastery:
		entry["xp"] = 0
	if levelled:
		mastery_changed.emit(id, int(entry["level"]))
		_recompute()


## Damage / cost / cooldown changes for a spell from its mastery and Magic Power.
func modifiers_for(spell: SpellData) -> SpellModifiers:
	var mods := SpellModifiers.new()
	var steps := maxi(mastery_level(spell.id) - 1, 0)
	mods.damage = (1.0 + PROGRESSION.damage_bonus_per_level * steps) * (1.0 + magic_power * PROGRESSION.damage_per_power)
	mods.cost = 1.0 - PROGRESSION.cost_reduction_per_level * steps
	mods.cooldown = (1.0 - PROGRESSION.cooldown_reduction_per_level * steps) * (1.0 - gear_cooldown)
	return mods


## Puts a known spell in a slot (or empties it with &""). If it was in another slot, the two swap.
func set_loadout_slot(slot: int, id: StringName) -> void:
	if id != &"" and not knows(id):
		return
	var previous_slot := loadout.find(id) if id != &"" else -1
	if previous_slot != -1:
		loadout[previous_slot] = loadout[slot]
	loadout[slot] = id
	loadout_changed.emit()


func set_equipment_power(value: int) -> void:
	equipment_power = value
	_recompute()


## Magic Power from the pet dragon's bond (GAME_DESIGN.md §5.2), set by DragonManager.
func set_dragon_power(value: int, announce := true) -> void:
	if value == dragon_power:
		return
	dragon_power = value
	_recompute(announce)


func rank_label() -> String:
	return PROGRESSION.rank_label(rank)


func to_dict() -> Dictionary:
	var spells := {}
	for id in learned:
		spells[String(id)] = learned[id].duplicate()
	return {
		"learned": spells,
		"tomes": tomes.map(func(id: StringName) -> String: return String(id)),
		"loadout": loadout.map(func(id: StringName) -> String: return String(id)),
	}


func from_dict(data: Dictionary) -> void:
	learned.clear()
	var spells: Dictionary = data.get("learned", {})
	for id: Variant in spells:
		var entry: Dictionary = spells[id]
		learned[StringName(str(id))] = {"level": int(entry.get("level", 1)), "xp": int(entry.get("xp", 0))}
	tomes.clear()
	for id: Variant in data.get("tomes", []):
		tomes.append(StringName(str(id)))
	var slots: Array = data.get("loadout", [])
	for i in SLOTS:
		loadout[i] = StringName(str(slots[i])) if i < slots.size() else &""
	_read_gear()
	_recompute(false)
	loadout_changed.emit()


func _on_gear_changed() -> void:
	_read_gear()
	_recompute()


func _read_gear() -> void:
	var gear := Inventory.gear_bonus()
	equipment_power = gear.magic_power
	gear_cooldown = gear.spell_cooldown


func _put_in_free_slot(id: StringName) -> void:
	if id in loadout:
		return
	var free := loadout.find(&"")
	if free != -1:
		loadout[free] = id


func _recompute(announce := true) -> void:
	var total := float(equipment_power + dragon_power)
	for id in learned:
		var spell := LIBRARY.find(id)
		if spell:
			total += PROGRESSION.spell_power(spell, int(learned[id]["level"]))
	var new_power := roundi(total)
	var new_rank := PROGRESSION.rank_for(new_power)
	var power_changed := new_power != magic_power
	var previous_rank := rank
	magic_power = new_power
	rank = new_rank
	if power_changed:
		magic_power_changed.emit(magic_power)
		EventBus.magic_power_changed.emit(magic_power)
	if new_rank != previous_rank and announce:
		rank_changed.emit(new_rank, previous_rank)
		EventBus.rank_changed.emit(new_rank)
