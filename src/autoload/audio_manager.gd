extends Node
## Plays every sound by event id (FR-AUD-01, AUDIO_DESIGN.md §4): SoundEvents from assets/audio/sound_library.tres
## through pooled players, with per-sound polyphony limits, minimum intervals and random pitch/volume (FR-AUD-05).
## Music (MusicTracks with loop points) crossfades and gets a combat layer that fades in while enemies are engaged
## (FR-AUD-07); ambience follows region, time of day and weather (FR-AUD-09); stingers duck the music (FR-AUD-08);
## music also ducks under dialogue and everything but UI is muffled while paused (FR-AUD-10).
## Gameplay code never loads audio files: it calls play(&"id") / play(&"id", position).

signal music_changed(track_id: StringName)
signal sound_played(id: StringName)

const LIBRARY_PATH := "res://assets/audio/sound_library.tres"
const MUSIC: MusicLibrary = preload("res://data/audio/music_library.tres")
const TUNING: AudioTuning = preload("res://data/audio/audio_tuning.tres")
const VOLUME_BUSES: Array[StringName] = [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]
const MUFFLED_BUSES: Array[StringName] = [&"Music", &"Ambience"]

var library: SoundLibrary
var music: MusicChannel
var combat_layer: MusicChannel
var ambience: MusicChannel
var weather: MusicChannel
var in_combat := false
var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _voices: Dictionary[StringName, Array] = {}   ## id → players playing it, oldest first
var _last_played: Dictionary[StringName, float] = {}
var _streams: Dictionary[String, AudioStream] = {}
var _warned: Dictionary[String, bool] = {}
var _was_paused := false
var _ducks: Dictionary[StringName, float] = {}    ## reason → dB, combined into the music level
var _calm_left := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	if ResourceLoader.exists(LIBRARY_PATH):
		library = load(LIBRARY_PATH) as SoundLibrary
	if library == null:
		library = SoundLibrary.new()
		push_warning("AudioManager: no sound library yet; run tools/audio/generate_placeholders.py")
	for i in TUNING.voices_2d:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool_2d.append(player)
	for i in TUNING.voices_3d:
		var player := AudioStreamPlayer3D.new()
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.unit_size = 4.0
		add_child(player)
		_pool_3d.append(player)
	music = _channel(&"Music", TUNING.loop_crossfade)
	combat_layer = _channel(&"Music", TUNING.loop_crossfade)
	ambience = _channel(&"Ambience", TUNING.ambience_fade)
	weather = _channel(&"Ambience", TUNING.ambience_fade)
	_connect_stingers()


func _process(delta: float) -> void:
	var paused := get_tree().paused
	if paused != _was_paused:
		_was_paused = paused
		_set_muffled(paused)
	if _calm_left > 0.0 and not get_tree().paused:
		_calm_left -= delta
		if _calm_left <= 0.0:
			_set_combat(false)


# --- Sound effects -------------------------------------------------------------------------------

## Plays sound `id`; with a Vector3 `at` (and a positional event) it is placed in the world. Returns false if the
## sound is unknown, has no files, or was skipped by its polyphony/interval limits.
func play(id: StringName, at: Variant = null) -> bool:
	var event := library.find(id)
	if event == null:
		_warn_once("unknown sound %s" % id)
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(id, -INF) < event.min_interval:
		return false
	var stream := _pick_stream(event)
	if stream == null:
		return false
	_last_played[id] = now
	var voices: Array = _voices.get_or_add(id, [])
	voices = voices.filter(func(p: Node) -> bool:
		return is_instance_valid(p) and p.get(&"playing") and p.get_meta(&"event", &"") == id)
	if voices.size() >= event.max_polyphony:
		(voices.pop_front() as Node).call(&"stop")
	var player := _free_player(at is Vector3 and event.positional)
	player.set(&"stream", stream)
	player.set(&"bus", event.bus)
	player.set(&"pitch_scale", _rng.randf_range(event.pitch_range.x, event.pitch_range.y))
	player.set(&"volume_db", event.volume_db + _rng.randf_range(-event.volume_jitter_db, event.volume_jitter_db))
	player.set_meta(&"event", id)
	if player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).max_distance = event.max_distance
		(player as AudioStreamPlayer3D).global_position = at
	player.call(&"play")
	voices.append(player)
	_voices[id] = voices
	sound_played.emit(id)
	return true


