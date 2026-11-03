extends GutTest
## Real fights in a small physics world: the player's strike and spells hit a Thornling; the Thornling's
## telegraphed attack hurts the player unless she dashes; defeat, respawn and enemy death.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const THORNLING_SCENE := preload("res://src/actors/enemies/thornling/thornling.tscn")

var world: Node3D
var player: Player


func before_all() -> void:
	CombatFx.hit_stop_enabled = false


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Engine.time_scale = 1.0


func before_each() -> void:
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


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _thornling(pos: Vector3, passive := true) -> Enemy:
	var thornling: Enemy = THORNLING_SCENE.instantiate()
	thornling.position = pos
	world.add_child(thornling)
	if passive:
		thornling.state_machine.set_physics_process(false)  # stands still; the test controls it
	return thornling


func _face(direction: Vector3) -> void:
	player.face_instantly(direction)
	player._mouse_aim = false  # aim = facing (no mouse in tests)


func test_staff_strike_hits_enemy_in_front() -> void:
	var enemy := _thornling(Vector3(0, 0, -1.4))
	await wait_physics_frames(3)
	_face(Vector3.FORWARD)
	player.request_strike()
	await wait_physics_frames(20)
	assert_almost_eq(enemy.health.current, enemy.data.max_health - player.combat.strike_damage, 0.01)
	assert_false(player.strike_hitbox.is_active(), "hit window closed")


func test_strike_misses_enemy_behind() -> void:
	var enemy := _thornling(Vector3(0, 0, 1.4))
	await wait_physics_frames(3)
	_face(Vector3.FORWARD)
	player.request_strike()
	await wait_physics_frames(20)
	assert_eq(enemy.health.current, enemy.data.max_health)


func test_light_mote_flies_and_hits() -> void:
	var enemy := _thornling(Vector3(0.8, 0, -7))
	await wait_physics_frames(3)
	_face(Vector3.FORWARD)
	assert_true(player.try_cast(0), "Light Mote cast")
	assert_eq(player.stamina.current, player.combat.max_stamina - 8.0)
	await wait_physics_frames(45)
	# Light vs Earth is neutral: 12 damage.
	assert_almost_eq(enemy.health.current, enemy.data.max_health - 12.0, 0.01, "homing bolt hit")


func test_gust_knocks_back_and_staggers() -> void:
	var enemy := _thornling(Vector3(0, 0, -2.5), false)
	await wait_physics_frames(3)
	_face(Vector3.FORWARD)
	var start_z := enemy.global_position.z
	assert_true(player.try_cast(1), "Gust cast")
	await wait_physics_frames(2)
	assert_true(enemy.state_machine.is_in(&"Stagger"), "staggered")
	# Wind vs Earth is strong: 4 × 1.5 = 6 damage.
	assert_almost_eq(enemy.health.current, enemy.data.max_health - 6.0, 0.01)
	await wait_physics_frames(20)
	assert_lt(enemy.global_position.z, start_z - 1.0, "pushed away from Aurelia")


func test_thornling_telegraphs_then_hits() -> void:
	var enemy := _thornling(Vector3(0, 0, -1.6), false)
	await wait_physics_frames(10)
	assert_true(enemy.state_machine.is_in(&"Telegraph"), "winds up first (FR-CMB-05)")
	assert_eq(player.health.current, player.combat.max_health, "no damage during the warning")
	await wait_physics_frames(int(enemy.data.telegraph_time * 60) + 10)
	assert_almost_eq(player.health.current, player.combat.max_health - enemy.data.attack_damage, 0.01, "hit after the warning")
	assert_true(player.is_invulnerable, "brief protection after being hurt")


func test_dash_through_the_attack_avoids_damage() -> void:
	var enemy := _thornling(Vector3(0, 0, -1.6), false)
	await wait_physics_frames(10)
	assert_true(enemy.state_machine.is_in(&"Telegraph"))
	# Wait until just before the hit, then dash.
	await wait_physics_frames(int(enemy.data.telegraph_time * 60) - 18)
	player.request_dash()
	await wait_physics_frames(25)
	assert_eq(player.health.current, player.combat.max_health, "i-frames avoided the hit")


func test_defeat_and_respawn_keeps_going() -> void:
	player.respawn_point = Vector3(5, 0.05, 5)
	watch_signals(player)
	player.health.apply_damage(DamageInfo.create(999.0, Elements.Type.NONE, Vector3.ZERO, null))
	await wait_physics_frames(2)
	assert_true(player.state_machine.is_in(&"Dead"))
	assert_false(player.try_cast(0), "no casting while defeated")
	await wait_physics_frames(int(player.combat.respawn_delay * 60) + 10)
	assert_signal_emitted(player, "respawned")
	assert_eq(player.health.current, player.combat.max_health)
	assert_almost_eq(player.global_position.x, 5.0, 0.2, "back at the respawn point")


func test_enemy_dies_and_is_removed() -> void:
	var enemy := _thornling(Vector3(0, 0, -3))
	await wait_physics_frames(2)
	enemy.state_machine.set_physics_process(true)
	watch_signals(enemy)
	enemy.hurtbox.receive_hit(DamageInfo.create(999.0, Elements.Type.NONE, Vector3.ZERO, player))
	assert_signal_emitted(enemy, "defeated")
	assert_true(enemy.state_machine.is_in(&"Dead"))
	await wait_physics_frames(90)
	assert_false(is_instance_valid(enemy), "removed after the death effect")
