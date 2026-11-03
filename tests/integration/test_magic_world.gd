extends GutTest
## Phase 4 in a physics world: tomes (incl. a hidden one revealed by Lantern Glow), resting at a Lantern Shrine,
## rank-up bonuses, Mending Bloom healing, the Ember Wisp's Burning bolt, and the Grimoire.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const WISP_SCENE := preload("res://src/actors/enemies/ember_wisp/ember_wisp.tscn")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")
const GUST := preload("res://data/spells/gust.tres")
const MENDING_BLOOM := preload("res://data/spells/mending_bloom.tres")

var world: Node3D
var player: Player


func before_all() -> void:
	CombatFx.hit_stop_enabled = false


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Engine.time_scale = 1.0
	get_tree().paused = false


func before_each() -> void:
	Inventory.reset()
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])
	GameState.reset()
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
	await wait_physics_frames(3)


func _tome(spell: SpellData, pos: Vector3, hidden := false) -> SpellTome:
	var tome := SpellTome.new()
	tome.spell = spell
	tome.persist_id = StringName("test_tome_%s" % spell.id)
	tome.hidden = hidden
	tome.position = pos
	world.add_child(tome)
	return tome


func test_take_a_tome() -> void:
	_tome(GUST, Vector3(0, 0, -1))
	await wait_physics_frames(5)
	assert_true(player.try_interact(), "tome in reach")
	assert_eq(PlayerData.tomes, [&"gust"] as Array[StringName])
	assert_true(GameState.get_object_state(&"test_tome_gust").get("taken", false), "remembered as taken")
	await wait_physics_frames(30)
	_tome(GUST, Vector3(0, 0, -1))  # a fresh copy of the same tome
	await wait_physics_frames(2)
	assert_false(player.try_interact(), "an already-taken tome doesn't come back")


func test_hidden_tome_needs_lantern_glow() -> void:
	var tome := _tome(MENDING_BLOOM, Vector3(0, 0, -1), true)
	await wait_physics_frames(5)
	assert_false(player.try_interact(), "hidden: can't be taken yet")
	assert_true(player.try_cast(1), "Lantern Glow cast")
	await wait_physics_frames(5)
	assert_false(tome.hidden, "revealed by the light")
	assert_true(player.try_interact(), "now it can be taken")
	assert_has(PlayerData.tomes, &"mending_bloom")


func test_rest_at_shrine_heals_respawns_and_reads_tomes() -> void:
	var shrine := RestPoint.new()
	shrine.position = Vector3(0, 0, -1.2)
	world.add_child(shrine)
	watch_signals(shrine)
	PlayerData.add_tome(GUST)
	PlayerData.add_tome(MENDING_BLOOM)
	player.health.apply_damage(DamageInfo.create(40.0, Elements.Type.NONE, Vector3.ZERO, null))
	await wait_physics_frames(5)
	assert_true(player.try_interact(), "shrine in reach")
	assert_signal_emitted(shrine, "rested")
	assert_eq(player.health.current, player.health.max_health, "healed")
	assert_almost_eq(player.respawn_point, shrine.respawn_position(), Vector3.ONE * 0.01)
	assert_true(PlayerData.knows(&"gust"), "Gust learned (26 MP)")
	assert_true(PlayerData.knows(&"mending_bloom"), "...which unlocked Mending Bloom (needs 20)")
	assert_eq(player.spell_caster.loadout[2], GUST, "new spell placed in a free slot")


func test_rank_up_raises_max_stamina_and_health() -> void:
	var stamina_before := player.stamina.max_stamina
	var health_before := player.health.max_health
	PlayerData.set_equipment_power(40)  # 54 MP: rank E
	assert_eq(player.stamina.max_stamina, stamina_before + PlayerData.PROGRESSION.stamina_bonus_per_rank)
	assert_eq(player.health.max_health, health_before + PlayerData.PROGRESSION.health_bonus_per_rank)
	assert_eq(player.health.current, player.health.max_health, "the bonus is added straight away")


func test_mending_bloom_heals_over_time() -> void:
	PlayerData.learn(GUST)
	PlayerData.learn(MENDING_BLOOM)
	await wait_physics_frames(2)
	var slot := player.spell_caster.loadout.find(MENDING_BLOOM)
	assert_ne(slot, -1)
	player.health.apply_damage(DamageInfo.create(50.0, Elements.Type.NONE, Vector3.ZERO, null))
	assert_true(player.try_cast(slot))
	await wait_process_frames(30)
	var mid := player.health.current
	assert_between(mid, 50.0, 50.0 + MENDING_BLOOM.base_damage, "healing part-way")
	await wait_seconds(MENDING_BLOOM.duration)
	var expected := 50.0 + MENDING_BLOOM.base_damage * PlayerData.modifiers_for(MENDING_BLOOM).damage
	assert_almost_eq(player.health.current, minf(expected, player.health.max_health), 0.5, "full heal amount over the duration")


func test_casting_earns_mastery() -> void:
	assert_true(player.try_cast(0))
	await wait_process_frames(2)
	assert_eq(int(PlayerData.learned[&"light_mote"]["xp"]), PlayerData.PROGRESSION.xp_per_cast)


func test_ember_wisp_telegraphs_and_burns() -> void:
	var wisp: Enemy = WISP_SCENE.instantiate()
	wisp.position = Vector3(0, 0, -6)
	world.add_child(wisp)
	await wait_physics_frames(10)
	assert_true(wisp.state_machine.is_in(&"Telegraph"), "aims first (FR-CMB-05)")
	assert_eq(player.health.current, player.health.max_health)
	await wait_seconds(wisp.data.telegraph_time + 1.0)
	assert_lt(player.health.current, player.health.max_health, "the ember bolt hit")
	assert_true(player.status_effects.has(StatusEffectComponent.BURN), "and set Aurelia Burning")


func test_light_is_strong_against_ember() -> void:
	var wisp: Enemy = WISP_SCENE.instantiate()
	wisp.position = Vector3(0, 0, -6)
	world.add_child(wisp)
	await wait_physics_frames(2)
	wisp.state_machine.set_physics_process(false)
	player.face_instantly(Vector3.FORWARD)
	player._mouse_aim = false
	assert_true(player.try_cast(0))
	await wait_physics_frames(40)
	var expected := 12.0 * PlayerData.modifiers_for(LIGHT_MOTE).damage * Elements.STRONG
	assert_almost_eq(wisp.health.current, wisp.data.max_health - expected, 0.05, "Light vs Ember × 1.5")


func test_grimoire_pauses_and_assigns_slots() -> void:
	PlayerData.learn(GUST)
	var grimoire := Grimoire.new()
	add_child_autofree(grimoire)
	grimoire.open()
	assert_true(get_tree().paused, "game paused while reading")
	grimoire.select(&"gust")
	grimoire.assign(0)
	assert_eq(PlayerData.loadout[0], &"gust")
	assert_eq(player.spell_caster.loadout[0], GUST, "the player's slot follows")
	grimoire.close()
	assert_false(get_tree().paused)
