class_name DragonSkillData
extends Resource
## One pet dragon skill (GAME_DESIGN.md §8.3–8.4): an ACTIVE breath the player triggers (H) on its own cooldown, or a
## PASSIVE trait. Unlocked by growth stage and bond level (FR-DRG-05). Lives inside data/dragons/<element>.tres.

enum Kind { ACTIVE, PASSIVE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind := Kind.ACTIVE
@export var stage := DragonTypes.Stage.HATCHLING   ## the first growth stage that has it
@export var bond_required := 1

@export_group("Active (breath)")
@export var cooldown := 8.0              ## s
@export var damage := 8.0
@export var element := Elements.Type.NONE
@export var radius := 3.5                ## m, length of the breath cone
@export var angle_deg := 70.0            ## width of the cone
@export var knockback := 3.0             ## m/s
@export var stagger := false
@export var status := &""                ## status effect on hit (StatusEffectComponent id)
@export var status_duration := 0.0
@export var status_power := 0.0
@export var wind_up := 0.3               ## s it visibly breathes in first
@export var approach_range := 8.0        ## m: runs this far towards a target before breathing

@export_group("Passive (trait)")
@export var bite_status := &""           ## its bites apply this status
@export var bite_status_duration := 0.0
@export var bite_status_power := 0.0
@export var bite_knockback_bonus := 0.0  ## m/s added to its bites
@export var speed_multiplier := 1.0
@export var damage_taken_multiplier := 1.0
@export var glow_energy := 0.0           ## a soft light around it (0 = none)


func is_unlocked(at_stage: DragonTypes.Stage, bond_level: int) -> bool:
	return at_stage >= stage and bond_level >= bond_required


## "Breath skill" or "Trait", for menus.
func kind_name() -> String:
	return "Breath skill (H)" if kind == Kind.ACTIVE else "Trait"
