extends Node3D
## Elderroot Meadow (region "elderroot_meadow"), still the test meadow from Phase 2: a corner of Elderroot built from
## simple shapes, following the world art (World Tree with sunbeams, mossy stone stairs between broken walls, yellow
## flowers, misty cliffs with a waterfall), with the systems of Phases 3–6. Solid objects are StaticBody3D roots with
## their meshes as children, so the camera can fade the whole object when it blocks the view.
## RegionRuntime adds Aurelia, the camera, interface, sky and day/night; the south gate leads to Elderroot Village.
## Start options (after `--`, they skip the title): --spawn=start|viewpoint|combat|wisp|ruins|from_village;
## --open=inventory|grimoire|journal|save|options|crafting; --talk=tamsin; --give=materials; --visual=animated;
## --benchmark=<dir> (PerfOverlay). Press V in game to switch between the placeholder and the animated model.

const GROUND := preload("res://assets/shaders/ground.gdshader")
const GRASS := preload("res://assets/shaders/grass.gdshader")
const STONE := preload("res://assets/shaders/stone_moss.gdshader")
const WATER := preload("res://assets/shaders/water.gdshader")
const THORNLING_SCENE := preload("res://src/actors/enemies/thornling/thornling.tscn")
## Where Thornlings live (away from the spawn, so Aurelia isn't attacked straight away).
const THORNLING_SPOTS: Array[Vector3] = [Vector3(11, 0, -9), Vector3(-7, 0, -19), Vector3(15, 0, -18), Vector3(3, 0, -27)]
const ENEMY_RESPAWN_TIME := 6.0
const EMBER_WISP_SCENE := preload("res://src/actors/enemies/ember_wisp/ember_wisp.tscn")
const WISP_SPOTS: Array[Vector3] = [Vector3(-15, 0, -7), Vector3(20, 0, -14)]
const GUST := preload("res://data/spells/gust.tres")
const MENDING_BLOOM := preload("res://data/spells/mending_bloom.tres")
const SHRINE_POSITION := Vector3(-3.2, 0, 3.5)
const WORKBENCH_POSITION := Vector3(2.0, 0, 8.0)
const GATHER_DIR := "res://data/items/gather/%s.tres"
const RECIPE_DIR := "res://data/recipes/%s.tres"
const RESERVED_RADIUS := 1.6  ## m trees and columns keep away from item spots
const REGION_ID: StringName = &"elderroot_meadow"
## The south gate to Elderroot Village (Phase 6b), and how far trees keep from it.
const VILLAGE_GATE := Vector3(0, 0, 22)
const VILLAGE_GATE_CLEARANCE := 6.0
const VILLAGERS_DIALOGUE := preload("res://dialogue/npcs/elderroot_villagers.dialogue")
const SATCHEL := preload("res://data/items/tamsin_satchel.tres")
const LUMEN_CRYSTAL := preload("res://data/items/lumen_crystal.tres")
const HEALING_POTION := preload("res://data/items/healing_potion.tres")
## Villagers out in the meadow (the Elder and Maren live in Elderroot Village since Phase 6b): [id, name, look, position].
const VILLAGERS: Array[Array] = [
	[&"tamsin", "Tamsin", "res://data/npcs/tamsin.tres", Vector3(2.8, 0, -2.4)],
]
## The old shrine ruins east of the pond (puzzles for Tamsin's satchel): a walled courtyard split by a gated wall.
const RUINS_MIN := Vector3(13, 0, 6)
const RUINS_MAX := Vector3(25, 0, 16)
const RUINS_WALL_HEIGHT := 1.7
const RUINS_DIVIDER_X := 19.0
const RUINS_DOOR_Z := 11.0

const WORLD_LAYER := 1 << 0
const OCCLUDER_LAYER := 1 << 10  # camera_occluder
const GRASS_BLADES := 50000
const FLOWERS := 4000
const POND_CENTER := Vector3(7, 0, 2)
const SPAWN := Vector3(0, 0, 4)
const PLATFORM_CENTER := Vector3(-11, 0, -13)
const PLATFORM_SIZE := Vector3(6, 1.2, 6)
const WORLD_TREE := Vector3(-6, 0, -75)
const SIGN_TEXT := "Elderroot Meadow, test area. Talk to the villagers (E); J opens the journal.\nWASD move · Space dash · Q/R rotate camera · Wheel zoom · Z reset\n" + \
		"Left click staff strike · 1 Light Mote · 2 Lantern Glow · Tab menu (Q/R: Inventory, Grimoire) · E interact\n" + \
		"Find spell tomes and read them at the shrine. Gather flowers, ore, wood and crystals; enemies drop materials.\n" + \
		"Craft potions at the kit by the shrine and accessories at the workbench. Recipes are hidden around the meadow.\n" + \
		"Climb the stairs to the west for a view of the World Tree."

