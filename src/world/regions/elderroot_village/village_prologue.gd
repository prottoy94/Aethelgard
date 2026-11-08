class_name VillagePrologue
extends Node
## The prologue (GAME_DESIGN.md §3.6; DIALOGUE_DESIGN.md §10; FR-QST-01, FR-BOS-04, FR-DRG-09): Rank Day in Elderroot
## Village. A new game starts here (SaveManager.start_prologue) and this director runs the beats in order:
## 1. prologue_morning: Aurelia reads on the bench by her cottage (Sunlight on Ancient Stone, intro + verse 1).
## 2. She walks to the Rank Stone in the square (quest step, N shows the way) and touches it: prologue_rank_trial,
##    the Elder holds the test (owner decision 2026-11-07) and the Stone stops at Spark. A horn: Emberbound Scouts.
## 3. She fights the two Scouts (the villagers hide).
## 4. prologue_ignis_arrives, then the fight she can't win (ScriptedEncounter): Ignis can't be hurt, she can't fall.
## 5. prologue_unwinnable → sylvaris_first_meeting: Sylvaris drives Ignis off; Lumen wakes; she vows to grow strong.
## 6. elder_quest_start: the Elder sends her to the Trial shrine in the meadow and to Maren and Tamsin.
## Lines: dialogue/main/prologue.dialogue (cutscenes, skippable with Esc). The region's exit stays closed until it
## ends. Beat flags let a game saved part-way pick up at the last beat; `-- --prologue=<beat>` starts at a beat
## (stone, attack, ignis, sylvaris, elder; dev tool).

signal finished

const DIALOGUE: DialogueResource = preload("res://dialogue/main/prologue.dialogue")
const SCOUT_SCENE: PackedScene = preload("res://src/actors/enemies/emberbound/emberbound_scout.tscn")
const ENCOUNTER: ScriptedEncounterData = preload("res://data/encounters/ignis_prologue.tres")
const QUEST: StringName = &"prologue"
const FLAG_ACTIVE: StringName = &"prologue_active"
const FLAG_RANK: StringName = &"prologue_rank_done"
const FLAG_SCOUTS: StringName = &"prologue_scouts_done"
const FLAG_IGNIS: StringName = &"prologue_ignis_done"
const FLAG_DONE: StringName = &"prologue_done"
const MORNING_MUSIC: StringName = &"mus_prologue_morning"
const ATTACK_MUSIC: StringName = &"mus_prologue_attack"
const START_OPTION := "--prologue="
const AFTER_SCOUTS := 1.5     ## s between the last Scout falling and Ignis arriving

enum Beat { MORNING, TO_STONE, RANK, ATTACK, IGNIS_ARRIVES, IGNIS_FIGHT, UNWINNABLE, ELDER, DONE }

## Where things happen in the village (village coordinates). The Rank Stone, the bench and Aurelia's "home" spawn
## are built by the village from the same values.
const HOME_BENCH := Vector3(-7.6, 0, 5.4)
const RANK_STONE := Vector3(-3.4, 0, -3.0)
const RANK_STONE_FACING := Vector3(0.15, 0, 1.0)   ## its rune marks face the south of the square
const MARKERS := {
	&"aurelia_stone": Vector3(-3.15, 0, -1.65),
	&"elder_stone": Vector3(-5.1, 0, -1.9),
	&"elder_hide": Vector3(-8.6, 0, -5.4),
	&"elder_door": Vector3(-8.2, 0, -4.6),
	&"elder_meet": Vector3(-0.9, 0, -4.0),
	&"scout_gate_1": Vector3(-1.2, 0, -18.5),
	&"scout_gate_2": Vector3(1.3, 0, -19.5),
	&"scout_square_1": Vector3(-1.8, 0, -10.0),
	&"scout_square_2": Vector3(1.9, 0, -10.8),
	&"aurelia_square": Vector3(0.6, 0, -3.2),
	&"ignis_gate": Vector3(0, 0, -19.5),
	&"ignis_square": Vector3(0, 0, -9.5),
	&"ignis_final": Vector3(0, 0, -16.0),
	&"aurelia_down": Vector3(-1.5, 0, -6.5),
	&"sylvaris_sky": Vector3(-16, 22, 14),
	&"sylvaris_land": Vector3(1.0, 0, -9.5),
	&"sylvaris_rest": Vector3(1.0, 0, -13.5),
	&"aurelia_meet": Vector3(0.8, 0, -5.4),
}
## Camera spots: [position, the point it looks at].
const CAMERAS := {
	&"cam_home": [Vector3(-4.2, 1.9, 2.9), Vector3(-7.6, 0.9, 5.4)],
	&"cam_stone": [Vector3(-1.4, 2.0, 3.4), Vector3(-3.7, 1.2, -2.3)],
	&"cam_marks": [Vector3(-1.4, 1.25, 0.5), Vector3(-3.3, 1.05, -2.9)],
	&"cam_road": [Vector3(2.6, 2.4, -2.6), Vector3(0, 1.0, -15.0)],
	&"cam_ignis": [Vector3(1.8, 1.9, -5.4), Vector3(0, 1.6, -9.5)],
	&"cam_final": [Vector3(8.0, 3.2, -4.0), Vector3(-0.1, 1.2, -9.8)],
	&"cam_sky": [Vector3(3.0, 8.0, 5.0), Vector3(0.5, 3.0, -9.5)],
	&"cam_meet": [Vector3(-2.5, 1.6, 0.5), Vector3(0.9, 2.8, -9.5)],
	&"cam_elder": [Vector3(2.8, 2.0, -1.6), Vector3(-0.1, 1.2, -4.8)],
}

