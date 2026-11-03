extends GutTest
## Phase 6a in a physics world: conversations with choices and portraits, NPC lines changing with quests, puzzles
## reacting to spells (braziers, hidden steps, push block), persistence of solved puzzles, Lumen's hints, the
## journal, Cutscene basics and the Options page (FR-DLG-02/03/08/11, FR-QST-02/04/05, FR-PUZ-01/02/06/07).

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")
const GUST := preload("res://data/spells/gust.tres")
const SUNPETAL := preload("res://data/items/sunpetal.tres")
const SATCHEL := preload("res://data/items/tamsin_satchel.tres")
const VILLAGERS := preload("res://dialogue/npcs/elderroot_villagers.dialogue")
const MAX_LINES := 40

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
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])
	GameState.reset()
	QuestManager.reset()
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
	box = DialogueBox.new()
	add_child_autofree(box)
	await wait_physics_frames(3)


func after_each() -> void:
	get_tree().paused = false


## Plays a conversation to the end, picking `choices` in order at each choice. Returns every line's text.
func _talk(cue: String, choices: Array = []) -> Array[String]:
	var said: Array[String] = []
	box.start(VILLAGERS, cue)
	var guard := 0
	while box.is_open() and guard < MAX_LINES:
		guard += 1
		await wait_process_frames(2)
		if box.line == null:
			continue
		said.append(box.line.text)
		if not box.line.responses.is_empty():
			box.choose(choices.pop_front() if not choices.is_empty() else 0)
		else:
			box.advance()
	await wait_process_frames(2)
	return said


func test_conversation_pauses_and_shows_portraits() -> void:
	box.start(VILLAGERS, "maren")
	await wait_process_frames(3)
	assert_true(box.is_open())
	assert_true(get_tree().paused, "talking pauses the game")
	assert_eq(box.line.character, "Maren")
	assert_eq(box._right.mood, "worried", "[#worried] sets the expression")
	assert_true(box._right.visible)
	await _talk_rest()
	assert_false(get_tree().paused)


func _talk_rest() -> void:
	var guard := 0
	while box.is_open() and guard < MAX_LINES:
		guard += 1
		if box.line and not box.line.responses.is_empty():
			box.choose(0)
		else:
			box.advance()
		await wait_process_frames(2)


func test_choices_lead_to_different_replies() -> void:
	var first := await _talk("elder", [0])
	GameState.reset()
	var second := await _talk("elder", [1])
	assert_true(first.has("Maren is out of Sunpetal for her remedies. She's in her herb garden, just there."))
	assert_true(second.has("Every lantern in Elderroot was lit from one small spark."))
	assert_ne(first, second)


func test_repeat_talk_is_short() -> void:
	var first := await _talk("elder")
	var again := await _talk("elder")
	assert_gt(first.size(), again.size(), "the second time is just a reminder")


func test_herbalist_quest_through_dialogue() -> void:
	await _talk("maren")
	assert_true(QuestManager.is_active(&"herbs_for_maren"), "the conversation starts the quest")
	Inventory.add(SUNPETAL, 3)
	assert_true(QuestManager.is_on_step(&"herbs_for_maren", 1))
	await _talk("maren", [0])
	assert_true(QuestManager.is_done(&"herbs_for_maren"))
	assert_eq(Inventory.count(&"sunpetal"), 0, "handed over")
	assert_true(Inventory.knows_recipe(&"stamina_tonic"), "reward")
	var after := await _talk("maren")
	assert_eq(after[0], "The Sunpetal tea is working wonders. Brew yourself a tonic, dear.", "lines change (FR-QST-04)")


func test_satchel_quest_from_the_world() -> void:
	await _talk("tamsin")
	var satchel := ItemPickup.new()
	satchel.item = SATCHEL
	satchel.persist_id = &"test_satchel"
	satchel.position = Vector3(0, 0, -3)
	world.add_child(satchel)
	await wait_physics_frames(2)
	player.global_position = satchel.global_position
	await wait_physics_frames(6)
	assert_true(QuestManager.is_on_step(&"lost_satchel", 1), "picking it up finishes the search step")
	assert_true(GameState.get_object_state(&"test_satchel").get("taken", false))
	await _talk("tamsin")
	assert_true(QuestManager.is_done(&"lost_satchel"))
	assert_false(Inventory.has(&"tamsin_satchel"), "given back")


