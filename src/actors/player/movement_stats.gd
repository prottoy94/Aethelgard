class_name MovementStats
extends Resource
## Movement tuning for a character. Aurelia's values: data/player/aurelia_movement.tres.

@export_group("Walking")
@export var walk_speed := 5.0           ## m/s
@export var acceleration := 40.0        ## m/s² towards the target speed
@export var deceleration := 55.0        ## m/s² when stopping
@export var turn_speed := 14.0          ## how fast the body turns to face the move direction

@export_group("Dash")
@export var dash_speed := 15.0          ## m/s
@export var dash_duration := 0.18       ## s
@export var dash_invulnerable_time := 0.22  ## s of i-frames from the start of the dash
@export var dash_cooldown := 0.6        ## s
@export var dash_buffer_time := 0.15    ## s a dash press is remembered while the dash is cooling down

@export_group("Ground")
@export var gravity := 25.0             ## m/s²
@export var floor_snap := 0.45          ## m; keeps her on slopes and stairs going down
@export var max_floor_angle_deg := 46.0 ## steeper surfaces are walls (stair ramps are ~27°)
