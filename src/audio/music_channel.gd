class_name MusicChannel
extends Node
## One stream of music or ambience: plays a MusicTrack, loops it at its loop points with a short crossfade, fades
## between tracks, and has a level (for ducking or for a combat layer that comes and goes). Used by AudioManager.

var track: MusicTrack
var level_db := 0.0           ## extra gain for ducking/layers, tweened
var crossfade := 1.5          ## s at loop points
var _players: Array[AudioStreamPlayer] = []
var _gains: Array[float] = [0.0, 0.0]  ## linear fade per player
var _active := 0
var _tweens: Array[Tween] = [null, null]
var _level_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func setup(bus: StringName, crossfade_time: float) -> void:
	crossfade = crossfade_time
	for player in _players:
		player.bus = bus


func is_playing() -> bool:
	return track != null and _players[_active].playing


## Starts `new_track` (with `stream`), fading the old one out over `fade` seconds. The same track keeps playing.
func play(new_track: MusicTrack, stream: AudioStream, fade: float) -> void:
	if new_track == track and is_playing():
		return
	_fade_player(_active, 0.0, fade, true)
	track = new_track
	if stream == null:
		return
	_active = 1 - _active
	_start(_active, stream, new_track.start, fade)


func stop(fade: float) -> void:
	_fade_player(_active, 0.0, fade, true)
	track = null


## Stops at once and drops the streams (when the game closes).
func release() -> void:
	track = null
	for player in _players:
		player.stop()
		player.stream = null


## Moves the channel's level to `db` over `fade` seconds (ducking, combat layer in/out).
func set_level(db: float, fade: float) -> void:
	if _level_tween:
		_level_tween.kill()
	_level_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_level_tween.tween_property(self, "level_db", db, maxf(fade, 0.01))


func position() -> float:
	return _players[_active].get_playback_position() if is_playing() else 0.0


func _process(_delta: float) -> void:
	for i in 2:
		var player := _players[i]
		var base := track.volume_db if track else 0.0
		player.volume_db = base + level_db + linear_to_db(maxf(_gains[i], 0.0001))
	if track == null or not _players[_active].playing:
		return
	var player := _players[_active]
	if not track.loop:
		# A one-shot part of a song (e.g. Sunlight's intro and first verse): fades out at loop_end.
		if track.loop_end > 0.0 and player.get_playback_position() >= track.loop_end - crossfade:
			stop(crossfade)
		return
	var length := player.stream.get_length()
	var end := track.loop_end if track.loop_end > 0.0 else length
	if length > 0.0 and player.get_playback_position() >= end - crossfade:
		var stream := player.stream
		_fade_player(_active, 0.0, crossfade, true)
		_active = 1 - _active
		_start(_active, stream, track.loop_start, crossfade)


func _start(index: int, stream: AudioStream, from: float, fade: float) -> void:
	var player := _players[index]
	player.stream = stream
	_gains[index] = 0.0 if fade > 0.0 else 1.0
	player.play(from)
	_fade_player(index, 1.0, fade, false)


func _fade_player(index: int, gain: float, fade: float, stop_after: bool) -> void:
	if _tweens[index]:
		_tweens[index].kill()
	if fade <= 0.0:
		_gains[index] = gain
		if stop_after:
			_players[index].stop()
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(g: float) -> void: _gains[index] = g, _gains[index], gain, fade)
	if stop_after:
		tween.tween_callback(_players[index].stop)
	_tweens[index] = tween
