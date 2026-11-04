class_name BossPhaseData
extends Resource
## One phase of a boss (FR-BOS-01): it starts when the boss's HP falls to `health_ratio` and brings its own moves.

@export var health_ratio := 1.0              ## 1.0 = from the start; 0.6 = when HP drops to 60%
@export var moves: Array[EnemyMoveData] = []
@export var speed_multiplier := 1.0
@export var opening_move: StringName          ## a move done as soon as the phase starts (e.g. calling helpers)
@export_multiline var announce := ""          ## a line on screen when the phase begins
