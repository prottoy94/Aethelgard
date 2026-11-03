extends Node3D
## Elderroot Village (region "elderroot_village", Phase 6b): a small graybox village south of the meadow, built from
## simple shapes. Cottages around a well, a Lantern Shrine with its crafting kit, Maren's herb garden, the Elder by
## his house; the north road leads back to the meadow. RegionRuntime adds Aurelia, the interface and day/night.
## Start it directly with `-- --region=elderroot_village`.

const GROUND := preload("res://assets/shaders/ground.gdshader")
const GRASS := preload("res://assets/shaders/grass.gdshader")
const VILLAGERS_DIALOGUE := preload("res://dialogue/npcs/elderroot_villagers.dialogue")
const SUNPETAL_PATCH := preload("res://data/items/gather/sunpetal_patch.tres")
const MOONBLOOM_PATCH := preload("res://data/items/gather/moonbloom_patch.tres")
const REGION_ID: StringName = &"elderroot_village"
const WORLD_LAYER := 1
const OCCLUDER_LAYER := 1 << 10
const GRASS_BLADES := 16000
const PATH_HALF_WIDTH := 1.6
const NORTH_ROAD_Z := -21.0
const PLAZA_RADIUS := 6.5
const SHRINE_POSITION := Vector3(4.5, 0, -4.0)
const GARDEN_MIN := Vector3(3.5, 0, 3.0)
const GARDEN_MAX := Vector3(9.5, 0, 7.5)
## [position, size, yaw] of each cottage; the door faces the plaza.
const COTTAGES: Array[Array] = [
	[Vector3(-10, 0, -7), Vector3(5.0, 3.0, 4.2), 0.9],
	[Vector3(11, 0, -9), Vector3(4.6, 2.8, 4.0), -0.8],
	[Vector3(-11, 0, 8), Vector3(5.4, 3.2, 4.4), 2.3],
	[Vector3(13, 0, 11), Vector3(4.4, 2.8, 3.8), -2.4],
]
const WALL := Color(0.92, 0.86, 0.74)
const TIMBER := Color(0.42, 0.29, 0.19)
const ROOF := Color(0.55, 0.32, 0.3)
const WINDOW := Color(1.0, 0.8, 0.45)

var runtime: RegionRuntime
var _rng := RandomNumberGenerator.new()
var _noise: NoiseTexture2D
var _grass: MultiMesh


func _ready() -> void:
	_rng.seed = 7
	_noise = NoiseTexture2D.new()
	_noise.seamless = true
	_noise.noise = FastNoiseLite.new()
	_noise.noise.frequency = 0.02
	runtime = RegionRuntime.new()
	runtime.region_id = REGION_ID
	add_child(runtime)
	runtime.build_sky(self)
	_build_ground()
	_build_cottages()
	_build_well()
	_build_garden()
	_build_trees()
	var shrine := RestPoint.new()
	shrine.position = SHRINE_POSITION
	shrine.rotation.y = -0.6
	add_child(shrine)
	_build_villagers()
	_build_road_to_meadow()
	runtime.start()
	Settings.graphics_changed.connect(_apply_graphics)
	_apply_graphics(Settings.graphics)


