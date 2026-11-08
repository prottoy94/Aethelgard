extends GutTest
## Phase 8b logic: health that can't be hurt or can't fall (the prologue Ignis, FR-BOS-04), the Gust Trial's rune
## order (FR-QST-03), cutscene markers and actors (FR-DLG-06), skip bookkeeping (FR-DLG-07), the prologue's flags,
## Lumen sleeping until the prologue wakes it, and the new quests and data.

const IGNIS: BossData = preload("res://data/bosses/ignis_prologue.tres")
const ENCOUNTER: ScriptedEncounterData = preload("res://data/encounters/ignis_prologue.tres")
const GUST_TRIAL: TrialData = preload("res://data/trials/gust_trial.tres")
const GUST: SpellData = preload("res://data/spells/gust.tres")
const LIGHT_MOTE: SpellData = preload("res://data/spells/light_mote.tres")


func before_each() -> void:
	GameState.reset()
	QuestManager.reset()
	PlayerData.reset([LIGHT_MOTE] as Array[SpellData])


func after_each() -> void:
	Cutscene.clear()


func _health(maximum := 100.0) -> HealthComponent:
	var health := HealthComponent.new()
	health.max_health = maximum
	add_child_autofree(health)
	return health


# --- Health in scripted fights --------------------------------------------------------------------

func test_invulnerable_health_takes_nothing_but_reports_the_hit() -> void:
	var health := _health()
	health.invulnerable = true
	watch_signals(health)
	assert_eq(health.apply_damage(DamageInfo.create(50.0, Elements.Type.LIGHT, Vector3.ZERO, null)), 0.0)
	assert_eq(health.current, 100.0, "no damage (Ignis in the prologue)")
	assert_signal_emitted(health, "damaged", "the hit still lands (it flashes and says Immune)")
	assert_false(health.is_dead())


func test_minimum_health_stops_a_fall() -> void:
	var health := _health()
	health.minimum = 1.0
	assert_eq(health.apply_damage(DamageInfo.create(30.0, Elements.Type.NONE, Vector3.ZERO, null)), 30.0)
	assert_eq(health.apply_damage(DamageInfo.create(500.0, Elements.Type.NONE, Vector3.ZERO, null)), 69.0,
			"only what was taken is reported")
	assert_eq(health.current, 1.0, "she can't fall in the scripted fight")
	assert_false(health.is_dead())
	health.minimum = 0.0
	health.apply_damage(DamageInfo.create(5.0, Elements.Type.NONE, Vector3.ZERO, null))
	assert_true(health.is_dead(), "normal again once the fight is over")


# --- The Gust Trial's runes ------------------------------------------------------------------------

func _runes() -> RuneSequence:
	var runes: Array[TrialRune] = []
	for i in 3:
		var rune := TrialRune.new()
		rune.order = i + 1
		rune.persist_id = StringName("test_rune_%d" % i)
		add_child_autofree(rune)
		rune.reveal()
		rune._grace = 0.0
		runes.append(rune)
	var sequence := RuneSequence.new()
	add_child_autofree(sequence)
	sequence.setup(runes)
	return sequence


func test_hidden_runes_cant_be_lit_and_reveal_remembers() -> void:
	var rune := TrialRune.new()
	rune.order = 2
	rune.persist_id = &"test_hidden_rune"
	add_child_autofree(rune)
	assert_true(rune.is_in_group(&"revealable"), "Lantern Glow finds it")
	rune._on_element_hit(Elements.Type.LIGHT, Vector3.ZERO)
	assert_false(rune.is_lit, "hidden in the mist: nothing to light yet")
	rune.reveal()
	rune._on_element_hit(Elements.Type.LIGHT, Vector3.ZERO)
	assert_false(rune.is_lit, "the light that revealed it doesn't light it in the same moment")
	rune._grace = 0.0
	rune._on_element_hit(Elements.Type.WIND, Vector3.ZERO)
	assert_false(rune.is_lit, "only Light lights it")
	rune._on_element_hit(Elements.Type.LIGHT, Vector3.ZERO)
	assert_true(rune.is_lit)
	assert_true(GameState.get_object_state(&"test_hidden_rune").get("revealed", false))


