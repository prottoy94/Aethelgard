extends GutTest
## Phase 8b end to end: the Cutscene API (markers, actors, camera, skipping: FR-DLG-06/07), the scripted Ignis fight
## (FR-BOS-04), the Rank Stone, the closed road, and the whole prologue in Elderroot Village (FR-QST-01, FR-DRG-09):
## Rank Stone → Spark → Emberbound → Ignis can't be beaten → Sylvaris → Lumen wakes → the Elder sends Aurelia on.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const ENCOUNTER: ScriptedEncounterData = preload("res://data/encounters/ignis_prologue.tres")
const PROLOGUE: DialogueResource = preload("res://dialogue/main/prologue.dialogue")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")
const TUNING: DragonTuning = preload("res://data/dragons/dragon_tuning.tres")
const VILLAGE := &"elderroot_village"
const TEST_DIR := "user://test_saves/"
const MAX_STEPS := 900  ## × 2 physics frames

var world: Node3D
var player: Player
var box: DialogueBox
var holder: Node
var _old_speed := 1


func before_all() -> void:
	CombatFx.hit_stop_enabled = false
	Settings.persist = false
	SaveManager.save_dir = TEST_DIR
	_old_speed = Settings.text_speed


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Settings.text_speed = _old_speed
	Settings.persist = true
	for slot in SaveManager.SLOTS:
		SaveManager.delete_slot(slot)
	SaveManager.save_dir = "user://saves/"
	SaveManager.writes_enabled = true
	SceneLoader.scene_parent = null
	SceneLoader.current_region = &""
	TimeOfDay.running = false
	get_tree().paused = false


func before_each() -> void:
	Settings.text_speed = 3  # instant text
	Settings.auto_advance = false
	SaveManager.reset_world()
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])
	world = null
	holder = null


func after_each() -> void:
	get_tree().paused = false
	TimeOfDay.running = false
	Cutscene.clear()
	if holder:
		holder.queue_free()
	await wait_process_frames(2)


## A small test world: floor, Aurelia, a camera and a dialogue box.
func _world() -> void:
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
	var camera := Camera3D.new()
	camera.position = Vector3(0, 8, 8)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	box = DialogueBox.new()
	world.add_child(box)
	await wait_physics_frames(3)


## Skips every scene that plays and answers what needs the player, until nothing is playing or `done` is true.
func _skip_until(done: Callable) -> bool:
	for i in MAX_STEPS:
		if done.call():
			return true
		await wait_physics_frames(2)
		if Cutscene.is_asking():
			Cutscene.submit_text("")
		elif Cutscene.is_playing() and not Cutscene.skipping:
			var dialogue := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
			if dialogue and dialogue.line and not dialogue.line.responses.is_empty():
				dialogue.choose(0)
			else:
				Cutscene.skip()
	return done.call()


# --- The Cutscene API ------------------------------------------------------------------------------

func test_cutscene_moves_turns_and_shows_actors() -> void:
	await _world()
	world.add_child(CutsceneMarker.make(&"spot", Vector3(4, 0, -3)))
	world.add_child(CutsceneMarker.make(&"cam_spot", Vector3(0, 3, 6), Vector3(0, 1, 0)))
	var sylvaris := Sylvaris.new()
	world.add_child(sylvaris)
	await wait_physics_frames(1)
	Cutscene.spawn("sylvaris", "spot")
	assert_true(sylvaris.visible, "spawned")
	assert_almost_eq(sylvaris.global_position.distance_to(Vector3(4, 0, -3)), 0.0, 0.01)
	await Cutscene.move("aurelia", "spot", 0.3)
	assert_almost_eq(player.global_position.distance_to(Vector3(4, 0, -3)), 0.0, 0.05, "walked to the marker")
	player.global_position = Vector3.ZERO
	Cutscene.face("aurelia", "sylvaris")
	assert_almost_eq((-player.visual.global_basis.z).normalized().dot(Vector3(4, 0, -3).normalized()), 1.0, 0.05,
			"turned to face him")
	var play_camera := get_viewport().get_camera_3d()
	await Cutscene.camera_to("cam_spot", 0.2)
	assert_true(Cutscene.has_camera(), "a cutscene camera took over")
	assert_almost_eq(get_viewport().get_camera_3d().global_position.distance_to(Vector3(0, 3, 6)), 0.0, 0.05)
	await Cutscene.camera_back(0.1)
	assert_eq(get_viewport().get_camera_3d(), play_camera, "back to the play camera")
	Cutscene.emote("aurelia", "!")
	await wait_physics_frames(1)
	assert_eq(player.get_children().filter(func(c: Node) -> bool: return c is EmoteBubble).size(), 1, "an emote")


