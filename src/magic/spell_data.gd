class_name SpellData
extends Resource
## One spell's numbers and behaviour scene (TECHNICAL_DESIGN.md §4.4). Files: data/spells/*.tres.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var element := Elements.Type.LIGHT
@export var scene: PackedScene              ## the spell's runtime behaviour (extends Spell)

@export_group("Cost")
@export var stamina_cost := 10.0
@export var cooldown := 1.0                 ## s

@export_group("Effect")
@export var base_damage := 10.0
@export var knockback := 3.0                ## m/s push
@export var stagger := false
@export var speed := 14.0                   ## m/s for projectiles
@export var spell_range := 12.0             ## m
@export var radius := 0.25                  ## m: projectile size, or cone/area radius
@export var angle_deg := 0.0                ## cone width for cone spells
@export var duration := 0.0                 ## s for lasting spells (auras, heals over time)
@export var status_effect := &""          ## applied on hit (StatusEffectComponent id)
@export var status_duration := 0.0
@export var status_power := 0.0

@export_group("Progression (Phase 4)")
@export var power_value := 10               ## contribution to Magic Power
@export var required_magic_power := 0       ## gate for learning