func test_runes_lit_in_order_complete_the_sequence() -> void:
	var sequence := _runes()
	watch_signals(sequence)
	for rune in sequence.runes:
		rune.light_up()
	assert_true(sequence.is_on(), "one breath, then two, then three")
	assert_signal_not_emitted(sequence, "wrong")


func test_a_rune_out_of_order_puts_them_all_out() -> void:
	var sequence := _runes()
	watch_signals(sequence)
	sequence.runes[0].light_up()
	sequence.runes[2].light_up()  # three before two
	assert_signal_emitted(sequence, "wrong")
	assert_false(sequence.is_on())
	assert_eq(sequence.next, 1, "start again from the first")
	for rune in sequence.runes:
		assert_false(rune.is_lit, "all dark again")
	for rune in sequence.runes:
		rune.light_up()
	assert_true(sequence.is_on(), "the right order still works afterwards")


func test_a_solved_sequence_shows_all_runes_lit() -> void:
	var sequence := _runes()
	sequence.set_complete()
	assert_true(sequence.is_on())
	for rune in sequence.runes:
		assert_true(rune.is_lit)


# --- Cutscene markers, actors and skipping ---------------------------------------------------------

func test_marker_faces_the_point_it_looks_at() -> void:
	var marker := CutsceneMarker.make(&"cam_test", Vector3(0, 2, 5), Vector3(0, 2, 0))
	add_child_autofree(marker)
	assert_almost_eq((-marker.global_basis.z).dot(Vector3.FORWARD), 1.0, 0.001, "looks along its -Z")
	assert_eq(CutsceneMarker.find(get_tree(), &"cam_test"), marker)
	assert_null(CutsceneMarker.find(get_tree(), &"nowhere"))


func test_actors_are_found_by_id() -> void:
	var node := Node3D.new()
	add_child_autofree(node)
	CutsceneActor.tag(node, &"someone")
	assert_eq(Cutscene.actor("someone"), node)
	assert_null(Cutscene.actor("nobody"))
	var sylvaris := Sylvaris.new()
	add_child_autofree(sylvaris)
	assert_eq(Cutscene.actor("sylvaris"), sylvaris, "Sylvaris tags himself")
	assert_false(sylvaris.visible, "hidden until a scene spawns him")


func test_seen_flag_name() -> void:
	assert_eq(Cutscene.seen_flag(&"prologue_morning"), &"cs_prologue_morning_seen")


func test_skip_pauses_for_a_choice_and_resumes() -> void:
	var scene := CutsceneScene.new()
	add_child_autofree(scene)
	Cutscene.active = scene
	Cutscene.skip()
	assert_true(Cutscene.skipping)
	Cutscene.pause_skip()
	assert_false(Cutscene.skipping, "the player decides this one")
	Cutscene.resume_skip()
	assert_true(Cutscene.skipping, "and the fast-forward goes on")
	Cutscene.active = null


func test_wait_ends_at_once_while_skipping() -> void:
	var scene := CutsceneScene.new()
	add_child_autofree(scene)
	Cutscene.active = scene
	Cutscene.skipping = true
	var start := Time.get_ticks_msec()
	await Cutscene.wait(5.0)
	assert_lt(Time.get_ticks_msec() - start, 500, "a skipped wait doesn't wait")
	Cutscene.active = null


# --- The prologue's flags and Lumen -----------------------------------------------------------------

