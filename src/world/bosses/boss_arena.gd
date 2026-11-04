class_name BossArena
extends Node3D
## A boss arena (FR-BOS-02): a round, scorched clearing. When Aurelia walks in, a ring of fire seals it, the boss
## music starts and the boss wakes. Beating the boss lowers the fire, gives the rewards and sets the boss's flag (it
## stays beaten: later visits find only the scorched ground). If Aurelia falls, the fire lowers and the boss resets to
## full (GAME_DESIGN.md §7: "bosses reset to full"). RegionRuntime shows the boss bar from fight_started/ended.

signal fight_started(boss: Boss)
signal fight_ended(won: bool)
signal rewarded(items: Array[ItemData], recipes: Array[RecipeData])

const PLAYER_LAYER := 1 << 1
const WORLD_LAYER := 1 << 0
const WALL_SEGMENTS := 28
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.6
const FLAME_HEIGHT := 1.3      ## m: low, so the high camera sees over the near side
const ENTRY_MARGIN := 2.0       ## m inside the fire line before the fight starts (never trapped in the wall)
const SCORCH := Color(0.16, 0.12, 0.1)
const FLAME := Color(1.0, 0.45, 0.12)

@export var boss_scene: PackedScene
@export var radius := 10.0

var boss: Boss
var fighting := false
var _wall_shapes: Array[CollisionShape3D] = []
var _flames: Array[MeshInstance3D] = []
var _time := 0.0
var _player: Player


func _ready() -> void:
	add_to_group(&"boss_arena")
	_build_ground()
	_build_walls()
	_set_walls(false, true)
	var trigger := Area3D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = PLAYER_LAYER
	trigger.monitorable = false
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius - ENTRY_MARGIN
	cylinder.height = 4.0
	shape.shape = cylinder
	shape.position = Vector3(0, 2.0, 0)
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_on_body_entered)
	if boss_scene and not is_beaten():
		boss = boss_scene.instantiate() as Boss
		add_child(boss)
		boss.home = boss.global_position
		boss.face(Vector3.BACK)
		boss.defeated.connect(_on_boss_defeated)


func is_beaten() -> bool:
	var data: BossData = boss.boss_data() if boss else null
	var flag := data.defeat_flag if data else _scene_flag()
	return flag != &"" and GameState.has_flag(flag)


func _process(delta: float) -> void:
	if not fighting:
		return
	_time += delta
	for i in _flames.size():
		_flames[i].scale.y = 0.85 + 0.2 * sin(_time * 7.0 + i * 1.7)


## Seals the arena and wakes the boss (also used by tests).
func start_fight() -> void:
	if fighting or boss == null or boss.health.is_dead():
		return
	fighting = true
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player and not _player.respawned.is_connected(_on_player_respawned):
		_player.respawned.connect(_on_player_respawned)
	_set_walls(true, false)
	AudioManager.play(&"world_fire_wall", global_position)
	var data := boss.boss_data()
	AudioManager.set_combat_layer(&"")
	if data.music != &"":
		AudioManager.play_music(data.music)
	boss.begin_fight()
	fight_started.emit(boss)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not (body as Player).health.is_dead():
		start_fight()


func _on_boss_defeated(_enemy: Enemy) -> void:
	fighting = false
	_set_walls(false, false)
	var data := boss.boss_data()
	if data.defeat_flag != &"":
		GameState.set_flag(data.defeat_flag)
	for item in data.reward_items:
		Inventory.add(item)
	for recipe in data.reward_recipes:
		Inventory.learn_recipe(recipe)
	AudioManager.play_stinger(&"stg_boss_defeated")
	EventBus.boss_defeated.emit(data.id)
	rewarded.emit(data.reward_items, data.reward_recipes)
	fight_ended.emit(true)


## Aurelia fell and got up at a shrine: the fire lowers and the boss starts over.
func _on_player_respawned() -> void:
	if not fighting:
		return
	fighting = false
	_set_walls(false, false)
	if is_instance_valid(boss) and not boss.health.is_dead():
		boss.reset_fight()
	fight_ended.emit(false)


func _set_walls(up: bool, instant: bool) -> void:
	for shape in _wall_shapes:
		shape.set_deferred(&"disabled", not up)
	for flame in _flames:
		if instant:
			flame.visible = up
			continue
		flame.visible = true
		var tween := create_tween()
		tween.tween_property(flame, "scale", Vector3.ONE if up else Vector3(1, 0.01, 1), 0.5)
		if not up:
			tween.tween_callback(flame.hide)


func _build_ground() -> void:
	var disk := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius + 1.0
	mesh.bottom_radius = radius + 1.0
	mesh.height = 0.04
	disk.mesh = mesh
	disk.material_override = ToonMaterials.toon(SCORCH, 0.1)
	disk.position = Vector3(0, 0.015, 0)
	add_child(disk)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 14:  # glowing embers in the ash
		var ember := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = rng.randf_range(0.05, 0.12)
		dot.height = dot.radius
		ember.mesh = dot
		ember.material_override = ToonMaterials.glow(FLAME, 2.5)
		var a := rng.randf() * TAU
		ember.position = Vector3(cos(a), 0, sin(a)) * rng.randf_range(1.0, radius - 0.5) + Vector3(0, 0.04, 0)
		ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ember)


func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	add_child(body)
	var flame_material := ToonMaterials.glow(FLAME, 3.0)
	flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_material.albedo_color.a = 0.8
	var segment := TAU * radius / WALL_SEGMENTS
	for i in WALL_SEGMENTS:
		var a := TAU * i / WALL_SEGMENTS
		var at := Vector3(cos(a), 0, sin(a)) * radius
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(segment + 0.2, WALL_HEIGHT, WALL_THICKNESS)
		shape.shape = box
		shape.position = at + Vector3(0, WALL_HEIGHT * 0.5, 0)
		shape.rotation.y = -a + PI * 0.5
		body.add_child(shape)
		_wall_shapes.append(shape)
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = segment * 0.3
		cone.height = FLAME_HEIGHT
		flame.mesh = cone
		flame.material_override = flame_material
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.position = at + Vector3(0, FLAME_HEIGHT * 0.5, 0)
		add_child(flame)
		_flames.append(flame)
	var light := OmniLight3D.new()
	light.light_color = FLAME
	light.light_energy = 0.0
	light.omni_range = radius * 1.4
	light.position = Vector3(0, 3, 0)
	add_child(light)
	fight_started.connect(func(_b: Boss) -> void: create_tween().tween_property(light, "light_energy", 1.6, 0.5))
	fight_ended.connect(func(_won: bool) -> void: create_tween().tween_property(light, "light_energy", 0.0, 0.8))


## The flag of the boss this arena would spawn (to check it is beaten without spawning it).
func _scene_flag() -> StringName:
	if boss_scene == null:
		return &""
	var state := boss_scene.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"data":
			var data := state.get_node_property_value(0, i) as BossData
			return data.defeat_flag if data else &""
	return &""