func test_npc_talk_requests_conversation() -> void:
	var npc := Npc.new()
	npc.npc_id = &"maren"
	npc.display_name = "Maren"
	npc.look = load("res://data/npcs/maren.tres")
	npc.dialogue = VILLAGERS
	npc.cue = "maren"
	npc.position = Vector3(0, 0, -1.5)
	world.add_child(npc)
	npc.talk_requested.connect(func(who: Npc) -> void: box.start(who.dialogue, who.cue, [who]))
	watch_signals(EventBus)
	await wait_physics_frames(5)
	assert_true(player.try_interact(), "villager in reach")
	await wait_process_frames(3)
	assert_true(box.is_open())
	assert_signal_emitted(EventBus, "npc_talked")
	await _talk_rest()


func test_braziers_light_from_light_mote_and_open_the_gate() -> void:
	var near := LanternBrazier.new()
	near.persist_id = &"test_brazier_a"
	near.position = Vector3(0, 0, -3)
	world.add_child(near)
	var far := LanternBrazier.new()
	far.persist_id = &"test_brazier_b"
	far.position = Vector3(12, 0, 0)
	world.add_child(far)
	var gate := PuzzleGate.new()
	world.add_child(gate)
	gate.position = Vector3(0, 0, 8)
	var puzzle := Puzzle.new()
	puzzle.puzzle_id = &"test_gate"
	world.add_child(puzzle)
	puzzle.setup([near, far] as Array[Node], [gate] as Array[Node])
	watch_signals(EventBus)
	player.face_instantly(Vector3.FORWARD)
	player._mouse_aim = false
	assert_true(player.try_cast(0), "Light Mote")
	await wait_physics_frames(30)
	assert_true(near.is_lit, "the mote lit the brazier it flew into")
	assert_false(puzzle.is_solved, "one of two")
	far.light_up()
	assert_true(puzzle.is_solved)
	assert_true(gate.is_open)
	assert_signal_emitted_with_parameters(EventBus, "puzzle_solved", [&"test_gate"])
	assert_true(GameState.get_object_state(&"test_brazier_a").get("lit", false), "remembered")


func test_solved_puzzle_stays_solved() -> void:
	GameState.set_object_state(&"test_saved", {"solved": true})
	var gate := PuzzleGate.new()
	world.add_child(gate)
	var puzzle := Puzzle.new()
	puzzle.puzzle_id = &"test_saved"
	world.add_child(puzzle)
	puzzle.setup([] as Array[Node], [gate] as Array[Node])
	assert_true(gate.is_open, "opens at once when loading a solved puzzle (FR-PUZ-06)")


func test_lantern_glow_reveals_steps_and_lights_braziers() -> void:
	var steps := HiddenSteps.new()
	steps.persist_id = &"test_steps"
	steps.position = Vector3(2, 0, -2)
	world.add_child(steps)
	var brazier := LanternBrazier.new()
	brazier.persist_id = &"test_glow_brazier"
	brazier.position = Vector3(-2, 0, -1)
	world.add_child(brazier)
	await wait_physics_frames(2)
	assert_true(steps.hidden)
	assert_true(steps._ramp.disabled, "can't be climbed while hidden")
	assert_true(player.try_cast(1), "Lantern Glow")
	await wait_physics_frames(3)
	assert_false(steps.hidden, "revealed")
	assert_false(steps._ramp.disabled, "now solid")
	assert_true(brazier.is_lit, "the glow lights braziers in its radius")


