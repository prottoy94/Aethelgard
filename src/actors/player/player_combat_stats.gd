class_name PlayerCombatStats
extends Resource
## Aurelia's combat tuning (GAME_DESIGN.md §5–7). Values: data/player/aurelia_combat.tres.

@export_group("Health & stamina")
@export var max_health := 100.0
@export var defense := 0.0
@export var max_stamina := 40.0
@export var stamina_regen := 12.0          ## per second
@export var stamina_regen_delay := 0.8     ## s
@export var exhausted_recover_ratio := 0.3

@export_group("Staff strike")
@export var strike_damage := 8.0
@export var strike_knockback := 3.0        ## m/s
@export var strike_windup := 0.1           ## s before the hit becomes active
@export var strike_active := 0.12          ## s the hit is active
@export var strike_recovery := 0.2         ## s after the hit before moving freely
@export var strike_cooldown := 0.45        ## s between strikes
@export var strike_move_factor := 0.3      ## movement speed while striking (× walk speed)
@export var strike_buffer := 0.15          ## s a strike press is remembered

@export_group("Spells")
@export var global_cooldown := 0.25        ## s after any cast
@export var cast_face_time := 0.35         ## s she keeps facing the aim after casting
@export var starting_spells: Array[SpellData] = []

@export_group("Getting hurt")
@export var hurt_stun := 0.3               ## s without control after a hit
@export var hurt_invulnerable := 0.8       ## s of protection after a hit
@export var knockback_decay := 10.0        ## how fast knockback slows down
@export var respawn_delay := 2.5           ## s after defeat
@export var respawn_invulnerable := 1.5    ## s of protection after respawning
