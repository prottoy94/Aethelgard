class_name MusicLibrary
extends Resource
## Every MusicTrack (music, combat layers, ambience loops), looked up by id. File: data/audio/music_library.tres.

@export var tracks: Array[MusicTrack] = []


func find(id: StringName) -> MusicTrack:
	for track in tracks:
		if track.id == id:
			return track
	return null
