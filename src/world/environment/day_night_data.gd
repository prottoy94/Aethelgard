class_name DayNightData
extends Resource
## How light, sky and fog look through the day (TECHNICAL_DESIGN.md §4.8: dawn gold → day → dusk violet → night blue
## moonlight) and in each weather. Keyframes at `hours`; values in between are blended. File: data/world/day_night.tres.

@export_group("Keyframes")
@export var hours: PackedFloat32Array = []          ## ascending, from 0 to 24
@export var light_colors: PackedColorArray = []     ## sun by day, moon by night
@export var light_energy: PackedFloat32Array = []
@export var ambient_energy: PackedFloat32Array = []
@export var sky_top: PackedColorArray = []
@export var sky_horizon: PackedColorArray = []

@export_group("Sun & moon path")
@export var sunrise_hour := 6.0
@export var sunset_hour := 19.5
@export var max_elevation_deg := 50.0
@export var sunrise_yaw_deg := 60.0
@export var sunset_yaw_deg := 195.0
@export var moon_elevation_deg := 38.0
@export var moon_yaw_deg := -40.0

@export_group("Weather")
@export var clear_fog := 0.004          ## fog density
@export var rain_fog := 0.014
@export var fog_fog := 0.016
@export var rain_light := 0.45          ## light energy multiplier under rain clouds
@export var rain_ambient := 0.8
@export var rain_sky_tint := Color(0.55, 0.6, 0.68)
@export var blend_speed := 0.25         ## weather changes fade in over ~1 / this seconds
@export var rain_drops := 1600          ## particles at the High preset


## The value of `values` at `hour`, blended between the two nearest keyframes.
func sample_float(values: PackedFloat32Array, hour: float) -> float:
	var i := _segment(hour)
	return lerpf(values[i], values[i + 1], _weight(hour, i))


func sample_color(values: PackedColorArray, hour: float) -> Color:
	var i := _segment(hour)
	return values[i].lerp(values[i + 1], _weight(hour, i))


## True between sunrise and sunset (the light is the sun), otherwise the moon.
func is_sun_up(hour: float) -> bool:
	return hour >= sunrise_hour and hour <= sunset_hour


## Light rotation in degrees (x = −elevation, y = yaw) for a DirectionalLight3D.
func light_rotation(hour: float) -> Vector3:
	if not is_sun_up(hour):
		return Vector3(-moon_elevation_deg, moon_yaw_deg, 0.0)
	var t := (hour - sunrise_hour) / (sunset_hour - sunrise_hour)
	var elevation := maxf(sin(t * PI) * max_elevation_deg, 4.0)
	return Vector3(-elevation, lerpf(sunrise_yaw_deg, sunset_yaw_deg, t), 0.0)


func _segment(hour: float) -> int:
	var h := clampf(hour, hours[0], hours[hours.size() - 1])
	for i in hours.size() - 1:
		if h <= hours[i + 1]:
			return i
	return hours.size() - 2


func _weight(hour: float, i: int) -> float:
	var span := hours[i + 1] - hours[i]
	return clampf((hour - hours[i]) / span, 0.0, 1.0) if span > 0.0 else 0.0
