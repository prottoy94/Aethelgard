class_name DragonStageStats
extends Resource
## The pet dragon's body at one growth stage (TECHNICAL_DESIGN.md §4.4: DragonSpeciesData × stage × bond).

@export var stage := DragonTypes.Stage.HATCHLING
@export var max_health := 40.0
@export var defense := 0.0
@export var move_speed := 6.0       ## m/s (Aurelia walks at 5)
@export var bite_damage := 4.0
@export var bite_cooldown := 1.2    ## s between bites
@export var bite_range := 1.3       ## m: bites when this close to its target
@export var bite_radius := 0.7      ## m, size of the bite hit
@export var size := 1.0             ## scale of the model
