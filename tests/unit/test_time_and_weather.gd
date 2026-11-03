extends GutTest
## The game clock and weather (FR-WLD-06/07): TimeOfDay, and the day/night keyframes in data/world/day_night.tres.

const DAY_NIGHT: DayNightData = preload("res://data/world/day_night.tres")


func before_each() -> void:
	TimeOfDay.running = false
	TimeOfDay.reset()


func test_new_game_starts_in_the_afternoon() -> void:
	assert_eq(TimeOfDay.day, 1)
	assert_eq(TimeOfDay.hour(), int(TimeOfDay.SETTINGS.start_hour))
	assert_eq(TimeOfDay.weather, &"clear")


func test_advance_wraps_into_the_next_day() -> void:
	watch_signals(TimeOfDay)
	TimeOfDay.set_hour(23.5)
	TimeOfDay.advance(60.0)
	assert_eq(TimeOfDay.day, 2)
	assert_almost_eq(TimeOfDay.hour_decimal(), 0.5, 0.001)
	assert_signal_emitted(TimeOfDay, "hour_changed")
	assert_eq(TimeOfDay.clock_text(), "Day 2, 00:30")


func test_twenty_minute_day() -> void:
	assert_almost_eq(TimeOfDay.SETTINGS.minutes_per_second() * TimeOfDay.SETTINGS.real_seconds_per_day, 1440.0, 0.01)
	TimeOfDay.running = true
	var before := TimeOfDay.total_minutes()
	TimeOfDay._process(10.0)
	TimeOfDay.running = false
	assert_almost_eq(TimeOfDay.total_minutes() - before, 10.0 * 1440.0 / 1200.0, 0.01, "10 s = 12 game minutes")


func test_night_hours() -> void:
	TimeOfDay.set_hour(22.0)
	assert_true(TimeOfDay.is_night())
	TimeOfDay.set_hour(4.0)
	assert_true(TimeOfDay.is_night())
	TimeOfDay.set_hour(12.0)
	assert_false(TimeOfDay.is_night())


func test_weather_rolls_every_few_hours() -> void:
	watch_signals(TimeOfDay)
	TimeOfDay.rng.seed = 3
	for i in 12:
		TimeOfDay.advance(TimeOfDay.SETTINGS.weather_change_hours * 60.0)
	assert_signal_emitted(TimeOfDay, "weather_changed", "some rain or fog in 36 game hours")
	assert_has(TimeOfDay.SETTINGS.weather_ids, TimeOfDay.weather)
	var total := 0.0
	for chance in TimeOfDay.SETTINGS.weather_chances:
		total += chance
	assert_almost_eq(total, 1.0, 0.001, "chances add up to 1")


func test_save_round_trip() -> void:
	TimeOfDay.advance(1000.0)
	TimeOfDay.set_weather(&"rain")
	var json := JSON.stringify(TimeOfDay.to_dict())
	TimeOfDay.reset()
	TimeOfDay.from_dict(JSON.parse_string(json))
	assert_eq(JSON.stringify(TimeOfDay.to_dict()), json)
	assert_eq(TimeOfDay.weather, &"rain")


func test_day_night_keyframes_are_consistent() -> void:
	var count := DAY_NIGHT.hours.size()
	assert_eq(DAY_NIGHT.hours[0], 0.0)
	assert_eq(DAY_NIGHT.hours[count - 1], 24.0)
	for i in count - 1:
		assert_lt(DAY_NIGHT.hours[i], DAY_NIGHT.hours[i + 1], "hours go up")
	for values: Variant in [DAY_NIGHT.light_colors, DAY_NIGHT.light_energy, DAY_NIGHT.ambient_energy, DAY_NIGHT.sky_top,
			DAY_NIGHT.sky_horizon]:
		assert_eq(values.size(), count, "one value per keyframe")


func test_sun_by_day_moon_by_night() -> void:
	assert_true(DAY_NIGHT.is_sun_up(12.0))
	assert_false(DAY_NIGHT.is_sun_up(23.0))
	assert_gt(DAY_NIGHT.sample_float(DAY_NIGHT.light_energy, 12.0), DAY_NIGHT.sample_float(DAY_NIGHT.light_energy, 0.0) * 3.0)
	assert_lt(DAY_NIGHT.light_rotation(12.0).x, DAY_NIGHT.light_rotation(7.0).x, "the sun is higher at noon")
	assert_eq(DAY_NIGHT.light_rotation(23.0).x, -DAY_NIGHT.moon_elevation_deg, "moonlight at night")
	var afternoon := DAY_NIGHT.light_rotation(15.0)
	assert_almost_eq(afternoon.x, -42.0, 3.0, "15:00 keeps the earlier afternoon look")
	assert_almost_eq(afternoon.y, 150.0, 3.0)