func test_skipping_a_scene_still_applies_its_effects() -> void:
	await _world()
	var elder := Node3D.new()
	world.add_child(elder)
	CutsceneActor.tag(elder, &"elder")
	for id: StringName in [&"elder_meet", &"elder_door", &"cam_elder", &"aurelia_meet"]:
		world.add_child(CutsceneMarker.make(id, Vector3(1, 0, -2)))
	var scene := StoryScene.new()
	scene.resource = PROLOGUE
	scene.title = "elder_quest_start"
	world.add_child(scene)
	Cutscene.play_scene(scene, &"elder_quest_start")
	await wait_physics_frames(2)
	Cutscene.skip()
	assert_true(await _skip_until(func() -> bool: return not Cutscene.is_playing()), "the scene ended")
	assert_true(GameState.has_flag(&"met_elder"), "flags still set (FR-DLG-07)")
	assert_true(QuestManager.is_active(&"gust_trial"), "the Trial quest still starts")
	assert_true(QuestManager.is_active(&"morning_in_elderroot"))
	assert_true(GameState.has_flag(Cutscene.seen_flag(&"elder_quest_start")), "seen once")
	assert_false(get_tree().paused, "play goes on")
	await wait_seconds(Cutscene.BAR_TIME + 0.2)
	assert_false(Cutscene.is_letterboxed(), "the bars slid away")


func test_skipping_the_hatching_still_asks_the_colour() -> void:
	await _world()
	DragonManager.receive_egg()
	DragonManager.add_warmth(TUNING.warmth_needed)
	Cutscene.play(&"dragon_hatch")
	await wait_physics_frames(2)
	Cutscene.skip()
	var asked := false
	for i in MAX_STEPS:
		await wait_physics_frames(2)
		if box.line and not box.line.responses.is_empty() and not Cutscene.skipping:
			asked = true
			box.choose(2)  # Earth
		elif Cutscene.is_asking():
			Cutscene.submit_text("")
		if not Cutscene.is_playing():
			break
	assert_true(asked, "the colour choice [#ask] waits for the player")
	assert_true(DragonManager.is_hatched(), "skipping still hatches it")
	assert_eq(DragonManager.element, Elements.Type.EARTH)
	assert_eq(DragonManager.dragon_name, "Pip")
	DragonManager.from_dict({})


# --- The fight that can't be won -----------------------------------------------------------------

func _encounter() -> ScriptedEncounter:
	var encounter := ScriptedEncounter.new()
	encounter.data = ENCOUNTER
	encounter.position = Vector3(0, 0, -6)
	world.add_child(encounter)
	await wait_physics_frames(1)
	return encounter


func test_ignis_cant_be_hurt_and_she_cant_fall() -> void:
	await _world()
	var encounter := await _encounter()
	assert_false(encounter.boss.visible, "asleep until his scene")
	assert_eq(Cutscene.actor("ignis"), encounter.boss, "a cutscene actor")
	encounter.start()
	assert_true(encounter.running)
	encounter.boss.hurtbox.receive_hit(DamageInfo.create(80.0, Elements.Type.LIGHT, Vector3.ZERO, player))
	assert_eq(encounter.boss.health.current, encounter.boss.health.max_health, "Immune")
	player.health.apply_damage(DamageInfo.create(1000.0, Elements.Type.EMBER, Vector3.ZERO, null))
	assert_false(player.health.is_dead(), "she can't fall in it")
	await wait_physics_frames(2)
	assert_false(encounter.running, "badly hurt: the fight stops for the story")
	assert_true(GameState.has_flag(ENCOUNTER.done_flag))
	assert_true(player.is_invulnerable, "safe from bolts still in the air")
	encounter.release()
	assert_eq(player.health.minimum, 0.0, "normal again")


func test_ignis_fight_ends_after_its_time() -> void:
	await _world()
	var encounter := await _encounter()
	watch_signals(encounter)
	encounter.start()
	encounter.elapsed = ENCOUNTER.duration - 0.01
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(encounter, "finished", [ScriptedEncounter.REASON_TIME])
	assert_signal_emitted(encounter, "fight_ended")


# --- The village: Rank Stone, closed road, the whole prologue ---------------------------------------

func _load_village(spawn: StringName) -> Node:
	holder = Node.new()
	add_child(holder)
	SceneLoader.scene_parent = holder
	SaveManager.writes_enabled = false
	SceneLoader.autosave_on_arrival = false
	assert_true(await SceneLoader.change_region(VILLAGE, spawn))
	await wait_physics_frames(3)
	return holder