var _rng := RandomNumberGenerator.new()
var _noise: NoiseTexture2D
var _grass: MultiMesh
var _flowers: MultiMesh
var _waterfall_material: StandardMaterial3D
var runtime: RegionRuntime
var _time := 0.0
var _shrine: RestPoint
## [gather node or recipe file id, position], planned before the trees, which keep clear of them.
var _gather_plan: Array[Array] = []
var _scroll_plan: Array[Array] = []
var _reserved: Array[Vector3] = []


func _ready() -> void:
	_rng.seed = 42
	_noise = NoiseTexture2D.new()
	_noise.seamless = true
	_noise.noise = FastNoiseLite.new()
	_noise.noise.frequency = 0.02
	_plan_item_spots()
	runtime = RegionRuntime.new()
	runtime.region_id = REGION_ID
	add_child(runtime)
	runtime.build_sky(self)
	_build_ground()
	_build_grass_and_flowers()
	_build_trees()
	_build_world_tree()
	_build_ruins()
	_build_platform_and_stairs()
	_build_pond()
	_build_cliffs_and_waterfall()
	_build_distant()
	_build_sign()
	_build_shrine()
	_build_tomes()
	_build_items()
	_build_ruins_puzzles()
	_build_villagers()
	_build_village_gate()
	_build_spawns()
	runtime.start()
	for spot in THORNLING_SPOTS:
		_spawn_enemy(THORNLING_SCENE, spot)
	for spot in WISP_SPOTS:
		_spawn_enemy(EMBER_WISP_SCENE, spot)
	Settings.graphics_changed.connect(_apply_graphics)
	_apply_graphics(Settings.graphics)


func _process(delta: float) -> void:
	_time += delta
	_waterfall_material.uv1_offset.y = -_time * 0.6


func _apply_graphics(preset: GraphicsPreset) -> void:
	_grass.visible_instance_count = preset.visible_grass(_grass.instance_count)
	_flowers.visible_instance_count = preset.visible_grass(_flowers.instance_count)


# --- Enemies ------------------------------------------------------------------------------

func _spawn_enemy(scene: PackedScene, spot: Vector3) -> void:
	var enemy: Enemy = scene.instantiate()
	enemy.position = spot
	add_child(enemy)
	enemy.defeated.connect(func(_enemy: Enemy) -> void:
		get_tree().create_timer(ENEMY_RESPAWN_TIME).timeout.connect(_spawn_enemy.bind(scene, spot)))


# --- Environment ---------------------------------------------------------------------------

func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(300, 300)
	_mesh(self, plane, ToonMaterials.shader_material(GROUND, {"noise_tex": _noise}), Vector3.ZERO)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = WORLD_LAYER
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(shape)
	add_child(floor_body)


func _build_grass_and_flowers() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v: Array in [[Vector3(-0.05, 0, 0), Vector2(0, 0)], [Vector3(0.05, 0, 0), Vector2(1, 0)], [Vector3(0, 0.5, 0), Vector2(0.5, 1)]]:
		st.set_normal(Vector3.BACK)
		st.set_uv(v[1])
		st.add_vertex(v[0])
	_grass = _scatter(st.commit(), GRASS_BLADES, 2.0, Vector2(0.7, 1.4), 0.0)
	var grass_node := MultiMeshInstance3D.new()
	grass_node.multimesh = _grass
	grass_node.material_override = ToonMaterials.shader_material(GRASS)
	grass_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass_node)

	var bloom := SphereMesh.new()
	bloom.radius = 0.06
	bloom.height = 0.1
	bloom.radial_segments = 6
	bloom.rings = 3
	var bloom_mat := StandardMaterial3D.new()
	bloom_mat.vertex_color_use_as_albedo = true
	bloom_mat.roughness = 1.0
	bloom.material = bloom_mat
	_flowers = _scatter(bloom, FLOWERS, 1.6, Vector2(0.8, 1.3), 0.28, [Color("f4c542"), Color("fff6dc"), Color("f6a6c8")])
	var flower_node := MultiMeshInstance3D.new()
	flower_node.multimesh = _flowers
	flower_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flower_node)


## Random placements over the meadow, avoiding the path, the pond, the platform and the spawn sign.
func _scatter(mesh: Mesh, count: int, path_clearance: float, scale_range: Vector2, height: float,
		colors: Array[Color] = []) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	var transforms: Array[Transform3D] = []
	while transforms.size() < count:
		var p := Vector3(_rng.randf_range(-40, 40), height, _rng.randf_range(-50, 30))
		if _on_path(p, path_clearance) or p.distance_to(POND_CENTER) < 4.6 or _on_platform(p):
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(scale_range.x, scale_range.y))
		transforms.append(Transform3D(basis, p))
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i % colors.size()])
	return mm


