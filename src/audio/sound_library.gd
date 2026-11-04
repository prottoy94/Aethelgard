class_name SoundLibrary
extends Resource
## Every SoundEvent, looked up by id. File: assets/audio/sound_library.tres (written by the placeholder generator;
## events added by hand go in `events` too).

@export var events: Array[SoundEvent] = []

var _by_id: Dictionary[StringName, SoundEvent] = {}


func find(id: StringName) -> SoundEvent:
	if _by_id.size() != events.size():
		_by_id.clear()
		for event in events:
			_by_id[event.id] = event
	return _by_id.get(id)
