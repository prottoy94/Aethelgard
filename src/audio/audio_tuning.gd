class_name AudioTuning
extends Resource
## Mixer behaviour (AUDIO_DESIGN.md §3, §5.3). File: data/audio/audio_tuning.tres.

@export var voices_2d := 12              ## pooled non-positional players
@export var voices_3d := 24              ## pooled positional players
@export var music_fade := 2.0            ## s, switching tracks
@export var loop_crossfade := 1.5        ## s, overlap at a loop point
@export var combat_fade_in := 1.0        ## s
@export var combat_fade_out := 3.0       ## s
@export var calm_delay := 4.0            ## s with no engaged enemy before the combat layer leaves
@export var combat_explore_dip_db := -4.0  ## the explore music steps back a little under the combat layer
@export var stinger_duck_db := -9.0
@export var dialogue_duck_db := -6.0
@export var duck_fade := 0.3             ## s
@export var ambience_fade := 3.0         ## s
@export var footstep_stride := 1.25      ## m between footsteps
