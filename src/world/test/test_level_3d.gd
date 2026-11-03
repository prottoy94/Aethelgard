extends Node3D
## Phase 2 test meadow: a corner of Elderroot built from simple shapes, following the world art
## (World Tree with sunbeams, mossy stone stairs between broken walls, yellow flowers, misty cliffs with a waterfall).
## Aurelia walks here with the hybrid camera. Solid objects are StaticBody3D roots with their meshes as children,
## so the camera can fade the whole object when it blocks the view.
## Start options (after `--`): --spawn=viewpoint puts Aurelia on the scenic platform; --visual=animated uses the animated
## stand-in model; --benchmark=<dir> (PerfOverlay). Press V in game to switch between the placeholder and the animated model.

const GROUND := preload("res://assets/shaders/ground.gdshader")
const GRASS := preload("res://assets/shaders/grass.gdshader")
const STONE := preload("res://assets/shaders/stone_moss.gdshader")
const WATER := preload("res://assets/shaders/water.gdshader")
const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const CAMERA_SETTINGS := preload("res://data/camera/follow_camera.tres")
const ANIM_SET := preload("res://data/animations/humanoid_default.tres")
const PLACEHOLDER := preload("res://src/actors/player/aurelia_placeholder.gd")
const STAND_IN_TINT := Color("7a5a8a")  # plum, like Aurelia's cape

const WORLD_LAYER := 1 << 0
const OCCLUDER_LAYER := 1 << 10  # camera_occluder
const GRASS_BLADES := 50000
const FLOWERS := 4000
const POND_CENTER := Vector3(7, 0, 2)
const SPAWN := Vector3(0, 0, 4)
const PLATFORM_CENTER := Vector3(-11, 0, -13)
const PLATFORM_SIZE := Vector3(6, 1.2, 6)
const WORLD_TREE := Vector3(-6, 0, -75)
const SIGN_TEXT := "Elderroot Meadow, test area.\nWASD move · Space dash · Q/R rotate camera · Wheel zoom · Z reset\nClimb the stairs to the west for a view of the World Tree."

var _rng := RandomNumberGenerator.new()
var _noise: NoiseTexture2D
var _environment: Environment
var _sun: DirectionalLight3D
var _grass: MultiMesh
var _flowers: MultiMesh
var _waterfall_material: StandardMaterial3D
var _lumen: Node3D
var _lumen_wings: Array[Node3D] = []
var _time := 0.0
var _toast: Label
var _toast_timer := 0.0
var player: Player
var _animated := false
var camera_rig: CameraRig


func _ready() -> void:
	_rng.seed = 42
	_noise = NoiseTexture2D.new()
	_noise.seamless = true
	_noise.noise = FastNoiseLite.new()
	_noise.noise.frequency = 0.02
	_build_environment()
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
	_build_lumen()
	_build_toast()
	_spawn_player()
	add_child(PerfOverlay.new())
	Settings.graphics_changed.connect(_apply_graphics)
	_apply_graphics(Settings.graphics)


func _process(delta: float) -> void:
	_time += delta
	_waterfall_material.uv1_offset.y = -_time * 0.6
	_animate_lumen()
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()
	elif event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_V:
		_set_animated(not _animated)


## Switches Aurelia between the shape placeholder and the animated stand-in (until her VRoid model arrives).
func _set_animated(on: bool) -> void:
	_animated = on
	if on:
		var humanoid := HumanoidVisual.new()
		humanoid.model_scene = ANIM_SET.library_scene
		humanoid.anim_set = ANIM_SET
		humanoid.stand_in_tint = STAND_IN_TINT
		player.set_visual(humanoid)
		show_toast("Animated stand-in model (press V to switch back)", 3.0)
	else:
		player.set_visual(PLACEHOLDER.new())
		show_toast("Placeholder Aurelia (press V for the animated stand-in)", 3.0)


func _apply_graphics(preset: GraphicsPreset) -> void:
	preset.apply_to_environment(_environment)
	preset.apply_to_sun(_sun)
	_grass.visible_instance_count = preset.visible_grass(_grass.instance_count)
	_flowers.visible_instance_count = preset.visible_grass(_flowers.instance_count)


func show_toast(text: String, seconds := 6.0) -> void:
	_toast.text = text
	_toast_timer = seconds
	_toast.modulate.a = 1.0


