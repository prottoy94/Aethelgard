class_name MusicTrack
extends Resource
## A piece of music or ambience with its loop points (AUDIO_DESIGN.md §5, §10.5). Loops are handled by the
## AudioManager with a short crossfade, so the owner's files are used exactly as they are (no trimming).
## Files: data/audio/music/*.tres.

@export var id: StringName
@export_file("*.ogg", "*.mp3", "*.wav") var file: String
@export var bus: StringName = &"Music"
@export var volume_db := 0.0
@export var loop := true
@export var loop_start := 0.0      ## s: where a repeat starts (skip the intro)
@export var loop_end := 0.0        ## s: where it jumps back (0 = the end of the file; set it to cut an outro)
@export var start := 0.0           ## s: where it starts playing the first time
@export var bpm := 0.0             ## for reference and beat-timed changes later
@export_multiline var notes: String  ## where it comes from and why it is used here
