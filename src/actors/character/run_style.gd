class_name RunStyle
extends Resource
## How a character's run is restyled on top of the run animation (owner request 2026-11-06: Aurelia should run like a
## sweet girl, not like a man chasing a dog). Used by RunStyleModifier. Directions are in the skeleton's space: the
## character faces +Z, +Y is up, +X is its left. Values: data/animations/aurelia_run_style.tres.

@export_range(0.0, 1.0) var arm_weight := 0.8      ## how strongly the arms take the pose below (1 = fully)
@export var upper_arm_dir := Vector3(0.22, -0.95, -0.12)  ## left upper arm: hanging close, a little back
@export var forearm_dir := Vector3(0.75, -0.62, 0.05)     ## left forearm: flared out, hands to the sides
@export var torso_upright_deg := 9.0               ## straightens the run's forward lean
@export_range(0.2, 1.0) var stride_scale := 0.7    ## shorter steps (leg swing × this)…
@export var max_speed_scale := 2.1                 ## …played quicker to keep up with her speed
@export var head_sway_deg := 5.0                   ## a little side-to-side tilt of the head
@export var bounce := 0.025                        ## m of extra hop each step (in skeleton units)
@export var step_rate := 1.6                     ## sways and hops per second
@export var blend_speed := 8.0                     ## how fast the style fades in and out
