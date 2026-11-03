class_name HumanoidAnimSet
extends Resource
## Which animation plays for each character action, which library it comes from, and how fast the source
## motion moves (so playback can be matched to the real movement speed and feet don't slide).
## Default set: data/animations/humanoid_default.tres (Quaternius Universal Animation Library, CC0).

## Imported model scene whose AnimationPlayer holds the animation library (retargeted to GeneralSkeleton).
@export var library_scene: PackedScene

@export_group("Animation names")
@export var idle := &"Idle"
@export var walk := &"Walk"
@export var run := &"Jog_Fwd"
@export var dash := &"Sprint"
@export var cast := &"Spell_Simple_Shoot"
@export var strike := &"Sword_Attack"
@export var hurt := &"Hit_Chest"
@export var death := &"Death01"
@export var interact := &"Interact"
@export var rest := &"Sitting_Idle"

@export_group("Speeds (for a 1.83 m skeleton; scaled with the model)")
@export var walk_native_speed := 1.03   ## m/s the walk animation's feet move at playback speed 1
@export var run_native_speed := 3.0     ## m/s for the run animation
@export var run_threshold := 2.2        ## m/s: faster than this uses the run animation
@export var source_height := 1.83       ## m, height of the skeleton the speeds were measured on
@export var dash_speed_scale := 1.5
@export var min_speed_scale := 0.7
@export var max_speed_scale := 1.7
@export var blend_time := 0.18          ## s cross-fade between animations
