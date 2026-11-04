extends GutTest
## Phase 8a: enemies with several moves (the Emberbound Scout), the boss framework (phases, arena, rewards, reset)
## and the Cinder Warden (FR-BOS-01/02, FR-CMB-05, FR-AUD-03).

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const SCOUT_SCENE := preload("res://src/actors/enemies/emberbound/emberbound_scout.tscn")
const WARDEN_SCENE := preload("res://src/actors/bosses/cinder_warden/cinder_warden.tscn")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const MOVE_ENEMIES: Array[String] = ["res://data/enemies/emberbound_scout.tres", "res://data/bosses/cinder_warden.tres"]

var world: Node3D
var player: Player


func before_all() -> void:
	CombatFx.hit_stop_enabled = false


func after_all() -> void:
	CombatFx.hit_stop_enabled = true


func before_each() -> void:
	Inventory.reset()
	GameState.reset()
	QuestManager.reset()
	DragonManager.from_dict({})
	PlayerData.reset([LIGHT_MOTE] as Array[SpellData])
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.05, 0)
	world.add_child(player)
	await wait_physics_frames(2)


func _arena(at := Vector3(0, 0, -20)) -> BossArena:
	var arena := BossArena.new()
	arena.boss_scene = WARDEN_SCENE
	arena.radius = 10.0
	arena.position = at
	world.add_child(arena)
	return arena


func _all_moves(data: EnemyData) -> Array[EnemyMoveData]:
	var moves: Array[EnemyMoveData] = []
	moves.append_array(data.moves)
	var boss := data as BossData
	if boss:
		for phase in boss.phases:
			for move in phase.moves:
				if not move in moves:
					moves.append(move)
	return moves


func test_scout_picks_a_move_for_the_distance() -> void:
	var scout: Enemy = SCOUT_SCENE.instantiate()
	world.add_child(scout)
	scout.state_machine.set_physics_process(false)
	assert_eq(scout.pick_move(1.5).id, &"slash", "sword up close")
	assert_eq(scout.pick_move(5.0).id, &"fire_dash", "fire dash from afar")
	assert_null(scout.pick_move(15.0), "nothing that far")


func test_scout_fire_dash_warns_then_dashes_and_burns() -> void:
	var scout: Enemy = SCOUT_SCENE.instantiate()
	scout.position = Vector3(0, 0, -5)
	world.add_child(scout)
	await wait_physics_frames(2)
	scout.current_move = scout.find_move(&"fire_dash")
	scout.state_machine.transition_to(&"Telegraph")
	await wait_physics_frames(5)
	assert_true(scout._marker.visible, "a lane on the ground shows the dash (FR-CMB-05)")
	assert_true(scout.is_in_group(&"danger_zone"))
	var start := scout.global_position
	await wait_seconds(scout.current_move.telegraph_time + scout.current_move.active_time + 0.1)
	assert_gt(scout.global_position.distance_to(start), 3.0, "it dashed")
	assert_lt(player.health.current, player.health.max_health, "and hit Aurelia standing in the lane")
	assert_true(player.status_effects.has(StatusEffectComponent.BURN))


func test_a_sweep_misses_behind_it() -> void:
	var hitbox := HitboxComponent.new()
	hitbox.team = HurtboxComponent.Team.ENEMY
	var source := Node3D.new()
	world.add_child(source)
	source.global_position = Vector3(0, 0, 1.5)  # Aurelia is in front of it (towards -Z)...
	hitbox.source = source
	hitbox.arc_deg = 120.0
	hitbox.arc_forward = Vector3(0, 0, 1)        # ...but it sweeps the other way
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.0
	shape.shape = sphere
	hitbox.add_child(shape)
	source.add_child(hitbox)
	hitbox.activate()
	await wait_physics_frames(4)
	assert_eq(player.health.current, player.health.max_health, "outside the arc: no hit")