func _build_trees() -> void:
	var trunk_mat := ToonMaterials.toon(Color(0.42, 0.29, 0.19), 0.2, 0.02)
	var leaf_mats: Array[ShaderMaterial] = [
		ToonMaterials.toon(Color(0.3, 0.5, 0.22), 0.3, 0.0, 0.05),
		ToonMaterials.toon(Color(0.38, 0.56, 0.24), 0.3, 0.0, 0.05),
	]
	var placed := 0
	while placed < 70:
		var p := Vector3(_rng.randf_range(-60, 60), 0, _rng.randf_range(-65, 35))
		if p.distance_to(SPAWN) < 8.0 or _on_path(p, 3.5) or p.distance_to(POND_CENTER) < 6.5 or _on_platform(p, 3.0) \
				or _is_reserved(p) or _in_ruins(p, 3.0) or p.distance_to(VILLAGE_GATE) < VILLAGE_GATE_CLEARANCE:
			continue
		var tree := _solid_root(p)
		_add_shape(tree, _cylinder_shape(0.35, 3.2), Vector3(0, 1.6, 0))
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.22
		trunk.bottom_radius = 0.4
		trunk.height = 3.2
		_mesh(tree, trunk, trunk_mat, Vector3(0, 1.6, 0))
		for k in 3:
			var leaves := SphereMesh.new()
			leaves.radius = _rng.randf_range(1.4, 2.1)
			leaves.height = leaves.radius * 2.0
			_mesh(tree, leaves, leaf_mats[k % 2], Vector3(_rng.randf_range(-0.9, 0.9), 3.6 + k * 0.7, _rng.randf_range(-0.9, 0.9)))
		var canopy := Area3D.new()  # lets the camera notice the canopy blocking the view
		canopy.collision_layer = OCCLUDER_LAYER
		canopy.collision_mask = 0
		canopy.monitoring = false
		var canopy_shape := SphereShape3D.new()
		canopy_shape.radius = 2.4
		_add_shape(canopy, canopy_shape, Vector3(0, 4.4, 0))
		tree.add_child(canopy)
		placed += 1