func test_after_the_prologue_the_stone_shows_her_rank_and_the_road_is_open() -> void:
	await _load_village(&"from_meadow")
	assert_null(get_tree().get_first_node_in_group(&"prologue"), "no prologue in a game that is past it")
	var stone := Cutscene.actor("rank_stone") as RankStone
	assert_not_null(stone)
	stone.show_rank(0, 0.1)
	await wait_physics_frames(2)
	var first := stone._marks[0].material_override as StandardMaterial3D
	var second := stone._marks[1].material_override as StandardMaterial3D
	assert_true(first.emission_enabled, "Spark: the first mark lights")
	assert_false(second.emission_enabled, "nothing above it")


func test_the_whole_prologue() -> void:
	GameState.set_flag(SaveManager.PROLOGUE_FLAG)
	await _load_village(&"home")
	var prologue := get_tree().get_first_node_in_group(&"prologue") as VillagePrologue
	assert_not_null(prologue, "a new story runs the prologue")
	var me := get_tree().get_first_node_in_group(&"player") as Player
	assert_true(QuestManager.is_active(&"prologue"), "Rank Day")
	assert_false(QuestManager.is_active(&"morning_in_elderroot"), "the village tasks wait until after it")
	var lumen := get_tree().get_first_node_in_group(&"lumen") as Lumen
	await wait_physics_frames(2)
	assert_false(lumen.visible, "Lumen sleeps")
	# The morning scene, then free walking.
	assert_true(await _skip_until(func() -> bool: return prologue.beat == VillagePrologue.Beat.TO_STONE))
	assert_false(get_tree().paused)
	var exit := get_tree().get_first_node_in_group(&"region_exit") as RegionExit
	watch_signals(exit)
	exit._armed = true
	exit._on_body_entered(me)
	assert_signal_emitted(exit, "blocked", "the road north stays closed on Rank Day")
	assert_false(SceneLoader.is_changing)
	# The Rank Stone: Spark, then the Emberbound.
	prologue.rank_stone.touched.emit(me)
	assert_true(await _skip_until(func() -> bool: return prologue.beat == VillagePrologue.Beat.ATTACK))
	assert_true(GameState.has_flag(VillagePrologue.FLAG_RANK))
	assert_eq(prologue.scouts.size(), 2, "two Emberbound Scouts")
	for npc in get_tree().get_nodes_in_group(&"npc"):
		assert_false((npc as Npc).visible, "the villagers hid")
	for scout in prologue.scouts.duplicate():
		scout.health.apply_damage(DamageInfo.create(1000.0, Elements.Type.LIGHT, Vector3.ZERO, me))
	# Ignis walks in; the fight he can't lose.
	assert_true(await _skip_until(func() -> bool: return prologue.encounter.running), "Ignis fights")
	assert_true(prologue.encounter.boss.visible)
	assert_eq(prologue.runtime.hud.boss_bar.boss, prologue.encounter.boss, "the boss bar shows Ignis")
	prologue.encounter.boss.hurtbox.receive_hit(DamageInfo.create(50.0, Elements.Type.LIGHT, Vector3.ZERO, me))
	assert_eq(prologue.encounter.boss.health.ratio(), 1.0, "Immune")
	prologue.encounter.end(ScriptedEncounter.REASON_TIME)
	# Sylvaris, Lumen, the Elder.
	assert_true(await _skip_until(func() -> bool: return prologue.beat == VillagePrologue.Beat.DONE), "the prologue ends")
	assert_true(GameState.has_flag(VillagePrologue.FLAG_DONE))
	assert_false(GameState.has_flag(SaveManager.PROLOGUE_FLAG))
	assert_true(QuestManager.is_done(&"prologue"))
	assert_true(QuestManager.is_active(&"gust_trial"), "the Elder sends her to the Trial")
	assert_true(QuestManager.is_active(&"morning_in_elderroot"), "and to Maren and Tamsin")
	assert_eq(QuestManager.step_index(&"morning_in_elderroot"), 1, "she has already talked to the Elder")
	assert_true(GameState.has_flag(Lumen.AWAKE_FLAG))
	await wait_physics_frames(2)
	assert_true(lumen.visible, "Lumen is awake")
	assert_false(prologue.sylvaris.visible, "Sylvaris flew back to the World Tree")
	assert_null(prologue.encounter.boss, "Ignis is gone")
	assert_eq(me.health.minimum, 0.0)
	for npc in get_tree().get_nodes_in_group(&"npc"):
		assert_true((npc as Npc).visible, "the villagers came back out")
	assert_false(get_tree().paused)
	assert_false(Cutscene.is_playing())
	for id: StringName in [&"prologue_morning", &"prologue_rank_trial", &"prologue_ignis_arrives",
			&"prologue_unwinnable", &"elder_quest_start"]:
		assert_true(GameState.has_flag(Cutscene.seen_flag(id)), "%s played" % id)
