class_name BarkSpeaker
extends Node3D
## Short remarks in a speech bubble above a character (FR-DLG-05): Lumen's hints, villagers in passing, enemies.
## Lines come from a .dialogue file, one cue per bark (`%` lines are random variants). Each cue has a cooldown so it
## doesn't repeat too often; a bark with a higher priority replaces a lower one on screen. Gameplay keeps running.

signal barked(text: String)

const TUNING: DialogueTuning = preload("res://data/dialogue/dialogue_tuning.tres")
const FADE_TIME := 0.4

@export var resource: DialogueResource
@export var color := Color(1, 1, 1)

var text := ""
var _label: Label3D
var _time_left := 0.0
var _priority := -1
var _last_said: Dictionary[String, float] = {}


func _ready() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = false
	_label.pixel_size = 0.005
	_label.font_size = 38
	_label.outline_size = 14
	_label.modulate = color
	_label.outline_modulate = Color(0.1, 0.07, 0.12, 0.9)
	_label.width = 520.0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.visible = false
	add_child(_label)


func is_showing() -> bool:
	return _time_left > 0.0


## Says a random line of `cue` unless it was said less than `cooldown` seconds ago or a more important bark is
## showing. Returns true if it was said (await it to get the result).
func bark(cue: String, priority := 0, cooldown := 20.0) -> bool:
	if resource == null or (is_showing() and priority < _priority):
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if _last_said.has(cue) and now - _last_said[cue] < cooldown:
		return false
	_last_said[cue] = now
	var line := await resource.get_next_dialogue_line(cue)
	if line == null or line.text.is_empty():
		return false
	say(line.text, priority)
	return true


## Shows `line_text` straight away.
func say(line_text: String, priority := 0) -> void:
	text = line_text
	_priority = priority
	_label.text = line_text
	_label.visible = true
	_label.modulate.a = 1.0
	_time_left = TUNING.bark_time + line_text.length() * TUNING.bark_time_per_char
	barked.emit(line_text)


## Speech bubbles hide while the game is paused (conversations, menus).
func _notification(what: int) -> void:
	if _label and (what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED):
		_label.visible = _time_left > 0.0 and what == NOTIFICATION_UNPAUSED


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	_label.modulate.a = clampf(_time_left / FADE_TIME, 0.0, 1.0)
	if _time_left <= 0.0:
		_label.visible = false
		_priority = -1
