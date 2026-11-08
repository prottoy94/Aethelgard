extends GutTest
## Phase 8b: the Gust Trial (FR-QST-03, FR-MAG-07; owner decision 2026-11-07): Lantern Glow reveals runes in the
## mist, Light lights them in order, a ring of wind seals the courtyard for two waves, and passing puts the Gust tome
## on the altar. Falling in the fight lowers the wind; the runes stay awake. Everything is remembered.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const GUST_TRIAL: TrialData = preload("res://data/trials/gust_trial.tres")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")

var world: Node3D
var player: Player


func before_all() -> void:
	CombatFx.hit_stop_enabled = false


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	get_tree().paused = false


func before_each() -> void:
	Inventory.reset()
	GameState.reset()
	QuestManager.reset()
	DragonManager.from_dict({})
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(-20, 0.05, 0)  # outside the courtyard
	world.add_child(player)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false


func _shrine() -> TrialShrine:
	var shrine := TrialShrine.new()
	shrine.data = GUST_TRIAL
	world.add_child(shrine)
	await wait_physics_frames(1)
	return shrine


func _wake_runes(shrine: TrialShrine) -> void:
	for rune in shrine.runes:
		rune.reveal()
		rune._grace = 0.0
	for rune in shrine.runes:  # in order
		rune.light_up()


func _defeat_all(shrine: TrialShrine) -> void:
	for enemy in shrine.alive.duplicate():
		enemy.health.apply_damage(DamageInfo.create(1000.0, Elements.Type.LIGHT, Vector3.ZERO, player))


func test_the_runes_hide_in_the_mist() -> void:
	var shrine := await _shrine()
	assert_eq(shrine.runes.size(), 3)
	for rune in shrine.runes:
		assert_true(rune.hidden, "hidden until Lantern Glow")
		assert_lt(rune.position.length(), GUST_TRIAL.radius, "inside the courtyard")
	var orders: Array[int] = []
	for rune in shrine.runes:
		orders.append(rune.order)
	assert_eq(orders, [1, 2, 3] as Array[int], "one curl, two, three")
	var nearest_way_in: TrialRune = shrine.runes.reduce(func(best: TrialRune, rune: TrialRune) -> TrialRune:
		return rune if rune.position.x < best.position.x else best)
	assert_eq(nearest_way_in.order, 2, "the first one met is not the first one to light")


func test_lantern_glow_reveals_a_rune_without_lighting_it() -> void:
	var shrine := await _shrine()
	var rune := shrine.runes[0]
	player.global_position = shrine.global_position + rune.position + Vector3(1.5, 0.05, 0)
	await wait_physics_frames(3)
	assert_true(player.try_cast(1), "Lantern Glow")
	await wait_physics_frames(3)
	assert_false(rune.hidden, "revealed")
	assert_false(rune.is_lit, "the same flash doesn't count as lighting it")
	rune._grace = 0.0
	rune._on_element_hit(Elements.Type.LIGHT, player.global_position)
	assert_true(rune.is_lit, "a Light Mote afterwards lights it")


func test_wrong_order_then_right_order_wakes_the_shrine() -> void:
	var shrine := await _shrine()
	for rune in shrine.runes:
		rune.reveal()
		rune._grace = 0.0
	shrine.runes[1].light_up()  # two first: wrong
	assert_false(shrine.runes[1].is_lit, "out again")
	assert_false(shrine.runes_awake())
	_wake_runes(shrine)
	assert_true(shrine.runes_awake(), "the puzzle is solved")
	assert_true(GameState.get_object_state(GUST_TRIAL.puzzle_id()).get("solved", false), "remembered")
	assert_false(shrine.fighting, "she lit them from outside: the wind waits for her")


func test_the_fight_two_waves_then_the_tome() -> void:
	var shrine := await _shrine()
	_wake_runes(shrine)
	player.global_position = shrine.global_position + Vector3(-3, 0.05, 0)
	await wait_physics_frames(3)
	assert_true(shrine.fighting, "walking in raises the ring of wind")
	assert_true(shrine.ring.is_up)
	assert_eq(shrine.alive.size(), GUST_TRIAL.waves[0].enemies.size(), "the first wave")
	_defeat_all(shrine)
	await wait_seconds(GUST_TRIAL.wave_delay + 0.3)
	assert_eq(shrine.wave_index, 1, "the second wave")
	assert_eq(shrine.alive.size(), GUST_TRIAL.waves[1].enemies.size())
	_defeat_all(shrine)
	await wait_seconds(GUST_TRIAL.wave_delay + 0.3)
	assert_true(shrine.is_passed(), "passed")
	assert_false(shrine.fighting)
	assert_false(shrine.ring.is_up, "the wind falls")
	var tome := shrine.get_node_or_null(^"Tome") as SpellTome
	assert_not_null(tome, "the Gust tome on the altar")
	assert_eq(tome.spell.id, &"gust")
	tome._on_taken(player)
	assert_has(PlayerData.tomes, &"gust", "carried, to read at a Lantern Shrine (FR-QST-03)")


func test_falling_lowers_the_wind_and_walking_in_starts_again() -> void:
	var shrine := await _shrine()
	_wake_runes(shrine)
	shrine.start_fight()
	assert_true(shrine.fighting)
	var first := shrine.alive.duplicate()
	player.respawned.emit()
	await wait_physics_frames(2)
	assert_false(shrine.fighting)
	assert_false(shrine.ring.is_up)
	for enemy in first:
		assert_false(is_instance_valid(enemy) and not enemy.is_queued_for_deletion(), "its enemies vanish")
	assert_true(shrine.runes_awake(), "the runes stay awake")
	shrine.start_fight()
	assert_true(shrine.fighting, "and it can be tried again")


func test_a_passed_trial_loads_passed() -> void:
	GameState.set_flag(GUST_TRIAL.passed_flag)
	GameState.set_object_state(GUST_TRIAL.puzzle_id(), {"solved": true})
	var shrine := await _shrine()
	assert_true(shrine.runes_awake())
	for rune in shrine.runes:
		assert_true(rune.is_lit)
	assert_not_null(shrine.get_node_or_null(^"Tome"), "the tome waits if it wasn't taken")
	shrine.start_fight()
	assert_false(shrine.fighting, "no second fight")
