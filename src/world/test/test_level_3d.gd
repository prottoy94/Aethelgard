extends Node3D
## Phase 1b graybox test level: a golden-hour corner of Elderroot built from simple shapes with the
## project's shaders, collisions on solid objects, a preview camera and the performance overlay.
## Phase 2 adds the player and the real camera rig here. Q/R rotate, mouse wheel zooms, Esc quits.

const TOON := preload("res://assets/shaders/toon.gdshader")
const OUTLINE := preload("res://assets/shaders/toon_outline.gdshader")
const GROUND := preload("res://assets/shaders/ground.gdshader")
const GRASS := preload("res://assets/shaders/grass.gdshader")
const STONE := preload("res://assets/shaders/stone_moss.gdshader")
const WATER := preload("res://assets/shaders/water.gdshader")

const GRASS_BLADES := 50000
const POND_CENTER := Vector3(7, 0, 2)
const WORLD_LAYER := 1

## Preview camera (temporary until the Phase 2 camera rig)
const CAMERA_PITCH_DEG := -42.0
const CAMERA_DISTANCE := 13.5
const CAMERA_ZOOM_RANGE := Vector2(7.0, 22.0)
const CAMERA_ROTATE_SPEED := 1.6
const CAMERA_FOCUS := Vector3(0, 0.9, -2)

var _rng := RandomNumberGenerator.new()
var _noise: NoiseTexture2D
var _environment: Environment
var _sun: DirectionalLight3D
var _grass: MultiMesh
var _camera_pivot: Node3D
var _camera: Camera3D
var _distance := CAMERA_DISTANCE


func _ready() -> void:
	_rng.seed = 42
	_noise = NoiseTexture2D.new()
	_noise.seamless = true
	_noise.noise = FastNoiseLite.new()
	_noise.noise.frequency = 0.02
	_build_environment()
	_build_ground_and_grass()
	_build_trees()
	_build_world_tree()
	_build_ruins()
	_build_pond()
	_build_distant()
	_build_marker()
	_build_camera()
	add_child(PerfOverlay.new())
	Settings.graphics_changed.connect(_apply_graphics)
	_apply_graphics(Settings.graphics)


func _process(delta: float) -> void:
	var turn := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	_camera_pivot.rotate_y(-turn * CAMERA_ROTATE_SPEED * delta)
	_camera.position = Vector3(0, 0, _distance)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		_distance = clampf(_distance - 1.0, CAMERA_ZOOM_RANGE.x, CAMERA_ZOOM_RANGE.y)
	elif event.is_action_pressed("camera_zoom_out"):
		_distance = clampf(_distance + 1.0, CAMERA_ZOOM_RANGE.x, CAMERA_ZOOM_RANGE.y)
	elif event.is_action_pressed("camera_reset"):
		_camera_pivot.rotation.y = 0.0
		_distance = CAMERA_DISTANCE
	elif event.is_action_pressed("pause"):
		get_tree().quit()


func _apply_graphics(preset: GraphicsPreset) -> void:
	preset.apply_to_environment(_environment)
	preset.apply_to_sun(_sun)
	_grass.visible_instance_count = preset.visible_grass(_grass.instance_count)


# --- Building ------------------------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(1.0, 0.78, 0.6)
	sky_mat.ground_horizon_color = Color(1.0, 0.78, 0.6)
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
	_environment.fog_light_color = Color(1.0, 0.84, 0.68)
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
	_sun.light_color = Color(1.0, 0.86, 0.68)
	_sun.light_energy = 1.6
	add_child(_sun)


func _build_ground_and_grass() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(260, 260)
	_mesh(plane, _material(GROUND, {"noise_tex": _noise}), Vector3.ZERO)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = WORLD_LAYER
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v: Array in [[Vector3(-0.05, 0, 0), Vector2(0, 0)], [Vector3(0.05, 0, 0), Vector2(1, 0)], [Vector3(0, 0.5, 0), Vector2(0.5, 1)]]:
		st.set_normal(Vector3.BACK)
		st.set_uv(v[1])
		st.add_vertex(v[0])
	_grass = MultiMesh.new()
	_grass.transform_format = MultiMesh.TRANSFORM_3D
	_grass.mesh = st.commit()
	var transforms: Array[Transform3D] = []
	while transforms.size() < GRASS_BLADES:
		var p := Vector3(_rng.randf_range(-35, 35), 0, _rng.randf_range(-45, 25))
		if _on_path(p, 2.0) or p.distance_to(POND_CENTER) < 4.6:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.4))
		transforms.append(Transform3D(basis, p))
	transforms.shuffle()  # so lower presets thin the grass evenly
	_grass.instance_count = transforms.size()
	for i in transforms.size():
		_grass.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _grass
	mmi.material_override = _material(GRASS, {})
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _build_trees() -> void:
	var trunk_mat := _toon(Color(0.42, 0.29, 0.19), 0.2, 0.0, 0.02)
	var leaf_mat := _toon(Color(0.3, 0.5, 0.22), 0.3, 0.05)
	var placed := 0
	while placed < 80:
		var p := Vector3(_rng.randf_range(-55, 55), 0, _rng.randf_range(-60, 30))
		if p.length() < 7.0 or _on_path(p, 3.5) or p.distance_to(POND_CENTER) < 6.5:
			continue
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.22
		trunk.bottom_radius = 0.4
		trunk.height = 3.2
		_mesh(trunk, trunk_mat, p + Vector3(0, 1.6, 0))
		_solid_cylinder(0.35, 3.2, p + Vector3(0, 1.6, 0))
		for k in 3:
			var leaves := SphereMesh.new()
			leaves.radius = _rng.randf_range(1.4, 2.1)
			leaves.height = leaves.radius * 2.0
			_mesh(leaves, leaf_mat, p + Vector3(_rng.randf_range(-0.9, 0.9), 3.6 + k * 0.7, _rng.randf_range(-0.9, 0.9)))
		placed += 1