## AUDIO_DESIGN.md §4.1 names: play_sfx(id) and play_sfx_at(id, position).
func play_sfx(id: StringName) -> bool:
	return play(id)


func play_sfx_at(id: StringName, at: Vector3) -> bool:
	return play(id, at)


func has_sound(id: StringName) -> bool:
	return library.find(id) != null


## A short musical moment (FR-AUD-08) that ducks the music while it plays. One at a time: a stinger that comes
## while another is playing is skipped (the dragon hatching also finishes a quest).
func play_stinger(id: StringName) -> void:
	if _ducks.has(&"stinger"):
		return
	if play(id):
		var event := library.find(id)
		var stream := _stream(event.files[0]) if event and not event.files.is_empty() else null
		duck(&"stinger", TUNING.stinger_duck_db)
		get_tree().create_timer(stream.get_length() if stream else 2.0, true).timeout.connect(func() -> void:
			duck(&"stinger", 0.0))


# --- Music & ambience ----------------------------------------------------------------------------

## Plays music track `id` (crossfading from the current one). An unknown id or missing file stops the music.
func play_music(id: StringName, fade := -1.0) -> void:
	var track := MUSIC.find(id)
	var time := TUNING.music_fade if fade < 0.0 else fade
	if track == null:
		music.stop(time)
		return
	music.play(track, _stream(track.file), time)
	music_changed.emit(id)


func stop_music(fade := -1.0) -> void:
	music.stop(TUNING.music_fade if fade < 0.0 else fade)
	combat_layer.stop(TUNING.combat_fade_out)
	in_combat = false


func current_music() -> StringName:
	return music.track.id if music.track else &""


## Sets the combat layer that goes with the current music (silent until set_combat).
func set_combat_layer(id: StringName) -> void:
	var track := MUSIC.find(id)
	if track == null:
		combat_layer.stop(TUNING.combat_fade_out)
		return
	combat_layer.play(track, _stream(track.file), 0.0)
	combat_layer.level_db = 0.0 if in_combat else -80.0


## Called with true while any enemy is engaged with Aurelia; the layer leaves a few seconds after the last one.
func set_combat(engaged: bool) -> void:
	if engaged:
		_calm_left = 0.0
		_set_combat(true)
	elif in_combat and _calm_left <= 0.0:
		_calm_left = TUNING.calm_delay


## AUDIO_DESIGN.md §4.1 name: set_music_state(&"explore" | &"combat").
func set_music_state(state: StringName) -> void:
	set_combat(state == &"combat")


func play_ambience(id: StringName) -> void:
	_play_on(ambience, id)


func play_weather(id: StringName) -> void:
	_play_on(weather, id)


## Lowers the music by `db` for `reason` (0 removes it). Several reasons combine: the deepest one wins.
func duck(reason: StringName, db: float) -> void:
	if db == 0.0:
		_ducks.erase(reason)
	else:
		_ducks[reason] = db
	music.set_level(_duck_level(), TUNING.duck_fade)


# --- Volume (NFR-AUD-04) -------------------------------------------------------------------------

## Linear volume 0–1 for one of VOLUME_BUSES.
func set_bus_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index != -1:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0001, 1.0)))
		AudioServer.set_bus_mute(index, linear <= 0.001)


func bus_volume(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(bus)
	return 0.0 if index == -1 or AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index))


# --- Inside --------------------------------------------------------------------------------------

func _channel(bus: StringName, crossfade: float) -> MusicChannel:
	var channel := MusicChannel.new()
	add_child(channel)
	channel.setup(bus, crossfade)
	return channel