func _apply_graphics(preset: GraphicsPreset) -> void:
	_grass.visible_instance_count = preset.visible_grass(_grass.instance_count)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	_mesh(self, plane, ToonMaterials.shader_material(GROUND, {"noise_tex": _noise, "paths": false}), Vector3.ZERO)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = WORLD_LAYER
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(shape)
	add_child(floor_body)
	# Packed-earth plaza and the road north
	var dirt := ToonMaterials.toon(Color(0.72, 0.6, 0.42), 0.1)
	var plaza := CylinderMesh.new()
	plaza.top_radius = PLAZA_RADIUS
	plaza.bottom_radius = PLAZA_RADIUS
	plaza.height = 0.02
	_mesh(self, plaza, dirt, Vector3(0, 0.01, 0))
	var road := BoxMesh.new()
	road.size = Vector3(PATH_HALF_WIDTH * 2.0, 0.02, absf(NORTH_ROAD_Z) + 6.0)
	_mesh(self, road, dirt, Vector3(0, 0.01, (NORTH_ROAD_Z - 6.0) * 0.5 + 3.0))
	# Grass blades away from the plaza, road, cottages and garden
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
		var p := Vector3(_rng.randf_range(-35, 35), 0, _rng.randf_range(-30, 30))
		if _is_built(p, 1.0):
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.3))
		transforms.append(Transform3D(basis, p))
	_grass.instance_count = transforms.size()
	for i in transforms.size():
		_grass.set_instance_transform(i, transforms[i])
	var grass_node := MultiMeshInstance3D.new()
	grass_node.multimesh = _grass
	grass_node.material_override = ToonMaterials.shader_material(GRASS)
	grass_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass_node)


## Timber-framed cottages: plaster walls, a pitched roof, a door and warm windows.
func _build_cottages() -> void:
	var wall := ToonMaterials.toon(WALL, 0.25, 0.015)
	var timber := ToonMaterials.toon(TIMBER, 0.2, 0.012)
	var roof := ToonMaterials.toon(ROOF, 0.25, 0.015)
	var window := ToonMaterials.glow(WINDOW, 1.4)
	for cottage: Array in COTTAGES:
		var size: Vector3 = cottage[1]
		var body := StaticBody3D.new()
		body.collision_layer = WORLD_LAYER
		body.position = cottage[0]
		body.rotation.y = cottage[2]
		add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(size.x, size.y + 1.6, size.z)
		shape.shape = box
		shape.position = Vector3(0, (size.y + 1.6) * 0.5, 0)
		body.add_child(shape)
		_box(body, size, wall, Vector3(0, size.y * 0.5, 0))
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_box(body, Vector3(0.2, size.y, 0.2), timber, Vector3(corner.x * size.x * 0.5, size.y * 0.5, corner.y * size.z * 0.5))
		_box(body, Vector3(size.x + 0.1, 0.2, size.z + 0.1), timber, Vector3(0, size.y, 0))
		var gable := CylinderMesh.new()  # a 3-sided prism lying along x
		gable.radial_segments = 3
		gable.top_radius = size.z * 0.62
		gable.bottom_radius = size.z * 0.62
		gable.height = size.x + 0.6
		var roof_mi := _mesh(body, gable, roof, Vector3(0, size.y + size.z * 0.3, 0))
		roof_mi.rotation = Vector3(PI * 0.5, 0, PI * 0.5)
		_box(body, Vector3(0.9, 1.7, 0.08), timber, Vector3(0, 0.85, -size.z * 0.5 - 0.04))  # door
		for side: float in [-1.0, 1.0]:
			_box(body, Vector3(0.6, 0.55, 0.06), window, Vector3(side * size.x * 0.3, size.y * 0.6, -size.z * 0.5 - 0.04))
		var canopy := Area3D.new()  # the roof hides Aurelia from the camera: let it fade
		canopy.collision_layer = OCCLUDER_LAYER
		canopy.collision_mask = 0
		canopy.monitoring = false
		var roof_shape := CollisionShape3D.new()
		var roof_box := BoxShape3D.new()
		roof_box.size = Vector3(size.x + 0.6, size.z * 0.7, size.z * 1.1)
		roof_shape.shape = roof_box
		roof_shape.position = Vector3(0, size.y + size.z * 0.3, 0)
		canopy.add_child(roof_shape)
		body.add_child(canopy)


