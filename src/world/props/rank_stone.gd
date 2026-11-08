class_name RankStone
extends StaticBody3D
## Elderroot's Rank Stone (prologue rank test, GAME_DESIGN.md §3.6 and §5.2; owner decision 2026-11-07: the Elder
## holds the test here). A tall old stone in the market square with seven rune marks up its face, one per Arcane Rank
## (Spark at the bottom, Sovereign at the top). Touch it (E) and light climbs the marks up to your rank. In the
## prologue the village starts the rank test from `touched`; later it simply shows how far Aurelia has come.

signal touched(by: Player)

const STONE := Color(0.5, 0.5, 0.52)
const RUNE_DARK := Color(0.3, 0.32, 0.36)
const RUNE_LIT := Color(0.62, 0.86, 1.0)
const HEIGHT := 2.5
const MARKS := 7              ## one per rank: Spark … Sovereign
const CLIMB_TIME := 0.35      ## s per mark the light climbs

@export var waypoint_id: StringName = &"rank_stone"

var _marks: Array[MeshInstance3D] = []
var _crystal_material: StandardMaterial3D
var _light: OmniLight3D
var _interactable: InteractableComponent


func _ready() -> void:
	collision_layer = 1  # world
	Waypoint.mark(self, waypoint_id)
	CutsceneActor.tag(self, &"rank_stone")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, HEIGHT, 0.7)
	shape.shape = box
	shape.position = Vector3(0, HEIGHT * 0.5, 0)
	add_child(shape)
	_build()
	_interactable = InteractableComponent.new()
	_interactable.prompt_verb = "Touch the Rank Stone"
	_interactable.prompt_height = HEIGHT + 0.3
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.3
	reach.shape = sphere
	reach.position = Vector3(0, 0.9, -0.5)
	_interactable.add_child(reach)
	add_child(_interactable)
	_interactable.interacted.connect(func(by: Node) -> void: touched.emit(by as Player))


## Light climbs the marks up to rank `rank` (0 = Spark) and stays there for `hold` seconds. Awaitable; runs while
## paused (it is used in cutscenes).
func show_rank(rank: int, hold := 2.5) -> void:
	var top := clampi(rank, 0, MARKS - 1)
	AudioManager.play(&"world_rank_stone", global_position)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if Cutscene.skipping:
		tween.set_speed_scale(CutsceneScene.SKIP_SPEED)
	for i in top + 1:
		tween.tween_callback(_light_mark.bind(i, true))
		tween.tween_interval(CLIMB_TIME)
	tween.tween_property(_light, "light_energy", 1.2, 0.3)
	tween.tween_interval(hold)
	tween.tween_callback(dim)
	await Cutscene.until_done(tween)


func dim() -> void:
	for i in _marks.size():
		_light_mark(i, false)
	_light.light_energy = 0.0


func _light_mark(index: int, on: bool) -> void:
	var material := _marks[index].material_override as StandardMaterial3D
	material.albedo_color = RUNE_LIT if on else RUNE_DARK
	material.emission_enabled = on
	material.emission = RUNE_LIT
	material.emission_energy_multiplier = 2.5
	if on:
		_light.light_energy = 0.4 + 0.15 * index
		_light.position.y = 0.5 + index * (HEIGHT - 0.8) / (MARKS - 1)
		_crystal_material.emission_energy_multiplier = 0.5 + index * 0.6


func _build() -> void:
	var stone := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, HEIGHT, 0.6)
	stone.mesh = mesh
	stone.material_override = ToonMaterials.toon(STONE, 0.3, 0.02)
	stone.position = Vector3(0, HEIGHT * 0.5, 0)
	add_child(stone)
	var cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.2
	cap_mesh.bottom_radius = 0.5
	cap_mesh.height = 0.3
	cap.mesh = cap_mesh
	cap.material_override = ToonMaterials.toon(STONE.darkened(0.1), 0.3, 0.02)
	cap.position = Vector3(0, HEIGHT + 0.15, 0)
	add_child(cap)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.4, 0.25, 1.1)
	base.mesh = base_mesh
	base.material_override = ToonMaterials.toon(STONE.darkened(0.2), 0.3, 0.02)
	base.position = Vector3(0, 0.125, 0)
	add_child(base)
	for i in MARKS:  # the rank marks, wider at the bottom
		var mark := MeshInstance3D.new()
		var mark_mesh := BoxMesh.new()
		mark_mesh.size = Vector3(0.5 - i * 0.04, 0.09, 0.04)
		mark.mesh = mark_mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = RUNE_DARK
		mark.material_override = material
		mark.position = Vector3(0, 0.5 + i * (HEIGHT - 0.8) / (MARKS - 1), -0.31)
		add_child(mark)
		_marks.append(mark)
	_crystal_material = ToonMaterials.glow(RUNE_LIT, 0.5)
	var crystal := MeshInstance3D.new()
	var crystal_mesh := PrismMesh.new()
	crystal_mesh.size = Vector3(0.25, 0.45, 0.25)
	crystal.mesh = crystal_mesh
	crystal.material_override = _crystal_material
	crystal.position = Vector3(0, HEIGHT + 0.52, 0)
	add_child(crystal)
	_light = OmniLight3D.new()
	_light.light_color = RUNE_LIT
	_light.light_energy = 0.0
	_light.omni_range = 4.0
	_light.position = Vector3(0, 0.5, -0.8)
	add_child(_light)