func _build_world_tree() -> void:
	var bark := ToonMaterials.toon(Color(0.4, 0.3, 0.22), 0.25)
	var tree := _solid_root(WORLD_TREE)
	_add_shape(tree, _cylinder_shape(6.0, 34.0), Vector3(0, 17, 0))
	var trunk := CylinderMesh.new()
	trunk.top_radius = 3.5
	trunk.bottom_radius = 7.0
	trunk.height = 34.0
	_mesh(tree, trunk, bark, Vector3(0, 17, 0))
	for i in 7:  # roots spreading over the ground
		var root := CylinderMesh.new()
		root.top_radius = 0.0
		root.bottom_radius = 2.2
		root.height = 14.0
		var a := TAU * i / 7.0
		var mi := _mesh(tree, root, bark, Vector3(cos(a) * 7.0, 1.0, sin(a) * 7.0))
		mi.rotation = Vector3(0, -a, 0)
		mi.rotate_object_local(Vector3.FORWARD, deg_to_rad(80.0))
	var canopy := ToonMaterials.toon(Color(0.33, 0.47, 0.23), 0.45, 0.0, 0.15)
	for i in 16:
		var s := SphereMesh.new()
		s.radius = _rng.randf_range(9.0, 14.0)
		s.height = s.radius * 2.0
		_mesh(tree, s, canopy, Vector3(_rng.randf_range(-20, 20), _rng.randf_range(32, 44), _rng.randf_range(-12, 12)))
	# Sunbeams falling through the canopy (additive light shafts)
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.albedo_color = Color(1.0, 0.86, 0.55, 0.16)
	for i in 6:
		var quad := QuadMesh.new()
		quad.size = Vector2(_rng.randf_range(2.5, 5.0), 48.0)
		var beam := _mesh(self, quad, beam_mat, WORLD_TREE + Vector3(-15 + i * 6.0, 20.0, 14.0))
		beam.rotation_degrees.z = -18.0 + i * 3.0
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_ruins() -> void:
	var stone := ToonMaterials.shader_material(STONE, {"noise_tex": _noise})
	# Arch gate across the path (walk through it; it fades when it blocks the view)
	var gate_z := -6.0
	var gate_x := _path_x(gate_z)
	for side: float in [-2.2, 2.2]:
		_solid_box(Vector3(0.9, 4.2, 0.9), stone, Vector3(gate_x + side, 2.1, gate_z))
	_solid_box(Vector3(5.3, 0.9, 1.0), stone, Vector3(gate_x, 4.6, gate_z))
	var ivy := ToonMaterials.toon(Color(0.27, 0.48, 0.2), 0.2, 0.0, 0.03)
	for i in 6:  # ivy hanging from the arch
		var vine := BoxMesh.new()
		vine.size = Vector3(0.12, _rng.randf_range(0.8, 2.2), 0.08)
		_mesh(self, vine, ivy, Vector3(gate_x - 2.3 + i * 0.9, 4.1 - vine.size.y / 2.0, gate_z - 0.52))
	# Low broken walls along the path (like the stone stairs in the world art)
	for i in 8:
		var z := -9.0 - i * 2.2
		for side: float in [-1.0, 1.0]:
			if _rng.randf() < 0.3:
				continue  # broken gaps
			var h := _rng.randf_range(0.4, 1.1)
			_solid_box(Vector3(0.45, h, 1.8), stone, Vector3(_path_x(z) + side * 2.6, h / 2.0, z))
	# Flat stone slabs on the path near the ruins
	var slab_mat := ToonMaterials.toon(Color(0.62, 0.6, 0.56), 0.15)
	for i in 14:
		var z := -2.0 - i * 1.3
		var slab := BoxMesh.new()
		slab.size = Vector3(_rng.randf_range(0.8, 1.4), 0.06, _rng.randf_range(0.6, 1.0))
		var mi := _mesh(self, slab, slab_mat, Vector3(_path_x(z) + _rng.randf_range(-0.6, 0.6), 0.03, z))
		mi.rotation.y = _rng.randf_range(-0.3, 0.3)
	# Broken columns
	for i in 8:
		var height := _rng.randf_range(0.8, 3.6)
		var p := Vector3(_rng.randf_range(-18, 18), 0, _rng.randf_range(-24, -2))
		if _on_path(p, 3.2) or _on_platform(p, 1.5) or p.distance_to(SPAWN) < 5.0 or _is_reserved(p):
			continue
		var column := CylinderMesh.new()
		column.top_radius = 0.45
		column.bottom_radius = 0.5
		column.height = height
		var body := _solid_root(p + Vector3(0, height / 2.0, 0))
		_add_shape(body, _cylinder_shape(0.5, height), Vector3.ZERO)
		_mesh(body, column, stone, Vector3.ZERO)


## Raised stone platform with stairs. The stairs collide as a smooth ramp (~27°), so Aurelia walks up
## them automatically; the platform's other sides are ledges she can't climb (no jump, FR-WLD-02).
func _build_platform_and_stairs() -> void:
	var stone := ToonMaterials.shader_material(STONE, {"noise_tex": _noise})
	_solid_box(PLATFORM_SIZE, stone, PLATFORM_CENTER + Vector3(0, PLATFORM_SIZE.y / 2.0, 0))
	var front_z := PLATFORM_CENTER.z + PLATFORM_SIZE.z / 2.0
	const STEPS := 4
	const STEP_DEPTH := 0.6
	var run := STEPS * STEP_DEPTH
	var ramp := _solid_root(Vector3(PLATFORM_CENTER.x, 0, front_z + run / 2.0))
	var slope := atan2(PLATFORM_SIZE.y, run)
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(2.2, 0.1, Vector2(run, PLATFORM_SIZE.y).length())
	var ramp_col := CollisionShape3D.new()
	ramp_col.shape = ramp_shape
	ramp_col.position = Vector3(0, PLATFORM_SIZE.y / 2.0 - 0.05, 0)
	ramp_col.rotation.x = slope
	ramp.add_child(ramp_col)
	for k in range(1, STEPS + 1):  # visible steps (k = 1 is the lowest, furthest from the platform)
		var h := PLATFORM_SIZE.y * k / STEPS
		var step := BoxMesh.new()
		step.size = Vector3(2.2, h, STEP_DEPTH)
		_mesh(ramp, step, stone, Vector3(0, h / 2.0, run / 2.0 - STEP_DEPTH * (k - 0.5)))
	# Scenic viewpoint on top, looking at the World Tree
	var viewpoint := ScenicViewpoint.new()
	viewpoint.position = PLATFORM_CENTER + Vector3(0, PLATFORM_SIZE.y + 1.5, 0)
	var area_shape := BoxShape3D.new()
	area_shape.size = Vector3(5.0, 3.0, 5.0)
	_add_shape(viewpoint, area_shape, Vector3.ZERO)
	var marker := Marker3D.new()
	viewpoint.add_child(marker)
	viewpoint.camera_marker = marker
	add_child(viewpoint)
	marker.global_position = PLATFORM_CENTER + Vector3(-2.0, 3.0, 4.0)
	marker.look_at(WORLD_TREE + Vector3(0, 22, 0), Vector3.UP)