func test_gust_pushes_block_onto_plate_and_unlocks_chest() -> void:
	PlayerData.learn(GUST)
	await wait_physics_frames(2)
	var block := PushBlock.new()
	block.persist_id = &"test_block"
	block.position = Vector3(0, 0, -2.5)
	world.add_child(block)
	var plate := PressurePlate.new()
	plate.position = block.position + Vector3(0, 0, -block.cell)
	world.add_child(plate)
	var chest := Chest.new()
	chest.persist_id = &"test_chest"
	chest.locked = true
	chest.contents = [SUNPETAL] as Array[ItemData]
	chest.position = Vector3(4, 0, 0)
	world.add_child(chest)
	var puzzle := Puzzle.new()
	puzzle.puzzle_id = &"test_block_puzzle"
	world.add_child(puzzle)
	puzzle.setup([plate] as Array[Node], [chest] as Array[Node])
	await wait_physics_frames(3)
	assert_false(chest.open(), "locked")
	player.face_instantly(Vector3.FORWARD)
	player._mouse_aim = false
	assert_true(player.try_cast(player.spell_caster.loadout.find(GUST)), "Gust")
	await wait_seconds(block.slide_time + 0.3)
	assert_almost_eq(block.global_position.z, -2.5 - block.cell, 0.05, "pushed one cell away from Aurelia")
	assert_true(plate.is_pressed)
	assert_true(puzzle.is_solved)
	assert_true(chest.open(), "unlocked")
	assert_eq(Inventory.count(&"sunpetal"), 1)
	assert_eq(PushBlock.axis_of(Vector3(0.3, 0, -0.9)), Vector3(0, 0, -1), "pushes snap to the grid axes")


func test_lumen_hints_when_stuck() -> void:
	var lumen := Lumen.new()
	lumen.hints = Lumen.HINTS.duplicate()
	lumen.hints.stuck_time = 0.3
	world.add_child(lumen)
	var brazier := LanternBrazier.new()
	brazier.persist_id = &"test_hint_brazier"
	brazier.position = Vector3(0, 0, -6)
	world.add_child(brazier)
	var puzzle := Puzzle.new()
	puzzle.puzzle_id = &"test_hint"
	puzzle.hint_cue = "lumen_hint_braziers"
	puzzle.position = brazier.position
	world.add_child(puzzle)
	puzzle.setup([brazier] as Array[Node], [] as Array[Node])
	watch_signals(lumen.speaker)
	await wait_seconds(0.8)
	assert_signal_emitted(lumen.speaker, "barked", "Lumen offers a hint (FR-PUZ-07)")
	assert_true(lumen.speaker.is_showing())


func test_lumen_notices_secrets_and_low_health() -> void:
	var lumen := Lumen.new()
	world.add_child(lumen)
	var steps := HiddenSteps.new()
	steps.persist_id = &"test_secret_steps"
	steps.position = Vector3(0, 0, -4)
	world.add_child(steps)
	watch_signals(lumen.speaker)
	await wait_process_frames(5)
	assert_signal_emitted(lumen.speaker, "barked", "a secret nearby")
	lumen.speaker._time_left = 0.0
	player.health.apply_damage(DamageInfo.create(80.0, Elements.Type.NONE, Vector3.ZERO, null))
	await wait_process_frames(5)
	assert_true(GameState.has_flag(Lumen.LOW_HEALTH_FLAG), "only once per game")
	assert_signal_emit_count(lumen.speaker, "barked", 2)


func test_journal_shows_the_current_step() -> void:
	QuestManager.start(&"herbs_for_maren")
	Inventory.add(SUNPETAL, 1)
	var text := JournalMenu.quest_text(QuestManager.LIBRARY.find(&"herbs_for_maren"))
	assert_string_contains(text, "Gather 3 Sunpetal (1/3)")
	assert_string_contains(text, "Maren")


func test_cutscene_basics() -> void:
	await Cutscene.letterbox(true)
	assert_true(Cutscene.is_letterboxed())
	await Cutscene.fade_out(0.1)
	await Cutscene.fade_in(0.1)
	Cutscene.clear()
	assert_false(Cutscene.is_letterboxed())


func test_text_speed_option() -> void:
	var options := OptionsMenu.new()
	add_child_autofree(options)
	Settings.set_text_speed(0)
	assert_eq(Settings.text_speed, 0)
	Settings.set_text_speed(99)
	assert_eq(Settings.text_speed, Settings.TEXT_SPEEDS - 1, "clamped")
	options.open()
	assert_true(options.is_open())
	options.close()
