extends Node
## The game clock (FR-WLD-06): ~20 real minutes per game day, counting days, and the current weather (FR-WLD-07),
## rolled every few game hours. DayNightCycle nodes in each region turn this into light, sky and rain.
## Runs only while a region is being played (`running`), and stops while the game is paused.
## Saved by SaveManager through to_dict() / from_dict().

signal hour_changed(hour: int)
signal weather_changed(weather: StringName)

const SETTINGS: TimeSettings = preload("res://data/world/time_settings.tres")

var day := 1
var minutes := 0.0              ## minutes since midnight of `day` (0–1440)
var weather: StringName = &"clear"
var weather_until := 0.0        ## total minutes when the weather is rolled again
var running := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	reset()


## New game: day 1, at the start hour, clear weather.
func reset() -> void:
	day = 1
	minutes = SETTINGS.start_hour * 60.0
	weather = &"clear"
	weather_until = total_minutes() + SETTINGS.weather_change_hours * 60.0


func _process(delta: float) -> void:
	if running:
		advance(delta * SETTINGS.minutes_per_second())


## Moves the clock forward by `game_minutes` (also used by tests and resting).
func advance(game_minutes: float) -> void:
	var before := hour()
	minutes += game_minutes
	while minutes >= 1440.0:
		minutes -= 1440.0
		day += 1
	if hour() != before:
		hour_changed.emit(hour())
	if total_minutes() >= weather_until:
		roll_weather()


func total_minutes() -> float:
	return (day - 1) * 1440.0 + minutes


func hour() -> int:
	return int(minutes / 60.0)


## The hour as a decimal (15.5 = half past three in the afternoon).
func hour_decimal() -> float:
	return minutes / 60.0


func set_hour(h: float) -> void:
	var before := hour()
	minutes = fposmod(h, 24.0) * 60.0
	if hour() != before:
		hour_changed.emit(hour())


func is_night() -> bool:
	var h := hour_decimal()
	return h >= SETTINGS.night_start_hour or h < SETTINGS.night_end_hour


## "Day 2, 15:30"
func clock_text() -> String:
	return "Day %d, %02d:%02d" % [day, hour(), int(minutes) % 60]


func set_weather(id: StringName) -> void:
	weather_until = total_minutes() + SETTINGS.weather_change_hours * 60.0
	if id != weather:
		weather = id
		weather_changed.emit(id)


func roll_weather() -> void:
	var roll := rng.randf()
	var picked: StringName = SETTINGS.weather_ids[0]
	for i in SETTINGS.weather_ids.size():
		roll -= SETTINGS.weather_chances[i]
		if roll < 0.0:
			picked = SETTINGS.weather_ids[i]
			break
	set_weather(picked)


func to_dict() -> Dictionary:
	return {"day": day, "minutes": minutes, "weather": String(weather), "weather_until": weather_until}


func from_dict(data: Dictionary) -> void:
	day = maxi(int(data.get("day", 1)), 1)
	minutes = clampf(float(data.get("minutes", SETTINGS.start_hour * 60.0)), 0.0, 1439.99)
	var saved := StringName(str(data.get("weather", "clear")))
	weather = saved if saved in SETTINGS.weather_ids else &"clear"
	weather_until = float(data.get("weather_until", total_minutes() + SETTINGS.weather_change_hours * 60.0))
	weather_changed.emit(weather)
	hour_changed.emit(hour())