func _build_well() -> void:
	var stone := ToonMaterials.toon(Color(0.62, 0.6, 0.56), 0.2, 0.015)
	var wood := ToonMaterials.toon(TIMBER, 0.2, 0.012)
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	add_child(body)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.0
	cylinder.height = 0.9
	shape.shape = cylinder
	shape.position = Vector3(0, 0.45, 0)
	body.add_child(shape)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.95
	ring.bottom_radius = 1.0
	ring.height = 0.8
	_mesh(body, ring, stone, Vector3(0, 0.4, 0))
	var water := CylinderMesh.new()
	water.top_radius = 0.75
	water.bottom_radius = 0.75
	water.height = 0.02
	_mesh(body, water, ToonMaterials.toon(Color(0.3, 0.55, 0.75), 0.6), Vector3(0, 0.7, 0))
	for side: float in [-0.85, 0.85]:
		_box(body, Vector3(0.12, 1.6, 0.12), wood, Vector3(side, 1.5, 0))
	var roof := CylinderMesh.new()
	roof.radial_segments = 3
	roof.top_radius = 0.9
	roof.bottom_radius = 0.9
	roof.height = 2.1
	var roof_mi := _mesh(body, roof, ToonMaterials.toon(ROOF, 0.25, 0.015), Vector3(0, 2.55, 0))
	roof_mi.rotation = Vector3(PI * 0.5, 0, PI * 0.5)


## Maren's herb garden: a low fence (open on the west) with Sunpetal and Moonbloom to gather.
func _build_garden() -> void:
	var wood := ToonMaterials.toon(TIMBER.lightened(0.15), 0.2, 0.012)
	var soil := BoxMesh.new()
	soil.size = Vector3(GARDEN_MAX.x - GARDEN_MIN.x, 0.04, GARDEN_MAX.z - GARDEN_MIN.z)
	_mesh(self, soil, ToonMaterials.toon(Color(0.42, 0.3, 0.2), 0.1), (GARDEN_MIN + GARDEN_MAX) * 0.5 + Vector3(0, 0.02, 0))
	var size := GARDEN_MAX - GARDEN_MIN
	var center := (GARDEN_MIN + GARDEN_MAX) * 0.5
	_fence(Vector3(center.x, 0, GARDEN_MIN.z), Vector3(size.x, 0.6, 0.08), wood)
	_fence(Vector3(center.x, 0, GARDEN_MAX.z), Vector3(size.x, 0.6, 0.08), wood)
	_fence(Vector3(GARDEN_MAX.x, 0, center.z), Vector3(0.08, 0.6, size.z), wood)
	var plants: Array[Array] = [[SUNPETAL_PATCH, Vector3(5.2, 0, 4.6)], [SUNPETAL_PATCH, Vector3(8.0, 0, 6.2)],
			[MOONBLOOM_PATCH, Vector3(8.0, 0, 4.2)]]
	for i in plants.size():
		var node := GatherNode.new()
		node.data = plants[i][0]
		node.persist_id = StringName("village_garden_%d" % i)
		node.position = plants[i][1]
		add_child(node)


func _fence(pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.position = pos
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.2), 0.9, maxf(size.z, 0.2))
	shape.shape = box
	shape.position = Vector3(0, 0.45, 0)
	body.add_child(shape)
	_box(body, Vector3(size.x, 0.08, size.z), material, Vector3(0, 0.55, 0))
	_box(body, Vector3(size.x, 0.08, size.z), material, Vector3(0, 0.3, 0))
	var posts := maxi(roundi(maxf(size.x, size.z) / 1.2), 1)
	for i in posts + 1:
		var t := float(i) / posts - 0.5
		_box(body, Vector3(0.1, 0.75, 0.1), material, Vector3(t * size.x, 0.37, t * size.z))


