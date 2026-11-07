class_name ClothChainSettings
extends Resource
## How one group of cloth or hair chains moves (SpringBoneSimulator3D settings). Used by ClothRig.

@export_range(0.0, 4.0) var stiffness := 1.0   ## pull back to the rest shape
@export_range(0.0, 1.0) var drag := 0.4        ## damping (higher = calmer, less swinging)
@export_range(0.0, 4.0) var gravity := 0.0     ## extra pull down
@export var radius := 0.02                     ## joint size for collisions (skeleton units)
