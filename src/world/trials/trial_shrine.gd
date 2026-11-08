class_name TrialShrine
extends Node3D
## A Trial shrine (FR-QST-03, FR-MAG-07; GAME_DESIGN.md §11), built from TrialData. The Gust Trial (owner decision
## 2026-11-07): a round courtyard with an old altar, veiled in mist. Walking in for the first time finds the place,
## plays the shrine's voice (and the owner's story music). Lantern Glow reveals the runes hidden in the mist; lighting
## them in order (one curl, two, three) wakes the shrine: a ring of wind seals the courtyard and short waves of
## enemies come. Beating the last wave passes the Trial: the wind falls, the mist clears and the spell tome rises on
## the altar. Falling in the fight lowers the wind; walking back in starts the waves again (the runes stay awake).
## Remembers everything through GameState (the puzzle, the passed flag, the tome).

signal fight_started
signal passed

const PLAYER_LAYER := 1 << 1
const STONE := Color(0.62, 0.62, 0.58)
const PAVING := Color(0.56, 0.55, 0.5)
const MIST := Color(0.92, 0.95, 0.96)
const MIST_PUFFS := 14
const ENTRY_MARGIN := 1.5   ## m inside the ring before the waves start

@export var data: TrialData

var runes: Array[TrialRune] = []
var sequence: RuneSequence
var puzzle: Puzzle
var ring: WindRing
var fighting := false
var wave_index := -1
var alive: Array[Enemy] = []
var _mist: Array[MeshInstance3D] = []
var _mist_material: StandardMaterial3D
var _altar_glow: OmniLight3D
var _altar: Node3D
var _player: Player
var _time := 0.0
var _player_inside := false


func _ready() -> void:
	add_to_group(&"trial_shrine")
	Waypoint.mark(self, &"trial_shrine")
	_build_courtyard()
	_build_mist()
	ring = WindRing.new()
	ring.radius = data.radius
	add_child(ring)
	var landmark := Landmark.new()
	landmark.place_id = data.place_id
	landmark.display_name = data.display_name
	landmark.radius = data.radius + 2.0
	add_child(landmark)
	landmark.discovered.connect(func(_place: Landmark) -> void: _on_found())
	_build_runes()
	_build_trigger()
	if is_passed():
		_clear_mist(true)
		_place_tome()


func is_passed() -> bool:
	return data.passed_flag != &"" and GameState.has_flag(data.passed_flag)


func runes_awake() -> bool:
	return puzzle != null and puzzle.is_solved


func _process(delta: float) -> void:
	_time += delta
	for i in _mist.size():
		var puff := _mist[i]
		puff.position.x += sin(_time * 0.3 + i) * delta * 0.3
		puff.position.z += cos(_time * 0.25 + i * 1.3) * delta * 0.3


# --- The puzzle's target: the runes are all lit ------------------------------------------------

## Called by the Puzzle when the runes are lit in order (instant = already solved when the game loaded).
func activate(instant: bool) -> void:
	sequence.set_complete()
	_altar_glow.light_energy = 1.0
	if instant or is_passed():
		return
	await _talk(data.test_cue)
	if is_inside_tree() and _player_inside:  # lit from outside the ring: the wind rises when she walks in
		start_fight()


# --- The fight -------------------------------------------------------------------------------------

## The ring of wind rises and the first wave comes (also used by tests).
func start_fight() -> void:
	if fighting or is_passed() or not runes_awake():
		return
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player and not _player.respawned.is_connected(_on_player_respawned):
		_player.respawned.connect(_on_player_respawned)
	fighting = true
	ring.set_up(true)
	AudioManager.play(&"world_wind_ring", global_position)
	fight_started.emit()
	wave_index = -1
	_next_wave()


func _next_wave() -> void:
	if not fighting:
		return
	wave_index += 1
	if wave_index >= data.waves.size():
		_pass()
		return
	var wave := data.waves[wave_index]
	for i in wave.enemies.size():
		var a := TAU * (i + 0.5 * wave_index) / maxf(wave.enemies.size(), 1.0) + PI * 0.5
		var enemy := wave.enemies[i].instantiate() as Enemy
		get_parent().add_child(enemy)
		enemy.global_position = global_position + Vector3(cos(a), 0, sin(a)) * data.spawn_distance
		enemy.home = enemy.global_position
		enemy.defeated.connect(_on_enemy_defeated)
		alive.append(enemy)
		AudioManager.play(&"world_trial_spawn", enemy.global_position)
		enemy.state_machine.transition_to.call_deferred(&"Chase")


func _on_enemy_defeated(enemy: Enemy) -> void:
	alive.erase(enemy)
	if alive.is_empty() and fighting:
		await get_tree().create_timer(data.wave_delay).timeout
		_next_wave()


func _pass() -> void:
	fighting = false
	ring.set_up(false)
	GameState.set_flag(data.passed_flag)
	AudioManager.play_stinger(&"stg_trial_passed")
	_clear_mist(false)
	_place_tome()
	passed.emit()
	_talk(data.complete_cue)


## Aurelia fell: the wind lowers and the enemies vanish; the runes stay awake.
func _on_player_respawned() -> void:
	if not fighting:
		return
	fighting = false
	ring.set_up(false)
	for enemy in alive:
		if is_instance_valid(enemy):
			enemy.queue_free()
	alive.clear()


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_player_inside = true
		if runes_awake() and not is_passed() and not fighting and not (body as Player).health.is_dead():
			start_fight.call_deferred()  # not inside the physics callback: the fight adds enemies


# --- Finding it, the tome --------------------------------------------------------------------------

func _on_found() -> void:
	if is_passed():
		return
	if data.found_music != &"":
		AudioManager.play_music(data.found_music)
	_talk(data.intro_cue)


func _place_tome() -> void:
	if data.spell == null or has_node(^"Tome"):
		return
	var tome := SpellTome.new()
	tome.name = &"Tome"
	tome.spell = data.spell
	tome.persist_id = data.tome_id()
	tome.position = _altar.position + Vector3(0, 0.35, 0)  # the book hovers just above the altar
	add_child(tome)
	Waypoint.mark(tome, data.spell.id)


func _talk(cue: String) -> void:
	if cue == "" or data.dialogue == null:
		return
	var box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if box == null or box.is_open():
		return
	box.start(data.dialogue, cue)
	if box.is_open():
		await box.finished


func _on_altar_used(_by: Node) -> void:
	if is_passed():
		_talk(data.repeat_cue)
	elif not runes_awake():
		_talk(data.intro_cue)


func _on_wrong_order() -> void:
	var lumen := get_tree().get_first_node_in_group(&"lumen") as Lumen
	if lumen and data.hint_cue != "":
		lumen.speaker.bark(data.hint_cue, 2, 8.0)


# --- Building ------------------------------------------------------------------------------------

func _build_courtyard() -> void:
	var floor_mesh := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = data.radius + 0.5
	disk.bottom_radius = data.radius + 0.5
	disk.height = 0.06
	disk.radial_segments = 40
	floor_mesh.mesh = disk
	floor_mesh.material_override = ToonMaterials.toon(PAVING, 0.2)
	floor_mesh.position = Vector3(0, 0.02, 0)
	add_child(floor_mesh)
	for i in 3:  # rings of paving
		var band := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 2.0 + i * 2.6
		torus.outer_radius = torus.inner_radius + 0.15
		torus.rings = 48
		band.mesh = torus
		band.material_override = ToonMaterials.toon(PAVING.darkened(0.2), 0.2)
		band.scale = Vector3(1, 0.1, 1)
		band.position = Vector3(0, 0.05, 0)
		add_child(band)
	# Low standing stones round the edge, each with a carved curl of wind.
	var stone_material := ToonMaterials.toon(STONE, 0.3, 0.02)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.set_meta(&"surface", "stone")
	add_child(body)
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		var at := Vector3(cos(a), 0, sin(a)) * (data.radius + 1.2)
		var pillar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.7, 1.6 + 0.3 * (i % 3), 0.5)
		pillar.mesh = mesh
		pillar.material_override = stone_material
		pillar.position = at + Vector3(0, mesh.size.y * 0.5, 0)
		pillar.rotation.y = -a + PI * 0.5
		body.add_child(pillar)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = mesh.size
		shape.shape = box
		shape.position = pillar.position
		shape.rotation = pillar.rotation
		body.add_child(shape)
	# The altar: a stepped plinth with a wind spiral on top.
	_altar = Node3D.new()
	add_child(_altar)
	var plinth := MeshInstance3D.new()
	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = 0.7
	plinth_mesh.bottom_radius = 0.9
	plinth_mesh.height = 0.9
	plinth.mesh = plinth_mesh
	plinth.material_override = stone_material
	plinth.position = Vector3(0, 0.45, 0)
	_altar.add_child(plinth)
	var step := MeshInstance3D.new()
	var step_mesh := CylinderMesh.new()
	step_mesh.top_radius = 1.4
	step_mesh.bottom_radius = 1.5
	step_mesh.height = 0.2
	step.mesh = step_mesh
	step.material_override = stone_material
	step.position = Vector3(0, 0.1, 0)
	_altar.add_child(step)
	var spiral := MeshInstance3D.new()
	var spiral_mesh := TorusMesh.new()
	spiral_mesh.inner_radius = 0.35
	spiral_mesh.outer_radius = 0.45
	spiral.mesh = spiral_mesh
	spiral.material_override = ToonMaterials.glow(TrialRune.WIND, 1.2)
	spiral.position = Vector3(0, 0.92, 0)
	_altar.add_child(spiral)
	var altar_shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.85
	cylinder.height = 0.9
	altar_shape.shape = cylinder
	altar_shape.position = Vector3(0, 0.45, 0)
	body.add_child(altar_shape)
	_altar_glow = OmniLight3D.new()
	_altar_glow.light_color = TrialRune.WIND
	_altar_glow.light_energy = 0.0
	_altar_glow.omni_range = 5.0
	_altar_glow.position = Vector3(0, 1.6, 0)
	_altar.add_child(_altar_glow)
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = "Listen to the shrine"
	interactable.prompt_height = 1.8
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	reach.shape = sphere
	reach.position = Vector3(0, 0.8, 0)
	interactable.add_child(reach)
	_altar.add_child(interactable)
	interactable.interacted.connect(_on_altar_used)


func _build_mist() -> void:
	_mist_material = StandardMaterial3D.new()
	_mist_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mist_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mist_material.albedo_color = Color(MIST, 0.32)
	_mist_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 1107
	for i in MIST_PUFFS:
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(1.6, 2.6)
		sphere.height = sphere.radius * 0.7
		sphere.radial_segments = 16
		sphere.rings = 6
		puff.mesh = sphere
		puff.material_override = _mist_material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := rng.randf() * TAU
		puff.position = Vector3(cos(a), 0, sin(a)) * rng.randf_range(1.5, data.radius - 1.0) + Vector3(0, 0.5, 0)
		add_child(puff)
		_mist.append(puff)


func _clear_mist(instant: bool) -> void:
	if instant:
		for puff in _mist:
			puff.visible = false
		return
	var tween := create_tween()
	tween.tween_property(_mist_material, "albedo_color:a", 0.0, 2.5)
	tween.tween_callback(func() -> void:
		for puff in _mist:
			puff.visible = false)


func _build_runes() -> void:
	var count := data.rune_count
	for i in count:
		var rune := TrialRune.new()
		rune.order = i + 1
		rune.persist_id = StringName("%s_rune_%d" % [data.id, i + 1])
		var degrees := data.rune_angles[i] if i < data.rune_angles.size() else 360.0 * i / count
		var a := deg_to_rad(degrees)
		rune.position = Vector3(cos(a), 0, sin(a)) * data.rune_distance
		add_child(rune)
		rune.rotation.y = Player.yaw_of(-rune.position)  # its marks face the altar
		runes.append(rune)
	sequence = RuneSequence.new()
	add_child(sequence)
	sequence.setup(runes)
	sequence.wrong.connect(_on_wrong_order)
	puzzle = Puzzle.new()
	puzzle.puzzle_id = data.puzzle_id()
	puzzle.hint_cue = data.hint_cue
	puzzle.hint_radius = data.radius
	add_child(puzzle)
	var parts: Array[Node] = [sequence]
	var targets: Array[Node] = [self]
	puzzle.setup(parts, targets)


func _build_trigger() -> void:
	var trigger := Area3D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = PLAYER_LAYER
	trigger.monitorable = false
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = data.radius - ENTRY_MARGIN
	cylinder.height = 4.0
	shape.shape = cylinder
	shape.position = Vector3(0, 2.0, 0)
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(func(body: Node3D) -> void:
		if body is Player:
			_player_inside = false)