func _build_trees() -> void:
	var trunk_mat := ToonMaterials.toon(Color(0.42, 0.29, 0.19), 0.2, 0.02)
	var leaf_mat := ToonMaterials.toon(Color(0.34, 0.54, 0.24), 0.3, 0.0, 0.05)
	var placed := 0
	while placed < 26:
		var p := Vector3(_rng.randf_range(-34, 34), 0, _rng.randf_range(-30, 30))
		if p.length() < 17.0 or _is_built(p, 4.0):
			continue
		var tree := StaticBody3D.new()
		tree.collision_layer = WORLD_LAYER
		tree.position = p
		add_child(tree)
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.35
		cylinder.height = 3.0
		shape.shape = cylinder
		shape.position = Vector3(0, 1.5, 0)
		tree.add_child(shape)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.22
		trunk.bottom_radius = 0.38
		trunk.height = 3.0
		_mesh(tree, trunk, trunk_mat, Vector3(0, 1.5, 0))
		for k in 2:
			var leaves := SphereMesh.new()
			leaves.radius = _rng.randf_range(1.5, 2.1)
			leaves.height = leaves.radius * 2.0
			_mesh(tree, leaves, leaf_mat, Vector3(_rng.randf_range(-0.6, 0.6), 3.6 + k * 0.8, _rng.randf_range(-0.6, 0.6)))
		var canopy := Area3D.new()
		canopy.collision_layer = OCCLUDER_LAYER
		canopy.collision_mask = 0
		canopy.monitoring = false
		var canopy_shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 2.3
		canopy_shape.shape = sphere
		canopy_shape.position = Vector3(0, 4.1, 0)
		canopy.add_child(canopy_shape)
		tree.add_child(canopy)
		placed += 1


func _build_villagers() -> void:
	var elder := Npc.villager(&"elder", "Elder", load("res://data/npcs/elder.tres"), VILLAGERS_DIALOGUE)
	elder.position = Vector3(-6.8, 0, -4.2)
	add_child(elder)
	elder.face_point(Vector3.ZERO)
	var maren := Npc.villager(&"maren", "Maren", load("res://data/npcs/maren.tres"), VILLAGERS_DIALOGUE)
	maren.position = Vector3(3.0, 0, 5.0)
	add_child(maren)
	maren.face_point(Vector3.ZERO)


## The road north to the meadow: a signpost, the exit, and where Aurelia arrives from the meadow.
func _build_road_to_meadow() -> void:
	var wood := ToonMaterials.toon(TIMBER.lightened(0.1), 0.25, 0.015)
	for side: float in [-1.0, 1.0]:
		_fence(Vector3(side * (PATH_HALF_WIDTH + 0.6), 0, NORTH_ROAD_Z + 3.0), Vector3(0.08, 0.6, 6.0), wood)
	var exit := RegionExit.new()
	exit.target_region = &"elderroot_meadow"
	exit.target_spawn = &"from_village"
	exit.size = Vector3(PATH_HALF_WIDTH * 2.0 + 1.0, 3.0, 1.2)
	exit.position = Vector3(0, 0, NORTH_ROAD_Z)
	add_child(exit)
	for id: StringName in [&"start", &"from_meadow"]:
		var spawn := RegionSpawn.new()
		spawn.spawn_id = id
		spawn.position = Vector3(0, 0, NORTH_ROAD_Z + 5.0)
		spawn.rotation.y = PI  # facing south, into the village
		add_child(spawn)


## True where something is built (plaza, road, cottages, garden, shrine), with `margin` metres around it.
func _is_built(p: Vector3, margin: float) -> bool:
	if Vector2(p.x, p.z).length() < PLAZA_RADIUS + margin:
		return true
	if absf(p.x) < PATH_HALF_WIDTH + margin and p.z < 0.0 and p.z > NORTH_ROAD_Z - 6.0:
		return true
	if p.x > GARDEN_MIN.x - margin and p.x < GARDEN_MAX.x + margin and p.z > GARDEN_MIN.z - margin and p.z < GARDEN_MAX.z + margin:
		return true
	if p.distance_to(SHRINE_POSITION) < 2.5 + margin:
		return true
	for cottage: Array in COTTAGES:
		if p.distance_to(cottage[0]) < 4.0 + margin:
			return true
	return false


func _box(parent: Node, size: Vector3, material: Material, pos: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, material, pos)


func _mesh(parent: Node, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi
