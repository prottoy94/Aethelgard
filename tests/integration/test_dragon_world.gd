extends GutTest
## Phase 7 in a physics world: the pet dragon follows Aurelia and comes back when left behind, fights enemies that
## come after her (and distracts them), guards her, goes after her target, uses its breath (which also lights a
## brazier), keeps out of telegraph rings, gets knocked out and comes back; the Elder gives the egg; the hatching
## scene with element choice and naming; the HUD panel and the Dragon page (FR-DRG-01/02/03/05/06/07, FR-DLG-09,
## FR-UI-02/04).

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const THORNLING_SCENE := preload("res://src/actors/enemies/thornling/thornling.tscn")
const WISP_SCENE := preload("res://src/actors/enemies/ember_wisp/ember_wisp.tscn")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const VILLAGERS := preload("res://dialogue/npcs/elderroot_villagers.dialogue")
const TREAT := preload("res://data/items/dragon_treat.tres")
const TUNING: DragonTuning = preload("res://data/dragons/dragon_tuning.tres")
const MAX_STEPS := 600  ## × 2 physics frames: long enough for the hatching scene's effects

var world: Node3D
var player: Player
var box: DialogueBox
var _old_speed := 1


func before_all() -> void:
	CombatFx.hit_stop_enabled = false
	Settings.persist = false
	_old_speed = Settings.text_speed


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Settings.text_speed = _old_speed
	Settings.persist = true
	get_tree().paused = false


func before_each() -> void:
	Settings.text_speed = 3  # instant text
	Settings.auto_advance = false
	Inventory.reset()
	GameState.reset()
	QuestManager.reset()
	TimeOfDay.reset()
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
	player._mouse_aim = false  # aim = facing (no mouse in tests)
	box = DialogueBox.new()
	world.add_child(box)
	await wait_physics_frames(3)


func after_each() -> void:
	get_tree().paused = false
	TimeOfDay.running = false
	Cutscene.clear()
	DragonManager.from_dict({})


func _dragon(element := "frost") -> Dragon:
	DragonManager.receive_egg()
	DragonManager.choose_element(element)
	DragonManager.hatch()
	return Dragon.spawn(world, player)


func _thornling(pos: Vector3, still := true) -> Enemy:
	var thornling: Enemy = THORNLING_SCENE.instantiate()
	thornling.position = pos
	world.add_child(thornling)
	if still:
		thornling.state_machine.set_physics_process(false)  # stands still; the test controls it
	return thornling


## Walks the conversation forward: picks choice `pick` when there are choices and types `name` into a name box.
func _talk_through(pick: int, name_text := "") -> void:
	for i in MAX_STEPS:
		await wait_physics_frames(2)
		if Cutscene.is_asking():
			Cutscene.submit_text(name_text)
		elif not box.is_open() and not Cutscene.is_playing():
			return
		elif box.line and not box.line.responses.is_empty():
			box.choose(pick)
		else:
			box.advance()
	fail_test("the conversation did not end")


func test_follows_aurelia_and_comes_back_when_left_behind() -> void:
	var dragon := _dragon()
	await wait_physics_frames(2)
	player.global_position = Vector3(0, 0.05, -7)
	await wait_seconds(2.0)
	assert_lt(dragon.distance_to_player(), TUNING.follow_restart + 0.3, "walked after her")
	assert_true(dragon.state_machine.is_in(&"Follow"))
	player.global_position = Vector3(40, 0.05, 0)
	await wait_physics_frames(3)
	assert_lt(dragon.distance_to_player(), TUNING.follow_distance + 0.5, "appeared beside her (leash)")


func test_follow_bites_an_enemy_that_comes_after_aurelia() -> void:
	var dragon := _dragon()
	var enemy := _thornling(Vector3(0, 0, -3), false)
	await wait_seconds(0.3)
	assert_true(enemy.is_engaged(), "the thornling is after Aurelia")
	assert_false(dragon.interactable.monitorable, "no petting prompt in a fight (E stays free)")
	var before := enemy.health.current
	await wait_seconds(2.5)
	assert_lt(enemy.health.current, before, "the dragon bit it (FR-DRG-02)")
	assert_true(enemy.is_distracted() or enemy.health.is_dead(), "and it turned on the dragon for a moment")


