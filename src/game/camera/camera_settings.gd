class_name CameraSettings
extends Resource
## Tuning for the hybrid high-angle camera (3D_PROPOSAL.md §3). Values: data/camera/follow_camera.tres.

@export_group("Framing")
@export var pitch_deg := -42.0          ## look-down angle
@export var fov := 40.0
@export var distance := 13.5            ## m from the focus point
@export var min_distance := 7.0
@export var max_distance := 22.0
@export var zoom_step := 1.5            ## m per mouse-wheel notch
@export var focus_height := 1.0         ## m above the player's feet

@export_group("Feel")
@export var follow_smoothing := 10.0    ## higher = tighter follow
@export var rotate_speed_deg := 110.0   ## deg/s while Q/R are held
@export var rotate_smoothing := 12.0
@export var drag_sensitivity := 0.25    ## deg per pixel of middle-mouse drag
@export var zoom_smoothing := 10.0

@export_group("Scenic & occlusion")
@export var scenic_blend_speed := 1.2   ## blend amount per second into/out of scenic shots
@export var occlusion_fade := 0.8       ## how see-through blocking objects become (0–1)
@export var occlusion_fade_speed := 6.0 ## fade amount per second
@export var near_fade_radius := 4.5     ## m: tree canopies this close to the lens fade too, even off the sight line
