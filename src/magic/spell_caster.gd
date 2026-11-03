class_name SpellCaster
extends Node
## Casts the spells in the 4 loadout slots: checks Exhausted, the slot cooldown, the short global cooldown
## and stamina, in that order (TECHNICAL_DESIGN.md §4.6). Spells spawn next to the caster.

signal cast_succeeded(slot: int, spell: SpellData)
signal cast_failed(slot: int, reason: StringName)  ## &"empty", &"exhausted", &"cooldown", &"global", &"stamina"
signal spell_landed(spell: SpellData, target: Node)

const SLOT_COUNT := 4

@export var stamina: StaminaComponent
@export var global_cooldown := 0.25
## Optional: returns SpellModifiers for a SpellData (mastery, Magic Power). Set by the player.
var modifiers_provider: Callable

var loadout: Array[SpellData] = [null, null, null, null]
## The Spell node spawned by the last successful cast (null if its data has no scene).
var last_spell: Spell
var cooldowns: Array[Cooldown] = []
var _global := Cooldown.new()


func _init() -> void:
	for i in SLOT_COUNT:
		cooldowns.append(Cooldown.new())


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_global.tick(delta)
	for cooldown in cooldowns:
		cooldown.tick(delta)


func set_slot(slot: int, spell: SpellData) -> void:
	loadout[slot] = spell
	cooldowns[slot].start(0.0)


## Why a cast in `slot` would fail right now, or &"" if it would work.
func check(slot: int) -> StringName:
	var spell := loadout[slot]
	if spell == null:
		return &"empty"
	if stamina and stamina.exhausted:
		return &"exhausted"
	if not cooldowns[slot].is_ready():
		return &"cooldown"
	if not _global.is_ready():
		return &"global"
	if stamina and stamina.current < effective_cost(slot):
		return &"stamina"
	return &""


func modifiers(spell: SpellData) -> SpellModifiers:
	return modifiers_provider.call(spell) if modifiers_provider.is_valid() else SpellModifiers.new()


## Stamina the spell in `slot` costs right now (after mastery).
func effective_cost(slot: int) -> float:
	var spell := loadout[slot]
	return spell.stamina_cost * modifiers(spell).cost if spell else 0.0


## Casts the spell in `slot` from `origin` towards `aim`. Returns true if it was cast.
func try_cast(slot: int, origin: Node3D, aim: Vector3) -> bool:
	var reason := check(slot)
	if reason != &"":
		if reason == &"stamina" or reason == &"exhausted":
			stamina.spend_failed.emit()
		cast_failed.emit(slot, reason)
		return false
	var spell_data := loadout[slot]
	var mods := modifiers(spell_data)
	if stamina:
		stamina.try_spend(spell_data.stamina_cost * mods.cost)
	cooldowns[slot].start(spell_data.cooldown * mods.cooldown)
	_global.start(global_cooldown)
	last_spell = null
	if spell_data.scene:
		last_spell = spell_data.scene.instantiate() as Spell
		origin.get_parent().add_child(last_spell)
		last_spell.global_position = origin.global_position
		last_spell.landed.connect(func(target: Node) -> void: spell_landed.emit(spell_data, target))
		last_spell.cast(origin, aim, spell_data, mods.damage)
	cast_succeeded.emit(slot, spell_data)
	return true