func _build_pond() -> void:
	var water := CylinderMesh.new()
	water.top_radius = 4.5
	water.bottom_radius = 4.5
	water.height = 0.04
	water.radial_segments = 48
	_mesh(self, water, ToonMaterials.shader_material(WATER), POND_CENTER + Vector3(0, 0.05, 0))
	var rock := ToonMaterials.toon(Color(0.55, 0.54, 0.52), 0.25, 0.02)
	for i in 14:
		var a := TAU * i / 14.0
		var s := SphereMesh.new()
		s.radius = 0.6
		s.height = 1.2
		var mi := _mesh(self, s, rock, POND_CENTER + Vector3(cos(a) * 4.8, 0.1, sin(a) * 4.8))
		mi.scale = Vector3(_rng.randf_range(0.6, 1.4), _rng.randf_range(0.4, 0.8), _rng.randf_range(0.6, 1.4))


func _build_cliffs_and_waterfall() -> void:
	var stone := ToonMaterials.shader_material(STONE, {"stone": Color(0.6, 0.58, 0.56), "noise_tex": _noise})
	var cliff_pos := Vector3(48, 0, -62)
	_solid_box(Vector3(30, 24, 22), stone, cliff_pos + Vector3(0, 12, 0))
	_solid_box(Vector3(18, 16, 18), stone, cliff_pos + Vector3(-20, 8, 10))
	_waterfall_material = StandardMaterial3D.new()
	_waterfall_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_waterfall_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_waterfall_material.albedo_color = Color(0.85, 0.95, 1.0, 0.85)
	_waterfall_material.albedo_texture = _noise
	_waterfall_material.uv1_scale = Vector3(1.0, 0.25, 1.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(5.0, 24.0)
	_mesh(self, quad, _waterfall_material, cliff_pos + Vector3(-6, 12, 11.1))
	var mist := GPUParticles3D.new()
	mist.amount = 60
	mist.lifetime = 3.0
	mist.preprocess = 3.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3, 0.5, 1)
	pm.gravity = Vector3(0, 0.6, 0)
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.5
	pm.scale_min = 2.0
	pm.scale_max = 4.0
	mist.process_material = pm
	var puff := SphereMesh.new()
	puff.radius = 0.8
	puff.height = 1.6
	var puff_mat := StandardMaterial3D.new()
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.albedo_color = Color(1, 1, 1, 0.18)
	puff.material = puff_mat
	mist.draw_pass_1 = puff
	mist.position = cliff_pos + Vector3(-6, 0.5, 12)
	add_child(mist)


func _build_distant() -> void:
	var mountain := ToonMaterials.toon(Color(0.52, 0.55, 0.62), 0.1)
	for d: Array in [[Vector3(-120, 0, -150), 70.0], [Vector3(60, 0, -170), 90.0], [Vector3(150, 0, -120), 60.0], [Vector3(-170, 0, -60), 55.0]]:
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = d[1] * 0.8
		c.height = d[1]
		_mesh(self, c, mountain, d[0] + Vector3(0, d[1] / 2.0, 0))
	var tower := ToonMaterials.shader_material(STONE, {"stone": Color(0.72, 0.7, 0.68), "noise_tex": _noise})
	for p: Vector3 in [Vector3(-42, 0, -105), Vector3(30, 0, -115), Vector3(-60, 0, -85)]:
		var t := BoxMesh.new()
		t.size = Vector3(5, 26, 5)
		_mesh(self, t, tower, p + Vector3(0, 13, 0))


# --- Interactive bits ----------------------------------------------------------------------

func _build_sign() -> void:
	var wood := ToonMaterials.toon(Color(0.5, 0.35, 0.22), 0.25, 0.015)
	var sign := _solid_root(SPAWN + Vector3(2.4, 0, -2.0))
	_add_shape(sign, _cylinder_shape(0.08, 1.2), Vector3(0, 0.6, 0))
	var post := CylinderMesh.new()
	post.top_radius = 0.06
	post.bottom_radius = 0.07
	post.height = 1.3
	_mesh(sign, post, wood, Vector3(0, 0.65, 0))
	var board := BoxMesh.new()
	board.size = Vector3(0.9, 0.5, 0.06)
	_mesh(sign, board, wood, Vector3(0, 1.2, 0))
	var interactable := InteractableComponent.new()
	interactable.prompt_verb = "Read"
	var range_shape := SphereShape3D.new()
	range_shape.radius = 0.6
	_add_shape(interactable, range_shape, Vector3(0, 0.8, 0))
	sign.add_child(interactable)
	interactable.interacted.connect(func(_by: Node) -> void: runtime.show_toast(SIGN_TEXT))


