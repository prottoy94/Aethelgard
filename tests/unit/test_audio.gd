extends GutTest
## The audio system (FR-AUD-01/03/05/07/08, NFR-AUD-03/04): every sound id the game uses exists, files are there
## (after tools/audio/generate_placeholders.py and import_owner_music.py), limits, music states and volumes.

const SPELLS: SpellLibrary = preload("res://data/spells/spell_library.tres")
const REGIONS: RegionLibrary = preload("res://data/world/regions.tres")
const ENEMY_PARTS: Array[String] = ["alert", "telegraph", "attack", "hurt", "death"]
const ENEMY_DATA: Array[String] = ["res://data/enemies/thornling.tres", "res://data/enemies/ember_wisp.tres"]

var _id_in_code := RegEx.create_from_string("AudioManager\\.(?:play|play_sfx|play_sfx_at|play_stinger|play_music|play_ambience|play_weather)\\(&\"([a-z0-9_]+)\"")


func before_each() -> void:
	AudioManager.stop_music(0.0)
	AudioManager.set_combat(false)
	AudioManager._calm_left = 0.0
	AudioManager._set_combat(false)


func _code_files(dir := "res://src") -> Array[String]:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			files.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		files.append_array(_code_files(dir.path_join(sub)))
	return files


func _known(id: StringName) -> bool:
	return AudioManager.has_sound(id) or AudioManager.MUSIC.find(id) != null


func test_every_literal_id_in_code_exists() -> void:
	var count := 0
	for path in _code_files():
		for found in _id_in_code.search_all(FileAccess.get_file_as_string(path)):
			var id := StringName(found.get_string(1))
			count += 1
			assert_true(_known(id), "%s uses %s" % [path.get_file(), id])
	assert_gt(count, 30, "the game plays plenty of sounds by id")


func test_ids_built_from_names_exist() -> void:
	for spell in SPELLS.spells:
		assert_true(AudioManager.has_sound(StringName("spell_%s_cast" % spell.id)), "cast sound for %s" % spell.id)
	for path in ENEMY_DATA:
		var data := load(path) as EnemyData
		for part in ENEMY_PARTS:
			assert_true(AudioManager.has_sound(StringName("enemy_%s_%s" % [data.id, part])), "%s %s" % [data.id, part])
	for surface in ["grass", "stone"]:
		assert_true(AudioManager.has_sound(StringName("player_footstep_%s" % surface)))
	for status in [StatusEffectComponent.BURN, StatusEffectComponent.CHILL, StatusEffectComponent.FREEZE,
			StatusEffectComponent.DAZE, StatusEffectComponent.EMBER_MARK]:
		assert_true(AudioManager.has_sound(StringName("combat_status_%s" % status)), "status %s" % status)
	for element in ["none", "light", "wind", "ember", "frost", "earth"]:
		assert_true(AudioManager.has_sound(StringName("combat_hit_%s" % element)), "hit %s" % element)
	for element: String in DragonTypes.ELEMENT_IDS:
		assert_true(AudioManager.has_sound(StringName("dragon_breath_%s" % element)), "%s dragon breath" % element)
	for id in GatherNode.GATHER_SOUNDS:
		assert_true(AudioManager.has_sound(id))


func test_region_music_and_ambience_exist() -> void:
	for region in REGIONS.regions:
		for id: StringName in [region.music_day, region.music_night, region.combat_layer, region.ambience_day,
				region.ambience_night]:
			if id != &"":
				assert_not_null(AudioManager.MUSIC.find(id), "%s: %s" % [region.id, id])
	assert_not_null(AudioManager.MUSIC.find(&"mus_title"), "the title song (FR-AUD-12)")


func test_files_are_in_place() -> void:
	var missing: Array[String] = []
	for event in AudioManager.library.events:
		assert_false(event.files.is_empty(), "%s has files" % event.id)
		for file in event.files:
			if not ResourceLoader.exists(file):
				missing.append(file)
	for track in AudioManager.MUSIC.tracks:
		if not ResourceLoader.exists(track.file):
			missing.append(track.file)
	if not missing.is_empty():
		fail_test("missing audio (run tools/audio/generate_placeholders.py and import_owner_music.py): %s" % missing[0])
	assert_eq(missing.size(), 0)


func test_unknown_ids_are_harmless() -> void:
	assert_false(AudioManager.play(&"no_such_sound"))
	AudioManager.play_music(&"no_such_track", 0.0)
	assert_eq(AudioManager.current_music(), &"")


func test_polyphony_and_interval_limits() -> void:
	var event := AudioManager.library.find(&"combat_hit_none")
	assert_true(AudioManager.play(&"combat_hit_none"))
	assert_false(AudioManager.play(&"combat_hit_none"), "re-trigger faster than min_interval is ignored (FR-AUD-05)")
	for i in event.max_polyphony + 3:
		AudioManager._last_played.erase(&"combat_hit_none")
		AudioManager.play(&"combat_hit_none", Vector3(i, 0, 0))
	var playing: Array = AudioManager._voices.get(&"combat_hit_none", []).filter(func(p: Node) -> bool: return p.get(&"playing"))
	assert_lte(playing.size(), event.max_polyphony, "at most %d at once" % event.max_polyphony)


func test_variants_and_random_pitch() -> void:
	var event := AudioManager.library.find(&"player_footstep_grass")
	assert_gte(event.files.size(), 3, "footsteps have variants (FR-AUD-05)")
	assert_lt(event.pitch_range.x, event.pitch_range.y)


func test_combat_layer_comes_and_goes() -> void:
	AudioManager.play_music(&"mus_elderroot_explore", 0.0)
	AudioManager.set_combat_layer(&"mus_elderroot_combat")
	assert_eq(AudioManager.current_music(), &"mus_elderroot_explore")
	AudioManager.set_combat(true)
	assert_true(AudioManager.in_combat, "an enemy noticed Aurelia (FR-AUD-07)")
	AudioManager.set_combat(false)
	assert_true(AudioManager.in_combat, "stays a few seconds after the last enemy")
	AudioManager._process(AudioManager.TUNING.calm_delay + 0.1)
	assert_false(AudioManager.in_combat)


func test_ducking_combines_reasons() -> void:
	AudioManager.duck(&"dialogue", -6.0)
	AudioManager.duck(&"stinger", -9.0)
	assert_eq(AudioManager._duck_level(), -9.0, "the deepest wins")
	AudioManager.duck(&"stinger", 0.0)
	assert_eq(AudioManager._duck_level(), -6.0)
	AudioManager.duck(&"dialogue", 0.0)
	assert_eq(AudioManager._duck_level(), 0.0)


func test_volume_settings() -> void:
	Settings.persist = false
	var before: float = Settings.volumes[&"Music"]
	Settings.set_volume(&"Music", 0.5)
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))), 0.5, 0.01)
	Settings.set_volume(&"Music", before)
	Settings.persist = true


func test_telegraph_sounds_match_the_wind_up() -> void:
	for path in ENEMY_DATA:
		var data := load(path) as EnemyData
		var event := AudioManager.library.find(StringName("enemy_%s_telegraph" % data.id))
		var stream := load(event.files[0]) as AudioStream if ResourceLoader.exists(event.files[0]) else null
		if stream == null:
			pending("placeholder sounds not generated")
			return
		assert_almost_eq(stream.get_length(), data.telegraph_time, 0.15, "%s wind-up sound lasts as long (FR-AUD-03)" % data.id)