# --- Player & camera -----------------------------------------------------------------------

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = SPAWN
	for arg in OS.get_cmdline_user_args():
		if arg == "--spawn=viewpoint":
			player.position = PLATFORM_CENTER + Vector3(0, PLATFORM_SIZE.y, 0)
	add_child(player)
	if "--visual=animated" in OS.get_cmdline_user_args():
		_set_animated(true)
	camera_rig = CameraRig.new()
	camera_rig.settings = CAMERA_SETTINGS
	camera_rig.target = player
	add_child(camera_rig)
	player.camera_rig = camera_rig


# --- Environment ---------------------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(1.0, 0.82, 0.64)
	sky_mat.ground_horizon_color = Color(1.0, 0.82, 0.64)
	sky_mat.ground_bottom_color = Color(0.2, 0.25, 0.15)
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_energy = 0.55
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.fog_light_color = Color(1.0, 0.86, 0.7)
	_environment.fog_density = 0.004
	_environment.fog_aerial_perspective = 0.4
	_environment.fog_sky_affect = 0.2
	_environment.glow_intensity = 0.9
	_environment.glow_bloom = 0.08
	_environment.glow_hdr_threshold = 0.9
	_environment.adjustment_enabled = true
	_environment.adjustment_saturation = 1.12
	var world_env := WorldEnvironment.new()
	world_env.environment = _environment
	add_child(world_env)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-42, 150, 0)  # afternoon sun: clear anime shadows
	_sun.light_color = Color(1.0, 0.88, 0.7)
	_sun.light_energy = 1.6
	add_child(_sun)


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
		if p.distance_to(SPAWN) < 8.0 or _on_path(p, 3.5) or p.distance_to(POND_CENTER) < 6.5 or _on_platform(p, 3.0):
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
		if _on_path(p, 3.2) or _on_platform(p, 1.5) or p.distance_to(SPAWN) < 5.0:
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
	interactable.interacted.connect(func(_by: Node) -> void: show_toast(SIGN_TEXT))


## Lantern shrine (future rest point, visual only for now).
func _build_shrine() -> void:
	var stone := ToonMaterials.shader_material(STONE, {"noise_tex": _noise})
	var shrine := _solid_root(SPAWN + Vector3(-3.2, 0, -0.5))
	_add_shape(shrine, _cylinder_shape(0.5, 1.2), Vector3(0, 0.6, 0))
	var base := CylinderMesh.new()
	base.top_radius = 0.45
	base.bottom_radius = 0.6
	base.height = 0.6
	_mesh(shrine, base, stone, Vector3(0, 0.3, 0))
	var post := BoxMesh.new()
	post.size = Vector3(0.18, 1.0, 0.18)
	_mesh(shrine, post, stone, Vector3(0, 1.1, 0))
	var lamp := BoxMesh.new()
	lamp.size = Vector3(0.26, 0.3, 0.26)
	_mesh(shrine, lamp, ToonMaterials.glow(Color(1.0, 0.75, 0.4), 3.0), Vector3(0, 1.75, 0))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.45)
	light.light_energy = 1.2
	light.omni_range = 5.0
	light.position = Vector3(0, 1.75, 0)
	shrine.add_child(light)


## Lumen, the blue spirit butterfly (pose_3 art), flutters around the spawn.
func _build_lumen() -> void:
	_lumen = Node3D.new()
	add_child(_lumen)
	var wing_mat := ToonMaterials.glow(Color(0.45, 0.75, 1.0), 4.0)
	wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		_lumen.add_child(hinge)
		var wing := QuadMesh.new()
		wing.size = Vector2(0.16, 0.12)
		var mi := _mesh(hinge, wing, wing_mat, Vector3(side * 0.08, 0, 0))
		mi.rotation_degrees.x = -90.0
		_lumen_wings.append(hinge)
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.75, 1.0)
	light.light_energy = 0.6
	light.omni_range = 2.0
	_lumen.add_child(light)


func _animate_lumen() -> void:
	var center := SPAWN + Vector3(0.5, 0, -1.0)
	var pos := center + Vector3(sin(_time * 0.7) * 2.2, 1.7 + sin(_time * 1.3) * 0.3, cos(_time * 0.5) * 1.6)
	var ahead := center + Vector3(sin((_time + 0.1) * 0.7) * 2.2, 1.7, cos((_time + 0.1) * 0.5) * 1.6)
	_lumen.position = pos
	if not pos.is_equal_approx(ahead):
		_lumen.look_at(ahead, Vector3.UP)
	var flap := sin(_time * 18.0) * 55.0
	_lumen_wings[0].rotation_degrees.z = flap
	_lumen_wings[1].rotation_degrees.z = -flap


func _build_toast() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -160.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.modulate.a = 0.0
	layer.add_child(_toast)


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