## The Lantern Shrine near the start: rest here to heal, set the respawn point and read spell tomes.
func _build_shrine() -> void:
	_shrine = RestPoint.new()
	_shrine.position = SHRINE_POSITION
	add_child(_shrine)


## Spell tomes: Gust waits on the scenic platform (a reward for climbing); Mending Bloom is hidden under
## the arch gate until Lantern Glow reveals it (and needs Magic Power 20 to read).
func _build_tomes() -> void:
	var gust := SpellTome.new()
	gust.spell = GUST
	gust.persist_id = &"elderroot_tome_gust"
	gust.position = PLATFORM_CENTER + Vector3(1.6, PLATFORM_SIZE.y, -1.2)
	add_child(gust)
	var bloom := SpellTome.new()
	bloom.spell = MENDING_BLOOM
	bloom.persist_id = &"elderroot_tome_mending_bloom"
	bloom.hidden = true
	bloom.position = Vector3(_path_x(-6.0), 0, -6.0)
	add_child(bloom)


# --- Items & crafting (Phase 5) ----------------------------------------------------------------

## Where gather nodes and recipe scrolls go: beside the path (trees and columns keep 3.2+ m from it), on the pond
## rim (trees keep 6.5 m from its centre), near the start, and on the platform. Planned first so trees avoid them.
func _plan_item_spots() -> void:
	var beside_path := func(z: float, side: float) -> Vector3: return Vector3(_path_x(z) + side * 3.3, 0, z)
	var pond_rim := func(degrees: float) -> Vector3:
		return POND_CENTER + Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees)) * 5.8
	_gather_plan = [
		["sunpetal_patch", Vector3(-3.5, 0, 9.0)], ["sunpetal_patch", Vector3(-6.0, 0, 6.5)],
		["sunpetal_patch", beside_path.call(-11.0, 1.0)],
		["moonbloom_patch", pond_rim.call(-30.0)], ["moonbloom_patch", pond_rim.call(-140.0)],
		["elderwood_branch", beside_path.call(-18.0, -1.0)], ["elderwood_branch", beside_path.call(-22.0, 1.0)],
		["iron_ore_vein", beside_path.call(-25.0, -1.0)], ["iron_ore_vein", Vector3(6.0, 0, 10.0)],
		["lumen_crystal_cluster", PLATFORM_CENTER + Vector3(-1.6, PLATFORM_SIZE.y, 1.4)],
		["lumen_crystal_cluster", beside_path.call(-8.0, 1.0)],
	]
	_scroll_plan = [
		["ember_ward_ring", Vector3(17.5, 0, -10.5)],
		["swift_quill_charm", Vector3(13.5, 0, -22.5)],
	]
	_reserved = [WORKBENCH_POSITION]
	for villager: Array in VILLAGERS:
		_reserved.append(villager[3])
	for plan: Array in _gather_plan + _scroll_plan:
		_reserved.append(plan[1])


func _is_reserved(p: Vector3) -> bool:
	return _reserved.any(func(spot: Vector3) -> bool:
		return Vector2(p.x - spot.x, p.z - spot.z).length() < RESERVED_RADIUS)


func _build_items() -> void:
	for plan: Array in _gather_plan:
		var node := GatherNode.new()
		node.persist_id = StringName("meadow_gather_%d" % _gather_plan.find(plan))
		node.data = load(GATHER_DIR % plan[0])
		node.position = plan[1]
		node.rotation.y = _rng.randf() * TAU
		add_child(node)
	for plan: Array in _scroll_plan:
		var scroll := RecipeScroll.new()
		scroll.recipe = load(RECIPE_DIR % plan[0])
		scroll.persist_id = StringName("elderroot_recipe_%s" % plan[0])
		scroll.position = plan[1]
		add_child(scroll)
	var workbench := CraftingStation.new()
	workbench.station = RecipeData.Station.WORKBENCH
	workbench.position = WORKBENCH_POSITION
	workbench.rotation.y = PI  # its tools face the start
	add_child(workbench)


## Elderroot villagers: talk to them (E). Conversations come from dialogue/npcs/elderroot_villagers.dialogue.
func _build_villagers() -> void:
	for villager: Array in VILLAGERS:
		var npc := Npc.villager(villager[0], villager[1], load(villager[2]), VILLAGERS_DIALOGUE)
		npc.position = villager[3]
		add_child(npc)
		npc.face_point(SPAWN)


