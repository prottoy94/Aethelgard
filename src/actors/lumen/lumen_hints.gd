class_name LumenHints
extends Resource
## When and how Lumen helps (GAME_DESIGN.md §10, FR-PUZ-07, FR-DLG-05). File: data/dialogue/lumen_hints.tres.

@export var follow_speed := 3.0         ## how quickly Lumen catches up with Aurelia
@export var orbit_radius := 0.9         ## m around her head
@export var height := 1.9               ## m above her feet
@export var secret_radius := 7.0        ## m: Lumen notices hidden things this close
@export var secret_cooldown := 45.0     ## s before the "secret nearby" remark can repeat
@export var stuck_time := 25.0          ## s near an unsolved puzzle without progress before a hint
@export var hint_cooldown := 40.0       ## s before the same puzzle hint can repeat
@export var low_health_ratio := 0.3     ## the first time HP drops below this, Lumen says something
@export var glow_near_secret := 2.2     ## light energy when a secret is near (normal 0.6)