func test_attack_goes_after_aurelias_target() -> void:
	var dragon := _dragon()
	DragonManager.set_command(DragonTypes.Command.ATTACK)
	var near := _thornling(Vector3(2, 0, 0))
	var far := _thornling(Vector3(-6, 0, -6))
	player.remember_target(far)
	await wait_physics_frames(3)
	assert_eq(dragon.pick_target(), far, "her target, not the closest one")
	assert_true(dragon.state_machine.is_in(&"Attack"))
	assert_eq(dragon.target, far)
	player.combat_target = null
	player.face_instantly(Vector3(1, 0, 0))
	assert_eq(dragon.aimed_enemy(), near, "otherwise the one she aims at")


func test_guard_stands_between_aurelia_and_danger() -> void:
	var dragon := _dragon("earth")
	DragonManager.set_command(DragonTypes.Command.GUARD)
	var wisp: Enemy = WISP_SCENE.instantiate()
	wisp.position = Vector3(0, 0, -8)
	world.add_child(wisp)
	wisp.state_machine.set_physics_process(false)
	wisp.state_machine.transition_to(&"Chase")
	await wait_seconds(1.5)
	assert_true(dragon.state_machine.is_in(&"Guard"))
	var side := dragon.global_position - player.global_position
	side.y = 0.0
	assert_lt(side.length(), TUNING.guard_distance + 0.5, "stays at her side")
	assert_gt(side.normalized().dot(Vector3(0, 0, -1)), 0.8, "on the side of the threat (bolts hit it first)")


func test_breath_hits_and_has_a_cooldown() -> void:
	var dragon := _dragon("frost")
	await wait_physics_frames(2)
	dragon.global_position = Vector3(3, 0.05, 0)  # beside Aurelia, close enough to stay put
	var enemy := _thornling(Vector3(3, 0, -2))
	var before := enemy.health.current
	player.face_instantly(Vector3(0, 0, -1))
	assert_true(dragon.request_skill(), "H uses the breath")
	await wait_seconds(dragon.skill.wind_up + 0.6)
	assert_lt(enemy.health.current, before, "the breath hit")
	assert_true(enemy.status_effects.has(StatusEffectComponent.CHILL), "Frost Puff chills")
	assert_false(dragon.skill_cooldown.is_ready(), "own cooldown (FR-DRG-03)")
	assert_false(dragon.request_skill(), "not again yet")


func test_light_breath_lights_a_brazier() -> void:
	var dragon := _dragon("light")
	await wait_physics_frames(2)
	dragon.global_position = Vector3(3, 0.05, 0)
	var brazier := LanternBrazier.new()
	brazier.persist_id = &"test_dragon_brazier"
	brazier.position = Vector3(3, 0, -2)
	world.add_child(brazier)
	player.face_instantly(Vector3(0, 0, -1))
	dragon.request_skill()
	await wait_seconds(dragon.skill.wind_up + 0.3)
	assert_true(brazier.is_lit, "a Light dragon's breath lights lanterns (FR-PUZ-05)")


func test_keeps_out_of_telegraph_rings() -> void:
	var dragon := _dragon()
	await wait_physics_frames(2)
	var enemy := _thornling(dragon.global_position + Vector3(0.6, 0, 0))
	enemy.state_machine.transition_to(&"Telegraph")
	assert_true(enemy.is_in_group(&"danger_zone"), "winding up marks its ring")
	var step := dragon.avoid_danger(Vector3.ZERO)
	assert_lt(step.x, 0.0, "steps away from the enemy")
	enemy.state_machine.transition_to(&"Attack")
	assert_true(enemy.is_in_group(&"danger_zone"), "still dangerous while the hit lands")
	enemy.state_machine.transition_to(&"Recover")
	assert_false(enemy.is_in_group(&"danger_zone"))
	assert_eq(dragon.avoid_danger(Vector3.ZERO), Vector3.ZERO)


func test_knocked_out_then_back_at_a_shrine() -> void:
	var dragon := _dragon()
	await wait_physics_frames(2)
	var hit := DamageInfo.create(999.0, Elements.Type.NONE, Vector3.ZERO, null)
	assert_true(dragon.hurtbox.receive_hit(hit), "enemy attacks can hit it")
	await wait_physics_frames(2)
	assert_true(dragon.state_machine.is_in(&"KnockedOut"), "knocked out, never dead (FR-DRG-07)")
	assert_false(DragonManager.is_active())
	assert_false(dragon.hurtbox.receive_hit(hit), "can't be hit while knocked out")
	assert_false(dragon.request_skill())
	DragonManager.rest()
	await wait_physics_frames(2)
	assert_true(dragon.state_machine.is_in(&"Follow"), "up again")
	assert_eq(dragon.health.current, dragon.health.max_health)