## Where Aurelia can appear: the start, arrivals from the village, and test spots (`-- --spawn=<id>`).
func _build_spawns() -> void:
	var spawns := {
		&"start": SPAWN,
		&"from_village": VILLAGE_GATE + Vector3(0, 0, -4.0),
		&"viewpoint": PLATFORM_CENTER + Vector3(0, PLATFORM_SIZE.y, 0),
		&"combat": THORNLING_SPOTS[0] + Vector3(0, 0, 3.5),
		&"wisp": WISP_SPOTS[0] + Vector3(2, 0, 6.5),
		&"ruins": Vector3(RUINS_MIN.x - 2.5, 0, RUINS_DOOR_Z),
	}
	for id: StringName in spawns:
		var spawn := RegionSpawn.new()
		spawn.spawn_id = id
		spawn.position = spawns[id]
		add_child(spawn)


## Two posts with a hanging sign at the meadow's south edge; walking through leads to Elderroot Village.
func _build_village_gate() -> void:
	var wood := ToonMaterials.toon(Color(0.5, 0.35, 0.22), 0.25, 0.015)
	for side: float in [-1.8, 1.8]:
		var post := _solid_root(VILLAGE_GATE + Vector3(side, 0, 0))
		_add_shape(post, _cylinder_shape(0.14, 2.8), Vector3(0, 1.4, 0))
		var pole := CylinderMesh.new()
		pole.top_radius = 0.11
		pole.bottom_radius = 0.14
		pole.height = 2.8
		_mesh(post, pole, wood, Vector3(0, 1.4, 0))
	var beam := BoxMesh.new()
	beam.size = Vector3(4.2, 0.18, 0.2)
	_mesh(self, beam, wood, VILLAGE_GATE + Vector3(0, 2.75, 0))
	var board := BoxMesh.new()
	board.size = Vector3(1.6, 0.45, 0.06)
	_mesh(self, board, wood, VILLAGE_GATE + Vector3(0, 2.3, 0))
	var exit := RegionExit.new()
	exit.target_region = &"elderroot_village"
	exit.target_spawn = &"from_meadow"
	exit.size = Vector3(3.4, 3.0, 1.2)
	exit.position = VILLAGE_GATE + Vector3(0, 0, 1.0)
	add_child(exit)


func _in_ruins(p: Vector3, margin: float) -> bool:
	return p.x > RUINS_MIN.x - margin and p.x < RUINS_MAX.x + margin and p.z > RUINS_MIN.z - margin \
			and p.z < RUINS_MAX.z + margin