var runtime: RegionRuntime
var world: Node3D
var rank_stone: RankStone
var encounter: ScriptedEncounter
var sylvaris: Sylvaris
var scouts: Array[Enemy] = []
var beat := Beat.MORNING
var _hidden: Array[Npc] = []


func _ready() -> void:
	add_to_group(&"prologue")


## True while a new game's prologue is still running.
static func is_running() -> bool:
	return GameState.has_flag(FLAG_ACTIVE) and not GameState.has_flag(FLAG_DONE)


## Adds the scene's markers, Sylvaris and Ignis's encounter to `world_`. Call before RegionRuntime.start().
func build(world_: Node3D, stone: RankStone) -> void:
	world = world_
	rank_stone = stone
	for id: StringName in MARKERS:
		world.add_child(CutsceneMarker.make(id, MARKERS[id]))
	for id: StringName in CAMERAS:
		world.add_child(CutsceneMarker.make(id, CAMERAS[id][0], CAMERAS[id][1]))
	sylvaris = Sylvaris.new()
	world.add_child(sylvaris)
	encounter = ScriptedEncounter.new()
	encounter.data = ENCOUNTER
	world.add_child(encounter)
	encounter.finished.connect(func(_reason: StringName) -> void: _unwinnable())
	rank_stone.touched.connect(_on_stone_touched)


## Starts at the right beat. Call after RegionRuntime.start().
func begin(runtime_: RegionRuntime) -> void:
	runtime = runtime_
	var start := _apply_start_option()
	QuestManager.start(QUEST)
	if start == "elder":
		_elder_only()
	elif start == "stone":  # straight to the rank test (dev tool)
		_rank_trial()
	elif GameState.has_flag(FLAG_IGNIS):
		_hide_villagers()
		_unwinnable()
	elif GameState.has_flag(FLAG_SCOUTS):
		_ignis_arrives()
	elif GameState.has_flag(FLAG_RANK):
		_hide_villagers()
		_spawn_scouts(true)
		_attack()
	else:
		_morning()


func _process(_delta: float) -> void:
	# The morning song plays only its intro and first verse; then the village's own music comes back.
	if (beat == Beat.TO_STONE or beat == Beat.RANK) and runtime and runtime.hold_music 			and AudioManager.current_music() == &"":
		runtime.hold_music = false
		runtime.update_audio()


# --- The beats -----------------------------------------------------------------------------------

func _morning() -> void:
	beat = Beat.MORNING
	Cutscene.fade_out(0.0)  # from black
	runtime.hold_music = true
	AudioManager.play_music(MORNING_MUSIC)
	if not await _scene(&"prologue_morning"):
		return  # the region closed mid-scene (quitting)
	beat = Beat.TO_STONE
	runtime.show_toast("Rank Day! Touch the Rank Stone in the square.   (N: show the way)", 6.0)


func _on_stone_touched(_by: Player) -> void:
	if beat == Beat.TO_STONE and not Cutscene.is_playing():
		_rank_trial()