func test_warden_phases_follow_its_health() -> void:
	var arena := _arena()
	await wait_physics_frames(2)
	var warden := arena.boss
	warden.state_machine.set_physics_process(false)
	arena.start_fight()
	assert_eq(warden.phase_index, 0)
	assert_null(warden.find_move(&"cinder_ring"), "no fire ring yet")
	warden.health.apply_damage(DamageInfo.create(warden.health.max_health * 0.45, Elements.Type.NONE, Vector3.ZERO, null))
	assert_eq(warden.phase_index, 1, "phase 2 at 60% (FR-BOS-01)")
	assert_eq(warden.current_move.id, &"call_wisps", "it opens the phase by calling wisps")
	assert_not_null(warden.find_move(&"cinder_ring"))
	warden.health.apply_damage(DamageInfo.create(warden.health.max_health * 0.3, Elements.Type.NONE, Vector3.ZERO, null))
	assert_eq(warden.phase_index, 2, "phase 3 at 30%")
	assert_not_null(warden.find_move(&"ember_volley"))


func test_arena_seals_and_rewards_the_win() -> void:
	var arena := _arena()
	await wait_physics_frames(2)
	watch_signals(arena)
	arena.start_fight()
	await wait_physics_frames(2)
	assert_true(arena.fighting)
	assert_false(arena._wall_shapes[0].disabled, "the ring of fire blocks the way out (FR-BOS-02)")
	assert_eq(AudioManager.current_music(), &"mus_boss_ascent", "boss music")
	var warden := arena.boss
	warden.health.apply_damage(DamageInfo.create(9999.0, Elements.Type.NONE, Vector3.ZERO, null))
	await wait_physics_frames(3)
	assert_false(arena.fighting)
	assert_true(arena._wall_shapes[0].disabled, "the fire lowers")
	assert_true(GameState.has_flag(&"warden_defeated"), "it stays beaten")
	assert_eq(Inventory.count(&"ember_core"), 1, "Ember Core #1 (approved 2026-11-04)")
	assert_true(Inventory.knows_recipe(&"ember_ward_ring"))
	assert_signal_emitted_with_parameters(arena, "fight_ended", [true])


func test_falling_resets_the_boss() -> void:
	var arena := _arena()
	await wait_physics_frames(2)
	arena.start_fight()
	var warden := arena.boss
	warden.health.apply_damage(DamageInfo.create(warden.health.max_health * 0.5, Elements.Type.NONE, Vector3.ZERO, null))
	await wait_seconds(1.4)  # the summon's warning, then the wisps
	assert_gt(warden.helpers.size(), 0, "phase 2 called wisps")
	player.respawn()
	await wait_physics_frames(2)
	assert_false(arena.fighting)
	assert_eq(warden.health.current, warden.health.max_health, "back to full (GDD §7)")
	assert_eq(warden.phase_index, 0)
	assert_true(warden.helpers.is_empty(), "its wisps are gone")


func test_a_beaten_boss_does_not_come_back() -> void:
	GameState.set_flag(&"warden_defeated")
	var arena := _arena()
	await wait_physics_frames(2)
	assert_null(arena.boss)
	assert_true(arena.is_beaten())


func test_every_move_has_matching_sounds_and_sane_phases() -> void:
	for path in MOVE_ENEMIES:
		var data := load(path) as EnemyData
		for part in ["alert", "hurt", "death"]:
			assert_true(AudioManager.has_sound(StringName("enemy_%s_%s" % [data.id, part])), "%s %s" % [data.id, part])
		for move in _all_moves(data):
			var id := StringName("enemy_%s_%s_telegraph" % [data.id, move.id])
			assert_true(AudioManager.has_sound(id), String(id))
			assert_true(AudioManager.has_sound(StringName("enemy_%s_%s" % [data.id, move.id])), "%s hit sound" % move.id)
			var event := AudioManager.library.find(id)
			if event and ResourceLoader.exists(event.files[0]):
				var stream := load(event.files[0]) as AudioStream
				assert_almost_eq(stream.get_length(), move.telegraph_time, 0.15, "%s lasts as long as its warning (FR-AUD-03)" % id)
			assert_gt(move.telegraph_time, 0.5, "%s warns long enough to dodge" % move.id)
			if move.follow_up != &"":
				assert_true(_all_moves(data).any(func(m: EnemyMoveData) -> bool: return m.id == move.follow_up))
		var boss := data as BossData
		if boss:
			assert_ne(boss.defeat_flag, &"")
			var last := 1.01
			for phase in boss.phases:
				assert_lt(phase.health_ratio, last, "phases go down in HP order")
				last = phase.health_ratio
