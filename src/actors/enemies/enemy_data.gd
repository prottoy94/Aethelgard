class_name EnemyData
extends Resource
## One enemy type's numbers (TECHNICAL_DESIGN.md §4.4). Files: data/enemies/*.tres.

@export var id: StringName
@export var display_name: String
@export var element := Elements.Type.NONE
@export var rank := "F"                     ## Arcane Rank letter shown above the health bar
@export var loot: LootTable                 ## what it drops when defeated (optional)

@export_group("Body")
@export var max_health := 30.0
@export var defense := 0.0
@export var move_speed := 2.6               ## m/s while chasing
@export var wander_speed := 1.0             ## m/s while idle
@export var knockback_resistance := 0.0     ## 0 = full knockback, 1 = immovable

@export_group("Senses")
@export var aggro_range := 9.0              ## m: starts chasing the player
@export var leash_range := 16.0             ## m: gives up the chase

@export_group("Attack")
@export var attack_range := 2.0             ## m: starts the wind-up when this close
@export var min_range := 0.0               ## m: ranged enemies back away when closer than this (0 = melee)
@export var telegraph_time := 0.8           ## s of visible warning before the hit (FR-CMB-05)
@export var attack_damage := 12.0
@export var attack_element := Elements.Type.NONE
@export var attack_radius := 1.9            ## m
@export var attack_knockback := 7.0         ## m/s
@export var attack_active := 0.15           ## s the hit is active
@export var recover_time := 1.0             ## s of vulnerability after attacking
@export var stagger_time := 0.45            ## s stunned when staggered
@export var attack_status := &""          ## status effect the attack applies (e.g. &"burn")
@export var attack_status_duration := 0.0
@export var attack_status_power := 0.0

@export_group("Projectile (ranged enemies)")
@export var projectile_speed := 7.0        ## m/s
@export var projectile_range := 14.0       ## m
@export var projectile_radius := 0.3       ## m