func _rank_trial() -> void:
	beat = Beat.RANK
	if not await _scene(&"prologue_rank_trial"):
		return  # the region closed mid-scene (quitting)
	GameState.set_flag(FLAG_RANK)
	if scouts.is_empty():
		_spawn_scouts(true)  # the scene was skipped before they came in
	_hide_villagers()
	_attack()


func _attack() -> void:
	beat = Beat.ATTACK
	runtime.hold_music = true  # the story's music from here until the Elder has spoken
	AudioManager.set_combat_layer(&"")
	AudioManager.play_music(ATTACK_MUSIC)
	runtime.show_toast("The Emberbound! Drive them out of the village!", 5.0)
	_check_scouts()


func _on_scout_defeated(scout: Enemy) -> void:
	scouts.erase(scout)
	_check_scouts()


func _check_scouts() -> void:
	if beat != Beat.ATTACK or not scouts.is_empty():
		return
	beat = Beat.IGNIS_ARRIVES
	GameState.set_flag(FLAG_SCOUTS)
	await Cutscene.wait(AFTER_SCOUTS)
	if is_inside_tree():
		_ignis_arrives()


func _ignis_arrives() -> void:
	beat = Beat.IGNIS_ARRIVES
	runtime.hold_music = true
	_hide_villagers()
	var player := runtime.player
	player.health.reset()  # a breath before he comes (the fight ends when she is hurt, so start it fresh)
	player.stamina.reset()
	if not await _scene(&"prologue_ignis_arrives"):
		return  # the region closed mid-scene (quitting)
	beat = Beat.IGNIS_FIGHT
	if not encounter.boss.visible:  # skipped before he walked in
		Cutscene.spawn("ignis", "ignis_square")
	encounter.start()


func _unwinnable() -> void:
	if beat == Beat.UNWINNABLE or beat == Beat.ELDER or beat == Beat.DONE:
		return
	beat = Beat.UNWINNABLE
	runtime.hold_music = true
	await Cutscene.wait(0.6)  # let the last hit land
	if not is_inside_tree():
		return
	if not await _scene(&"prologue_unwinnable"):
		return  # the region closed mid-scene (quitting)
	encounter.release()
	beat = Beat.ELDER
	if not await _scene(&"elder_quest_start"):
		return
	_finish()


func _finish() -> void:
	beat = Beat.DONE
	GameState.set_flag(&"met_elder")
	GameState.set_flag(Lumen.AWAKE_FLAG)
	GameState.set_flag(FLAG_DONE)
	GameState.clear_flag(FLAG_ACTIVE)
	for quest: StringName in [&"morning_in_elderroot", &"gust_trial"]:  # in case the scene ended early
		if not QuestManager.is_active(quest) and not QuestManager.is_done(quest):
			QuestManager.start(quest)
	_show_villagers()
	sylvaris.visible = false
	runtime.hold_music = false
	runtime.update_audio()
	runtime.player.health.reset()
	SaveManager.autosave()
	runtime.show_toast("The way to the meadow is open. The Trial shrine lies east of the old ruins.   (J: journal)", 7.0)
	finished.emit()


# --- Cues from the scenes (dialogue/main/prologue.dialogue) ---------------------------------------

