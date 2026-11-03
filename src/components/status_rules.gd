class_name StatusRules
extends Resource
## How status effects behave (GAME_DESIGN.md §6.5). Values: data/combat/status_rules.tres.

@export var burn_tick := 0.5               ## s between Burn damage ticks (power = damage per second)
@export var chill_slow_per_stack := 0.2    ## speed lost per Chill stack
@export var freeze_stacks := 3             ## Chill stacks that turn into Freeze
@export var freeze_time := 1.2             ## s frozen solid
@export var daze_slow := 0.4               ## speed lost while Dazed
@export var ember_mark_damage := 1.25      ## damage taken × this while Ember Marked