func test_prologue_runs_only_in_a_new_story() -> void:
	assert_false(VillagePrologue.is_running(), "tests and quick starts begin after the prologue")
	assert_true(Lumen.is_awake())
	GameState.set_flag(SaveManager.PROLOGUE_FLAG)
	assert_true(VillagePrologue.is_running())
	assert_false(Lumen.is_awake(), "Lumen sleeps until Sylvaris comes (GDD §3.6)")
	GameState.set_flag(Lumen.AWAKE_FLAG)
	assert_true(Lumen.is_awake())
	GameState.set_flag(VillagePrologue.FLAG_DONE)
	assert_false(VillagePrologue.is_running())


func test_prologue_quest_follows_the_beats() -> void:
	assert_true(QuestManager.start(&"prologue"))
	assert_eq(QuestManager.step_index(&"prologue"), 0)
	GameState.set_flag(VillagePrologue.FLAG_RANK)
	assert_eq(QuestManager.step_index(&"prologue"), 1, "then the Emberbound")
	GameState.set_flag(VillagePrologue.FLAG_SCOUTS)
	GameState.set_flag(VillagePrologue.FLAG_IGNIS)
	assert_true(QuestManager.is_active(&"prologue"), "still running through the scenes after the fight")
	GameState.set_flag(VillagePrologue.FLAG_DONE)
	assert_true(QuestManager.is_done(&"prologue"))


func test_gust_trial_quest_steps() -> void:
	assert_true(QuestManager.start(&"gust_trial"))
	assert_eq(QuestManager.LIBRARY.find(&"gust_trial").kind, QuestData.Kind.TRIAL)
	GameState.set_flag(StringName("found_%s" % GUST_TRIAL.place_id))
	assert_eq(QuestManager.step_index(&"gust_trial"), 1, "found the shrine")
	EventBus.puzzle_solved.emit(GUST_TRIAL.puzzle_id())
	assert_eq(QuestManager.step_index(&"gust_trial"), 2, "the runes are awake")
	GameState.set_flag(GUST_TRIAL.passed_flag)
	assert_eq(QuestManager.step_index(&"gust_trial"), 3, "passed")
	PlayerData.learn(GUST)
	assert_true(QuestManager.is_done(&"gust_trial"), "read the tome: done")


# --- Data -------------------------------------------------------------------------------------------

func test_ignis_and_encounter_data() -> void:
	assert_true(IGNIS.invulnerable, "can't be hurt (FR-BOS-04)")
	assert_eq(IGNIS.rank, "???", "rank hidden at first (GDD §5.2)")
	assert_eq(IGNIS.element, Elements.Type.EMBER)
	assert_gt(IGNIS.phases[0].moves.size(), 2, "every kind of warning")
	assert_gt(ENCOUNTER.duration, 0.0)
	assert_between(ENCOUNTER.end_health_ratio, 0.05, 0.95)
	assert_gt(ENCOUNTER.player_minimum_health, 0.0, "she can't fall")
	var ignis := ENCOUNTER.boss_scene.instantiate() as Boss
	assert_eq(ignis.data, IGNIS, "the encounter wakes Ignis")
	ignis.free()


func test_gust_trial_data() -> void:
	assert_eq(GUST_TRIAL.spell, GUST, "the Trial gives Gust (GDD §6.4)")
	assert_eq(GUST_TRIAL.rune_count, GUST_TRIAL.rune_angles.size(), "an angle for every rune")
	assert_eq(GUST_TRIAL.waves.size(), 2, "two short waves (owner decision 2026-11-07)")
	for wave in GUST_TRIAL.waves:
		assert_gt(wave.enemies.size(), 0)
	assert_lt(GUST_TRIAL.rune_distance, GUST_TRIAL.radius, "the runes are inside the ring")
	assert_ne(GUST_TRIAL.passed_flag, &"")
	var cues := GUST_TRIAL.dialogue.get_cues()
	for cue in [GUST_TRIAL.intro_cue, GUST_TRIAL.test_cue, GUST_TRIAL.complete_cue, GUST_TRIAL.repeat_cue]:
		assert_has(cues, cue)