func cue(cue_name: StringName) -> void:
	match cue_name:
		&"rank_stone":
			await rank_stone.show_rank(PlayerData.rank, 1.8)
		&"horn":
			AudioManager.play(&"world_war_horn")
			Cutscene.shake(0.15, 1.2)
			await Cutscene.wait(1.0)
		&"scouts":
			_spawn_scouts(false)
			await Cutscene.wait(1.6)
		&"villagers_hide":
			var elder := _actor(&"elder")
			if elder:
				Cutscene.walk_to(elder, MARKERS[&"elder_hide"], 1.2)
			await Cutscene.wait(1.0)
			_hide_villagers()
		&"stage_final_blow":
			await Cutscene.fade_out(0.4)
			_clear_scouts()
			Cutscene.spawn("aurelia", "aurelia_down")
			Cutscene.spawn("ignis", "ignis_final")
			Cutscene.face("aurelia", "ignis")
			Cutscene.face("ignis", "aurelia")
		&"sylvaris_breath":
			Cutscene.face("sylvaris", "ignis")
			var ignis := _ignis_visual()
			Cutscene.involve(sylvaris)
			sylvaris.play_anim(&"breath")
			await Cutscene.wait(0.5)
			Cutscene.flash("fff3c0", 0.6)
			Cutscene.shake(0.5, 0.8)
			if ignis:
				ignis.play_anim(&"release")
				ignis.play_anim(&"recoil")
			await Cutscene.wait(1.0)
			sylvaris.play_anim(&"breath_end")
			await Cutscene.wait(0.4)
		&"ignis_retreats":
			var ignis := _ignis_visual()
			if ignis:
				AudioManager.play(&"world_ignis_vanish", ignis.global_position)
				await Cutscene.wait(ignis.play_anim(&"vanish"))
		&"stage_meeting":
			await Cutscene.fade_out(0.5)
			Cutscene.despawn("ignis")
			Cutscene.spawn("sylvaris", "sylvaris_rest")
			Cutscene.spawn("aurelia", "aurelia_meet")
			Cutscene.face("sylvaris", "aurelia")
			Cutscene.face("aurelia", "sylvaris")
			Cutscene.anim("aurelia", "idle")
		&"lumen_awakens":
			var lumen := get_tree().get_first_node_in_group(&"lumen") as Lumen
			if lumen:
				Cutscene.involve(lumen)
				AudioManager.play(&"world_lumen_awaken", runtime.player.global_position)
				await lumen.awaken(runtime.player.global_position + Vector3(0.5, 1.4, -0.4))
		&"sylvaris_leaves":
			Cutscene.face("sylvaris", "ignis_gate")
			await Cutscene.wait(sylvaris.play_anim(&"take_off"))
		&"elder_returns":
			_show_villagers()
			Cutscene.spawn("elder", "elder_door")


# --- Helpers -------------------------------------------------------------------------------------

## Plays one title of the prologue as a cutscene. False if the region closed while it played (quitting).
func _scene(title: StringName) -> bool:
	var scene := StoryScene.new()
	scene.resource = DIALOGUE
	scene.title = String(title)
	scene.handler = self
	world.add_child(scene)
	await Cutscene.play_scene(scene, title)
	return is_inside_tree()


func _actor(id: StringName) -> Node3D:
	return Cutscene.actor(String(id))


func _ignis_visual() -> IgnisVisual:
	var ignis := _actor(&"ignis") as Enemy
	return ignis.visual as IgnisVisual if ignis else null


func _spawn_scouts(at_square: bool) -> void:
	for i in 2:
		var scout := SCOUT_SCENE.instantiate() as Enemy
		world.add_child(scout)
		var gate: Vector3 = MARKERS[StringName("scout_gate_%d" % (i + 1))]
		var square: Vector3 = MARKERS[StringName("scout_square_%d" % (i + 1))]
		scout.global_position = square if at_square else gate
		scout.home = square
		scout.face(Vector3.BACK)
		scout.defeated.connect(_on_scout_defeated)
		scouts.append(scout)
		if not at_square:
			Cutscene.walk_to(scout, square, 1.6)


func _clear_scouts() -> void:
	for scout in scouts:
		if is_instance_valid(scout):
			scout.queue_free()
	scouts.clear()


## The villagers run inside while the Emberbound are in the village.
func _hide_villagers() -> void:
	for node in get_tree().get_nodes_in_group(&"npc"):
		var npc := node as Npc
		if npc in _hidden:
			continue
		_hidden.append(npc)
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		npc.collision_layer = 0


func _show_villagers() -> void:
	for npc in _hidden:
		if is_instance_valid(npc):
			npc.visible = true
			npc.process_mode = Node.PROCESS_MODE_INHERIT
			npc.collision_layer = 1
	_hidden.clear()


## `-- --prologue=<beat>` (dev tool): start at a later beat. Returns the beat asked for ("" for none).
func _apply_start_option() -> String:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with(START_OPTION):
			continue
		var start := arg.trim_prefix(START_OPTION)
		var flags: Array[StringName] = []
		match start:
			"attack":
				flags = [FLAG_RANK]
			"ignis":
				flags = [FLAG_RANK, FLAG_SCOUTS]
			"sylvaris":
				flags = [FLAG_RANK, FLAG_SCOUTS, FLAG_IGNIS]
		for flag in flags:
			GameState.set_flag(flag)
		if start == "elder":
			for flag in [FLAG_RANK, FLAG_SCOUTS, FLAG_IGNIS]:
				GameState.set_flag(flag)
		return start
	return ""


func _elder_only() -> void:
	beat = Beat.ELDER
	GameState.set_flag(Lumen.AWAKE_FLAG)
	if not await _scene(&"elder_quest_start"):
		return
	_finish()