## The old shrine ruins (Phase 6a puzzles, FR-PUZ-01/02/06/07). Teach, then test:
## 1. Two lantern braziers by the inner gate: light both (Light Mote or Lantern Glow) and the gate sinks.
## 2. Behind it, a ledge too high to climb: Lantern Glow reveals spirit steps up to Tamsin's satchel.
## 3. Optional: Gust pushes a stone block onto a plate, unlocking a chest.
func _build_ruins_puzzles() -> void:
	var stone := ToonMaterials.shader_material(STONE, {"noise_tex": _noise})
	var h := RUINS_WALL_HEIGHT
	var size := RUINS_MAX - RUINS_MIN
	var center := (RUINS_MIN + RUINS_MAX) * 0.5
	_solid_box(Vector3(size.x, h, 0.6), stone, Vector3(center.x, h * 0.5, RUINS_MIN.z))  # north wall
	_solid_box(Vector3(size.x, h, 0.6), stone, Vector3(center.x, h * 0.5, RUINS_MAX.z))  # south wall
	_solid_box(Vector3(0.6, h, size.z), stone, Vector3(RUINS_MAX.x, h * 0.5, center.z))  # east wall
	_wall_with_door(RUINS_MIN.x, h, 2.4, stone)  # west wall: open entrance
	var gate_gap := 2.4
	_wall_with_door(RUINS_DIVIDER_X, h + 0.5, gate_gap, stone)  # inner wall: the gate fills the gap
	var gate := PuzzleGate.new()
	gate.width = gate_gap
	gate.height = h + 0.5
	gate.position = Vector3(RUINS_DIVIDER_X, 0, RUINS_DOOR_Z)
	gate.rotation.y = PI * 0.5
	add_child(gate)
	var braziers: Array[Node] = []
	for dz: float in [-2.2, 2.2]:
		var brazier := LanternBrazier.new()
		brazier.persist_id = StringName("ruins_brazier_%d" % braziers.size())
		brazier.position = Vector3(RUINS_DIVIDER_X - 1.3, 0, RUINS_DOOR_Z + dz)
		add_child(brazier)
		braziers.append(brazier)
	_puzzle(&"ruins_gate", "lumen_hint_braziers", Vector3(RUINS_DIVIDER_X - 2.0, 0, RUINS_DOOR_Z), braziers, [gate])
	# The ledge with Tamsin's satchel, and the hidden steps up to it (built along -Z).
	var ledge_height := 1.4
	var ledge_size := Vector3(3.0, ledge_height, 3.5)
	var ledge_pos := Vector3(RUINS_MAX.x - ledge_size.x * 0.5 - 0.3, ledge_height * 0.5, RUINS_MIN.z + ledge_size.z * 0.5 + 0.3)
	_solid_box(ledge_size, stone, ledge_pos)
	var steps := HiddenSteps.new()
	steps.persist_id = &"ruins_spirit_steps"
	steps.height = ledge_height
	steps.position = Vector3(ledge_pos.x, 0, ledge_pos.z + ledge_size.z * 0.5 + steps.steps * steps.step_depth)
	add_child(steps)
	_puzzle(&"ruins_ledge", "lumen_hint_steps", steps.position, [steps], [])
	var satchel := ItemPickup.new()
	satchel.item = SATCHEL
	satchel.persist_id = &"ruins_tamsin_satchel"
	satchel.position = ledge_pos + Vector3(0.3, ledge_height * 0.5, -0.6)
	add_child(satchel)
	# Optional: push the block onto the plate to unlock the chest.
	var block := PushBlock.new()
	block.persist_id = &"ruins_push_block"
	block.position = Vector3(RUINS_DIVIDER_X + 1.6, 0, RUINS_DOOR_Z + 1.6)
	add_child(block)
	var plate := PressurePlate.new()
	plate.position = block.position + Vector3(0, 0, block.cell)
	add_child(plate)
	var chest := Chest.new()
	chest.persist_id = &"ruins_chest"
	chest.locked = true
	chest.contents = [LUMEN_CRYSTAL, LUMEN_CRYSTAL, HEALING_POTION] as Array[ItemData]
	chest.position = Vector3(RUINS_MAX.x - 1.4, 0, RUINS_MAX.z - 1.2)
	chest.rotation.y = -PI * 0.5  # opening towards the courtyard
	add_child(chest)
	_puzzle(&"ruins_block", "lumen_hint_block", block.position, [plate], [chest])


## A wall along Z at `x` across the ruins, with a doorway of `gap` metres centred on RUINS_DOOR_Z.
func _wall_with_door(x: float, h: float, gap: float, material: Material) -> void:
	var north_len := RUINS_DOOR_Z - gap * 0.5 - RUINS_MIN.z
	var south_len := RUINS_MAX.z - (RUINS_DOOR_Z + gap * 0.5)
	_solid_box(Vector3(0.6, h, north_len), material, Vector3(x, h * 0.5, RUINS_MIN.z + north_len * 0.5))
	_solid_box(Vector3(0.6, h, south_len), material, Vector3(x, h * 0.5, RUINS_MAX.z - south_len * 0.5))


func _puzzle(id: StringName, hint: String, pos: Vector3, parts: Array[Node], targets: Array[Node]) -> Puzzle:
	var puzzle := Puzzle.new()
	puzzle.puzzle_id = id
	puzzle.hint_cue = hint
	puzzle.position = pos
	add_child(puzzle)
	puzzle.setup(parts, targets)
	return puzzle


# --- Helpers -------------------------------------------------------------------------------

func _path_x(z: float) -> float:
	return sin(z * 0.08) * 5.0


func _on_path(p: Vector3, half_width: float) -> bool:
	return absf(p.x - _path_x(p.z)) < half_width


func _on_platform(p: Vector3, margin := 0.5) -> bool:
	var half := PLATFORM_SIZE / 2.0 + Vector3(margin, 0, margin)
	return absf(p.x - PLATFORM_CENTER.x) < half.x and p.z > PLATFORM_CENTER.z - half.z \
			and p.z < PLATFORM_CENTER.z + half.z + 2.6  # include the stairs


func _mesh(parent: Node, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi


func _solid_root(pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.set_meta(&"surface", "stone")  # footsteps (FR-AUD-06); the open ground stays grass
	body.position = pos
	add_child(body)
	return body


func _solid_box(size: Vector3, material: Material, pos: Vector3) -> StaticBody3D:
	var body := _solid_root(pos)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_shape(body, shape, Vector3.ZERO)
	var box := BoxMesh.new()
	box.size = size
	_mesh(body, box, material, Vector3.ZERO)
	return body


func _cylinder_shape(radius: float, height: float) -> CylinderShape3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	return shape


func _add_shape(parent: Node, shape: Shape3D, pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = pos
	parent.add_child(col)
