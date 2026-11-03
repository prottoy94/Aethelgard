extends GutTest
## Graphics presets: Low → High must get strictly more expensive, and applying them sets the right values.


func _presets() -> Array[GraphicsPreset]:
	return Settings.get_graphics_presets()


func test_three_presets_load_in_order() -> void:
	var ids: Array[StringName] = []
	for preset in _presets():
		assert_not_null(preset)
		ids.append(preset.id)
	assert_eq(ids, [&"low", &"medium", &"high"] as Array[StringName])


func test_presets_scale_up_in_cost() -> void:
	var p := _presets()
	for i in range(1, p.size()):
		assert_gte(p[i].render_scale, p[i - 1].render_scale, "render scale rises: %s" % p[i].id)
		assert_gte(p[i].shadow_distance, p[i - 1].shadow_distance, "shadow distance rises: %s" % p[i].id)
		assert_gte(p[i].grass_density, p[i - 1].grass_density, "grass density rises: %s" % p[i].id)
	assert_eq(p[-1].render_scale, 1.0, "High renders at full resolution")


func test_apply_to_environment_and_sun() -> void:
	var low := _presets()[0]
	var env := Environment.new()
	env.ssao_enabled = true
	low.apply_to_environment(env)
	assert_eq(env.ssao_enabled, low.ssao)
	var sun: DirectionalLight3D = autofree(DirectionalLight3D.new())
	low.apply_to_sun(sun)
	assert_eq(sun.directional_shadow_max_distance, low.shadow_distance)


func test_visible_grass() -> void:
	var low := _presets()[0]
	assert_eq(low.visible_grass(1000), roundi(1000 * low.grass_density))
	assert_eq(_presets()[-1].visible_grass(1000), 1000)


func test_settings_switches_preset_and_signals() -> void:
	watch_signals(Settings)
	Settings.set_graphics_preset(&"medium")
	assert_eq(Settings.graphics.id, &"medium")
	assert_signal_emitted(Settings, "graphics_changed")
	Settings.set_graphics_preset(&"high")