func _play_on(channel: MusicChannel, id: StringName) -> void:
	var track := MUSIC.find(id)
	if track == null:
		channel.stop(TUNING.ambience_fade)
	else:
		channel.play(track, _stream(track.file), TUNING.ambience_fade)


func _set_combat(on: bool) -> void:
	if on == in_combat:
		return
	in_combat = on
	combat_layer.set_level(0.0 if on else -80.0, TUNING.combat_fade_in if on else TUNING.combat_fade_out)
	if on and combat_layer.track != null:  # dip the music only to make room for a combat layer
		_ducks[&"combat"] = TUNING.combat_explore_dip_db
	else:
		_ducks.erase(&"combat")
	music.set_level(_duck_level(), TUNING.combat_fade_in if on else TUNING.combat_fade_out)


func _duck_level() -> float:
	var level := 0.0
	for reason in _ducks:
		level = minf(level, _ducks[reason])
	return level


func _set_muffled(on: bool) -> void:
	for bus in MUFFLED_BUSES:
		var index := AudioServer.get_bus_index(bus)
		for effect in AudioServer.get_bus_effect_count(index):
			if AudioServer.get_bus_effect(index, effect) is AudioEffectLowPassFilter:
				AudioServer.set_bus_effect_enabled(index, effect, on)


func _pick_stream(event: SoundEvent) -> AudioStream:
	if event.files.is_empty():
		return null
	return _stream(event.files[_rng.randi() % event.files.size()])


func _stream(path: String) -> AudioStream:
	if path == "":
		return null
	if _streams.has(path):
		return _streams[path]
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	if stream == null:
		_warn_once("missing audio file %s (placeholders: tools/audio/generate_placeholders.py)" % path)
	_streams[path] = stream
	return stream


func _free_player(positional: bool) -> Node:
	var pool: Array = _pool_3d if positional else _pool_2d
	for player: Node in pool:
		if not player.get(&"playing"):
			return player
	var oldest: Node = pool[0]  # all busy: take the first one and move it to the back
	pool.erase(oldest)
	pool.append(oldest)
	oldest.call(&"stop")
	return oldest


func _warn_once(message: String) -> void:
	if not _warned.has(message):
		_warned[message] = true
		push_warning("AudioManager: " + message)


## Lets go of every stream when the game closes (no resources left in use at exit).
func _exit_tree() -> void:
	silence()


## Stops every sound and all music at once and drops the streams (quitting, end of a test run).
func silence() -> void:
	for player: Node in _pool_2d + _pool_3d:
		player.call(&"stop")
		player.set(&"stream", null)
	for channel in [music, combat_layer, ambience, weather]:
		channel.release()
	_streams.clear()
	_voices.clear()


## Stingers for big moments (AUDIO_DESIGN.md §5.3), from cross-system events.
func _connect_stingers() -> void:
	EventBus.spell_learned.connect(func(_id: StringName) -> void: play_stinger(&"stg_spell_learned"))
	EventBus.rank_changed.connect(func(_rank: int) -> void: play_stinger(&"stg_rank_up"))
	EventBus.quest_completed.connect(func(_id: StringName) -> void: play_stinger(&"stg_quest_complete"))
	EventBus.item_crafted.connect(func(_id: StringName) -> void: play_stinger(&"stg_item_crafted"))
	EventBus.secret_found.connect(func(_id: StringName) -> void: play_stinger(&"stg_secret_found"))
	EventBus.dragon_hatched.connect(func() -> void: play_stinger(&"stg_dragon_hatched"))
	EventBus.puzzle_solved.connect(func(_id: StringName) -> void: play(&"puzzle_solved"))
	EventBus.quest_started.connect(func(_id: StringName) -> void: play(&"ui_quest_update"))
	SaveManager.saved.connect(func(_slot: StringName) -> void: play(&"ui_save"))
