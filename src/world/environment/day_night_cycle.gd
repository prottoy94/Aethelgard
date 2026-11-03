class_name DayNightCycle
extends Node3D
## Turns TimeOfDay into light (FR-WLD-06) and weather into rain and fog (FR-WLD-07): moves the sun by day and the moon
## by night, blends light colour, sky, ambient light and fog, and rains around `follow` (the player).
## A region creates one and gives it its sun, environment and sky material.

@export var data: DayNightData

var sun: DirectionalLight3D
var environment: Environment
var sky: ProceduralSkyMaterial
var follow: Node3D
## 0–1, fading towards the current weather.
var rain_amount := 0.0
var fog_amount := 0.0
var _rain: GPUParticles3D


func _ready() -> void:
	_rain = _build_rain()
	add_child(_rain)
	var settled := TimeOfDay.weather
	rain_amount = 1.0 if settled == &"rain" else 0.0
	fog_amount = 1.0 if settled == &"fog" else 0.0
	Settings.graphics_changed.connect(func(_preset: GraphicsPreset) -> void: _update_rain_amount())
	_update_rain_amount()
	apply(TimeOfDay.hour_decimal())


func _process(delta: float) -> void:
	var step := data.blend_speed * delta
	rain_amount = move_toward(rain_amount, 1.0 if TimeOfDay.weather == &"rain" else 0.0, step)
	fog_amount = move_toward(fog_amount, 1.0 if TimeOfDay.weather == &"fog" else 0.0, step)
	apply(TimeOfDay.hour_decimal())
	if follow and is_instance_valid(follow):
		_rain.global_position = follow.global_position + Vector3(0, 9.0, 0)
	_rain.emitting = rain_amount > 0.05
	_rain.amount_ratio = rain_amount


## Sets the light, sky and fog for `hour` and the current weather blend.
func apply(hour: float) -> void:
	var cloud := lerpf(1.0, data.rain_light, rain_amount)
	if sun:
		sun.rotation_degrees = data.light_rotation(hour)
		sun.light_color = data.sample_color(data.light_colors, hour)
		sun.light_energy = data.sample_float(data.light_energy, hour) * cloud
	if environment:
		environment.ambient_light_energy = data.sample_float(data.ambient_energy, hour) * lerpf(1.0, data.rain_ambient, rain_amount)
		var horizon := data.sample_color(data.sky_horizon, hour).lerp(data.rain_sky_tint, rain_amount * 0.5)
		environment.fog_light_color = horizon
		environment.fog_density = lerpf(lerpf(data.clear_fog, data.rain_fog, rain_amount), data.fog_fog, fog_amount)
		if sky:
			sky.sky_top_color = data.sample_color(data.sky_top, hour).lerp(data.rain_sky_tint, rain_amount * 0.6)
			sky.sky_horizon_color = horizon
			sky.ground_horizon_color = horizon


func _update_rain_amount() -> void:
	var detail := Settings.graphics.grass_density if Settings.graphics else 1.0
	_rain.amount = maxi(roundi(data.rain_drops * detail), 100)


func _build_rain() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.lifetime = 0.9
	particles.visibility_aabb = AABB(Vector3(-16, -14, -16), Vector3(32, 18, 32))
	particles.emitting = false
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(15, 0.5, 15)
	process.direction = Vector3(0.08, -1, 0.04)
	process.spread = 2.0
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 19.0
	process.gravity = Vector3(0, -9.8, 0)
	particles.process_material = process
	var drop := QuadMesh.new()
	drop.size = Vector2(0.02, 0.55)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.78, 0.86, 1.0, 0.45)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.billboard_keep_scale = true
	drop.material = material
	particles.draw_pass_1 = drop
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles
