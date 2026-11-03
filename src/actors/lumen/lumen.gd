class_name Lumen
extends Node3D
## Lumen, a fragment of the World Tree's spirit (GAME_DESIGN.md §3.2, approved by the owner 2026-11-03): a small blue
## butterfly that follows Aurelia, glows brighter near secrets and offers gentle hints in speech bubbles
## (FR-DLG-05, FR-PUZ-07). Never fights. Tuning: data/dialogue/lumen_hints.tres; lines: dialogue/barks/lumen.dialogue.

const HINTS: LumenHints = preload("res://data/dialogue/lumen_hints.tres")
const BARKS: DialogueResource = preload("res://dialogue/barks/lumen.dialogue")
const WING := Color(0.45, 0.75, 1.0)
const BASE_GLOW := 0.6
const LOW_HEALTH_FLAG := &"lumen_low_health_hint"

## Tuning (the shared file unless a level or test gives another).
var hints: LumenHints = HINTS
var player: Player
var speaker: BarkSpeaker
## puzzle → seconds Aurelia has spent near it since its last progress
var stuck_time: Dictionary[Puzzle, float] = {}
var _progress_seen: Dictionary[Puzzle, int] = {}
var _wings: Array[Node3D] = []
var _light: OmniLight3D
var _time := 0.0
var _secret_near := false


func _ready() -> void:
	_build_body()
	speaker = BarkSpeaker.new()
	speaker.resource = BARKS
	speaker.color = Color(0.75, 0.9, 1.0)
	speaker.position = Vector3(0, 0.45, 0)
	add_child(speaker)


func _process(delta: float) -> void:
	_time += delta
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(&"player") as Player
		if player == null:
			return
		global_position = player.global_position + Vector3(0, hints.height, 0)
	_follow(delta)
	_check_secrets()
	_check_puzzles(delta)
	_check_health()


func _follow(delta: float) -> void:
	var orbit := Vector3(sin(_time * 0.8), 0.0, cos(_time * 0.6)) * hints.orbit_radius
	var target := player.global_position + Vector3(0, hints.height + sin(_time * 1.7) * 0.15, 0) + orbit
	var before := global_position
	global_position = before.lerp(target, 1.0 - exp(-hints.follow_speed * delta))
	var heading := global_position - before
	heading.y = 0.0
	if heading.length() > 0.001:
		rotation.y = Player.yaw_of(heading)
	var flap := sin(_time * 18.0) * 55.0
	_wings[0].rotation_degrees.z = flap
	_wings[1].rotation_degrees.z = -flap


## Glows near hidden things and mentions them now and then.
func _check_secrets() -> void:
	var near := false
	for node in get_tree().get_nodes_in_group(&"revealable"):
		var secret := node as Node3D
		if secret and secret.global_position.distance_to(player.global_position) <= hints.secret_radius:
			near = true
			break
	_light.light_energy = lerpf(_light.light_energy, hints.glow_near_secret if near else BASE_GLOW, 0.05)
	if near and not _secret_near:
		speaker.bark("lumen_secret_nearby", 1, hints.secret_cooldown)
	_secret_near = near


## A hint after Aurelia has spent a while near an unsolved puzzle without any progress (FR-PUZ-07).
func _check_puzzles(delta: float) -> void:
	for node in get_tree().get_nodes_in_group(&"puzzle"):
		var puzzle := node as Puzzle
		if puzzle == null or puzzle.is_solved or puzzle.hint_cue == "":
			continue
		if _progress_seen.get(puzzle, -1) != puzzle.progress_count:
			_progress_seen[puzzle] = puzzle.progress_count
			stuck_time[puzzle] = 0.0
		if puzzle.global_position.distance_to(player.global_position) > puzzle.hint_radius:
			continue
		stuck_time[puzzle] = stuck_time.get(puzzle, 0.0) + delta
		if stuck_time[puzzle] >= hints.stuck_time:
			stuck_time[puzzle] = 0.0
			speaker.bark(puzzle.hint_cue, 2, hints.hint_cooldown)


func _check_health() -> void:
	if player.health.is_dead() or player.health.ratio() >= hints.low_health_ratio or GameState.has_flag(LOW_HEALTH_FLAG):
		return
	GameState.set_flag(LOW_HEALTH_FLAG)
	speaker.bark("lumen_low_health", 3, 0.0)


func _build_body() -> void:
	var material := ToonMaterials.glow(WING, 4.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		add_child(hinge)
		var wing := QuadMesh.new()
		wing.size = Vector2(0.16, 0.12)
		var mi := MeshInstance3D.new()
		mi.mesh = wing
		mi.material_override = material
		mi.position = Vector3(side * 0.08, 0, 0)
		mi.rotation_degrees.x = -90.0
		hinge.add_child(mi)
		_wings.append(hinge)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 0.75, 1.0)
	_light.light_energy = BASE_GLOW
	_light.omni_range = 2.0
	add_child(_light)
