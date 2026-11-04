class_name EnemyMoveData
extends Resource
## One attack of an enemy or boss (GAME_DESIGN.md §7.1: "2–4 attack moves with clear telegraphs"). Every move is
## Telegraph → Attack → Recover (FR-CMB-05) and shows its own warning on the ground: a ring (MELEE, RING), a lane
## (CHARGE) or a fan (VOLLEY). Its wind-up sound is "enemy_<enemy id>_<move id>_telegraph" and lasts as long as the
## telegraph (FR-AUD-03). Lives inside the enemy's data file (EnemyData.moves, BossPhaseData.moves).

enum Kind { MELEE, CHARGE, RING, VOLLEY, SUMMON }

@export var id: StringName
@export var kind := Kind.MELEE
@export var weight := 1.0                  ## how often it is picked among the moves that are in range
@export var min_range := 0.0               ## m: only used when the target is at least this far…
@export var max_range := 2.5               ## m: …and at most this far

@export_group("Timing")
@export var telegraph_time := 1.0          ## s of visible warning
@export var active_time := 0.2             ## s the hit is active (CHARGE: the dash)
@export var recover_time := 1.0            ## s open to counter-attacks afterwards
@export var follow_up: StringName          ## a move done straight after this one (combos), or empty

@export_group("Hit")
@export var damage := 12.0
@export var element := Elements.Type.NONE
@export var knockback := 7.0
@export var radius := 2.0                  ## m: MELEE/RING reach, CHARGE body hit size
@export var arc_deg := 360.0               ## MELEE: width of the sweep in front (360 = all around)
@export var status := &""
@export var status_duration := 0.0
@export var status_power := 0.0

@export_group("Charge")
@export var length := 8.0                  ## m dashed
@export var width := 1.6                   ## m, the warning lane's width

@export_group("Volley")
@export var count := 3
@export var spread_deg := 30.0
@export var projectile_speed := 8.0
@export var projectile_range := 14.0
@export var projectile_radius := 0.3

@export_group("Summon")
@export var summon_scene: PackedScene
@export var summon_count := 2
@export var summon_distance := 3.0


## Charge speed that covers `length` in `active_time`.
func charge_speed() -> float:
	return length / maxf(active_time, 0.05)


func in_range(distance: float) -> bool:
	return distance >= min_range and distance <= max_range