func _build_world_tree() -> void:
	var base := Vector3(-6, 0, -75)
	var bark := _toon(Color(0.4, 0.3, 0.22), 0.25)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 3.5
	trunk.bottom_radius = 7.0
	trunk.height = 34.0
	_mesh(trunk, bark, base + Vector3(0, 17, 0))
	_solid_cylinder(6.0, 34.0, base + Vector3(0, 17, 0))
	var canopy := _toon(Color(0.33, 0.47, 0.23), 0.4, 0.15)
	for i in 14:
		var s := SphereMesh.new()
		s.radius = _rng.randf_range(9.0, 14.0)
		s.height = s.radius * 2.0
		_mesh(s, canopy, base + Vector3(_rng.randf_range(-18, 18), _rng.randf_range(32, 42), _rng.randf_range(-12, 12)))


func _build_ruins() -> void:
	var stone := _material(STONE, {"noise_tex": _noise})
	for x: float in [-6.8, -3.4]:
		_solid_box(Vector3(0.9, 4.0, 0.9), stone, Vector3(x, 2.0, -5.0))
	_solid_box(Vector3(4.3, 0.9, 1.0), stone, Vector3(-5.1, 4.4, -5.0))
	_solid_box(Vector3(0.9, 2.6, 0.9), stone, Vector3(4.5, 1.3, -12.0))
	_solid_box(Vector3(0.9, 4.0, 0.9), stone, Vector3(8.0, 2.0, -12.0))
	# Raised platform with four steps up to it (for testing stairs in Phase 2)
	_solid_box(Vector3(6, 1.2, 6), stone, Vector3(-11, 0.6, -13))
	for i in 4:
		var h := 0.3 * (i + 1)
		_solid_box(Vector3(2.2, h, 0.6), stone, Vector3(-11, h / 2.0, -8.5 - i * 0.6))
	for i in 10:
		var height := _rng.randf_range(0.8, 3.8)
		var p := Vector3(_rng.randf_range(-14, 14), height / 2.0, _rng.randf_range(-22, -3))
		if _on_path(p, 2.5):
			p.x += 5.0
		var c := CylinderMesh.new()
		c.top_radius = 0.45
		c.bottom_radius = 0.5
		c.height = height
		_mesh(c, stone, p)
		_solid_cylinder(0.5, height, p)


func _build_pond() -> void:
	var water := CylinderMesh.new()
	water.top_radius = 4.5
	water.bottom_radius = 4.5
	water.height = 0.04
	water.radial_segments = 48
	_mesh(water, _material(WATER, {}), POND_CENTER + Vector3(0, 0.05, 0))
	var rock := _toon(Color(0.55, 0.54, 0.52), 0.25, 0.0, 0.02)
	for i in 14:
		var a := TAU * i / 14.0
		var s := SphereMesh.new()
		s.radius = 0.6
		s.height = 1.2
		var mi := _mesh(s, rock, POND_CENTER + Vector3(cos(a) * 4.8, 0.1, sin(a) * 4.8))
		mi.scale = Vector3(_rng.randf_range(0.6, 1.4), _rng.randf_range(0.4, 0.8), _rng.randf_range(0.6, 1.4))


func _build_distant() -> void:
	var mountain := _toon(Color(0.52, 0.55, 0.62), 0.1)
	for d: Array in [[Vector3(-120, 0, -150), 70.0], [Vector3(60, 0, -170), 90.0], [Vector3(150, 0, -120), 60.0], [Vector3(-170, 0, -60), 55.0]]:
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = d[1] * 0.8
		c.height = d[1]
		_mesh(c, mountain, d[0] + Vector3(0, d[1] / 2.0, 0))


## Stand-in for Aurelia until Phase 2: a 1.6 m capsule in her cloak colour.
func _build_marker() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32
	capsule.height = 1.6
	_mesh(capsule, _toon(Color(0.36, 0.17, 0.31), 0.35, 0.0, 0.02), Vector3(0, 0.8, 0))
	var head := SphereMesh.new()
	head.radius = 0.2
	head.height = 0.4
	_mesh(head, _toon(Color(0.86, 0.86, 0.92), 0.5, 0.0, 0.015), Vector3(0, 1.45, 0))


func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.position = CAMERA_FOCUS
	add_child(_camera_pivot)
	var tilt := Node3D.new()
	tilt.rotation_degrees.x = CAMERA_PITCH_DEG
	_camera_pivot.add_child(tilt)
	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.position = Vector3(0, 0, _distance)
	tilt.add_child(_camera)
	_camera.make_current()


# --- Helpers -------------------------------------------------------------------------------

func _on_path(p: Vector3, half_width: float) -> bool:
	return absf(p.x - sin(p.z * 0.08) * 5.0) < half_width


func _material(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	for key: String in params:
		m.set_shader_parameter(key, params[key])
	return m


func _toon(color: Color, rim := 0.35, wind := 0.0, outline := 0.0) -> ShaderMaterial:
	var m := _material(TOON, {"albedo": color, "rim_strength": rim, "wind": wind})
	if outline > 0.0:
		m.next_pass = _material(OUTLINE, {"thickness": outline})
	return m


func _mesh(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	add_child(mi)
	return mi


func _solid_box(size: Vector3, material: Material, pos: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	_mesh(box, material, pos)
	var shape := BoxShape3D.new()
	shape.size = size
	_static_body(shape, pos)


func _solid_cylinder(radius: float, height: float, pos: Vector3) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_static_body(shape, pos)


func _static_body(shape: Shape3D, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.position = pos
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