func test_commands_change_behaviour() -> void:
	var dragon := _dragon()
	await wait_physics_frames(2)
	var press := InputEventAction.new()
	press.action = &"dragon_command"
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(3)
	assert_eq(DragonManager.command, DragonTypes.Command.ATTACK, "G gives the next command")
	DragonManager.set_command(DragonTypes.Command.GUARD)
	await wait_physics_frames(2)
	assert_true(dragon.state_machine.is_in(&"Guard"), "Guard visibly changes what it does (FR-DRG-03)")


func test_petting_and_feeding_in_the_world() -> void:
	var dragon := _dragon()
	await wait_physics_frames(2)
	dragon.interactable.interact(player)
	assert_eq(DragonManager.bond_xp, TUNING.bond_per_pet, "petting raises the bond")
	dragon.health.current = 5.0
	Inventory.add(TREAT, 1)
	assert_eq(DragonManager.feed(TREAT), &"")
	assert_gt(dragon.health.current, 5.0, "a treat heals it")


func test_the_elder_gives_the_egg() -> void:
	QuestManager.done.append_array([&"herbs_for_maren", &"lost_satchel"] as Array[StringName])
	box.start(VILLAGERS, "elder")
	await _talk_through(0)
	assert_true(DragonManager.has_egg(), "the Elder handed over the egg (FR-DRG-01)")
	assert_true(QuestManager.is_active(&"dragon_egg"))
	box.start(VILLAGERS, "elder")
	await _talk_through(0)
	assert_true(DragonManager.has_egg(), "only one egg")


func test_hatching_scene_with_element_and_name() -> void:
	DragonManager.receive_egg()
	QuestManager.start(&"dragon_egg")
	DragonManager.add_warmth(TUNING.warmth_needed)
	Cutscene.play(&"dragon_hatch")
	await wait_physics_frames(2)
	assert_true(Cutscene.is_playing())
	assert_true(box.is_open(), "the scene talks through the dialogue box")
	await _talk_through(1, "  Ember ")  # second colour: Wind
	assert_true(DragonManager.is_hatched(), "hatched (FR-DRG-01)")
	assert_eq(DragonManager.element, Elements.Type.WIND, "the colour Aurelia chose (FR-DRG-06)")
	assert_eq(DragonManager.dragon_name, "Ember", "the name the player typed (FR-DLG-09)")
	var dragon := get_tree().get_first_node_in_group(&"dragon") as Dragon
	assert_not_null(dragon, "the hatchling is in the world")
	assert_eq(dragon.species.element, Elements.Type.WIND)
	assert_true(QuestManager.is_done(&"dragon_egg"))
	assert_true(Inventory.knows_recipe(&"dragon_treat"))
	assert_false(get_tree().paused, "play continues")
	assert_eq(get_tree().get_nodes_in_group(&"dragon").size(), 1)


func test_an_empty_name_keeps_pip() -> void:
	DragonManager.receive_egg()
	DragonManager.add_warmth(TUNING.warmth_needed)
	Cutscene.play(&"dragon_hatch")
	await _talk_through(0, "")
	assert_eq(DragonManager.dragon_name, "Pip")
	assert_eq(DragonManager.element, Elements.Type.FROST)


func test_hud_panel_and_dragon_page() -> void:
	var hud := Hud.new()
	world.add_child(hud)
	hud.bind(player)
	await wait_process_frames(2)
	assert_false(hud.dragon_panel.visible, "no panel before the egg")
	DragonManager.receive_egg()
	await wait_process_frames(2)
	assert_true(hud.dragon_panel.visible, "the egg's warmth shows (FR-UI-02)")
	var dragon := _dragon()
	await wait_seconds(DragonPanel.FIND_EVERY + 0.1)
	assert_eq(hud.dragon_panel.dragon, dragon)
	var page := DragonMenu.new()
	world.add_child(page)
	page.open()
	assert_string_contains(page._header.text, "Pip", "name on the Dragon page (FR-UI-04)")
	assert_string_contains(page._skills.text, "Frost Puff")
	assert_string_contains(page._skills.text, "bond 3", "locked skills say what unlocks them")
	Inventory.add(TREAT, 2)
	page.refresh()
	page.feed()
	assert_eq(Inventory.count(TREAT.id), 1, "fed from the page")
	page.set_command(DragonTypes.Command.GUARD)
	assert_eq(DragonManager.command, DragonTypes.Command.GUARD)
	page.close()
