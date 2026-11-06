class_name PropKit
extends RefCounted
## Placeholder props of simple shapes at real size (NFR-ART-01), shared by the region builders: trees, rocks, fences,
## tents, campfires, crates, barrels, lamp posts, cottages, market stalls, a windmill, a bridge, water strips and an
## invisible edge. Solid props are a StaticBody3D root with meshes as children (needed for the camera's occlusion fade);
## tree canopies get a camera_occluder area. All use the shared shaders through ToonMaterials.

const WORLD_LAYER := 1 << 0
const OCCLUDER_LAYER := 1 << 10
const WATER := preload("res://assets/shaders/water.gdshader")
const BARK := Color(0.42, 0.29, 0.19)
const LEAVES: Array[Color] = [Color(0.3, 0.5, 0.22), Color(0.38, 0.56, 0.24), Color(0.27, 0.45, 0.2)]
const STONE := Color(0.6, 0.58, 0.55)
const WOOD := Color(0.5, 0.35, 0.22)
const CANVAS := Color(0.86, 0.8, 0.66)
const FIRE := Color(1.0, 0.55, 0.18)
const ROOF := Color(0.55, 0.27, 0.2)
const WALL := Color(0.93, 0.88, 0.76)


static func solid(parent: Node, pos: Vector3, surface := "stone") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.set_meta(&"surface", surface)
	body.position = pos
	parent.add_child(body)
	return body


static func mesh(parent: Node, m: Mesh, color: Color, pos: Vector3, outline := 0.015, rim := 0.3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = ToonMaterials.toon(color, rim, outline)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func cylinder_mesh(top: float, bottom: float, height: float, sides := 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = sides
	return m


static func sphere_mesh(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m


static func add_box_shape(body: Node, size: Vector3, pos: Vector3, rot_y := 0.0) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	shape.rotation.y = rot_y
	body.add_child(shape)


static func add_cylinder_shape(body: Node, radius: float, height: float, pos: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	shape.position = pos
	body.add_child(shape)


## A solid box with a mesh (walls, crates, plinths).
static func block(parent: Node, size: Vector3, color: Color, pos: Vector3, rot_y := 0.0, surface := "stone") -> StaticBody3D:
	var body := solid(parent, pos, surface)
	body.rotation.y = rot_y
	add_box_shape(body, size, Vector3(0, size.y * 0.5, 0))
	mesh(body, box_mesh(size), color, Vector3(0, size.y * 0.5, 0))
	return body


static func tree(parent: Node, pos: Vector3, rng: RandomNumberGenerator, size := 1.0, leaf := -1) -> StaticBody3D:
	var body := solid(parent, pos, "grass")
	var trunk_height := 3.2 * size
	add_cylinder_shape(body, 0.35 * size, trunk_height, Vector3(0, trunk_height * 0.5, 0))
	mesh(body, cylinder_mesh(0.22 * size, 0.4 * size, trunk_height, 8), BARK, Vector3(0, trunk_height * 0.5, 0), 0.02, 0.2)
	var color := LEAVES[leaf if leaf >= 0 else rng.randi() % LEAVES.size()]
	for k in 3:
		var r := rng.randf_range(1.3, 2.0) * size
		var canopy_mesh := mesh(body, sphere_mesh(r), color.lightened(0.05 * k),
				Vector3(rng.randf_range(-0.9, 0.9) * size, (3.5 + k * 0.7) * size, rng.randf_range(-0.9, 0.9) * size), 0.0)
		canopy_mesh.material_override = ToonMaterials.toon(color.lightened(0.05 * k), 0.3, 0.0, 0.05)
	var canopy := Area3D.new()
	canopy.collision_layer = OCCLUDER_LAYER
	canopy.collision_mask = 0
	canopy.monitoring = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.4 * size
	shape.shape = sphere
	shape.position = Vector3(0, 4.3 * size, 0)
	canopy.add_child(shape)
	body.add_child(canopy)
	return body


## A pine (darker, taller, cones of leaves): for the meadow's edges.
static func pine(parent: Node, pos: Vector3, rng: RandomNumberGenerator, size := 1.0) -> StaticBody3D:
	var body := solid(parent, pos, "grass")
	add_cylinder_shape(body, 0.3 * size, 3.0 * size, Vector3(0, 1.5 * size, 0))
	mesh(body, cylinder_mesh(0.16 * size, 0.3 * size, 2.0 * size, 8), BARK, Vector3(0, 1.0 * size, 0), 0.0, 0.2)
	var green := Color(0.18, 0.36, 0.22).lightened(rng.randf_range(0.0, 0.12))
	for k in 3:
		var cone := mesh(body, cylinder_mesh(0.0, (1.9 - k * 0.45) * size, 2.4 * size, 10), green,
				Vector3(0, (2.3 + k * 1.3) * size, 0), 0.0)
		cone.material_override = ToonMaterials.toon(green, 0.3, 0.0, 0.04)
	_add_occluder(body, 2.0 * size, Vector3(0, 3.6 * size, 0))
	return body


## Lets the camera notice this prop blocking the view and fade it (camera_occluder layer).
static func _add_occluder(body: Node3D, radius: float, pos: Vector3) -> void:
	var area := Area3D.new()
	area.collision_layer = OCCLUDER_LAYER
	area.collision_mask = 0
	area.monitoring = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	shape.position = pos
	area.add_child(shape)
	body.add_child(area)


static func rock(parent: Node, pos: Vector3, rng: RandomNumberGenerator, size := 1.0) -> StaticBody3D:
	var body := solid(parent, pos)
	var r := rng.randf_range(0.5, 0.9) * size
	add_cylinder_shape(body, r * 0.9, r * 1.2, Vector3(0, r * 0.5, 0))
	var mi := mesh(body, sphere_mesh(r), STONE.darkened(rng.randf_range(0.0, 0.2)), Vector3(0, r * 0.45, 0), 0.015, 0.2)
	mi.scale = Vector3(rng.randf_range(1.0, 1.5), rng.randf_range(0.6, 0.9), rng.randf_range(0.9, 1.3))
	mi.rotation.y = rng.randf() * TAU
	return body


## Posts with two rails from `a` to `b` (solid).
static func fence(parent: Node, a: Vector3, b: Vector3, color := WOOD) -> void:
	var length := a.distance_to(b)
	var mid := (a + b) * 0.5
	var yaw := atan2(b.x - a.x, b.z - a.z)
	var body := solid(parent, mid, "wood")
	body.rotation.y = yaw
	add_box_shape(body, Vector3(0.15, 1.0, length), Vector3(0, 0.5, 0))
	for y: float in [0.45, 0.8]:
		mesh(body, box_mesh(Vector3(0.06, 0.09, length)), color, Vector3(0, y, 0), 0.0)
	var posts := maxi(int(length / 2.0), 1)
	for i in posts + 1:
		mesh(body, box_mesh(Vector3(0.12, 1.05, 0.12)), color.darkened(0.1),
				Vector3(0, 0.52, -length * 0.5 + length * i / posts), 0.01)


static func tent(parent: Node, pos: Vector3, rot_y: float, color := CANVAS) -> StaticBody3D:
	var body := solid(parent, pos, "wood")
	body.rotation.y = rot_y
	add_box_shape(body, Vector3(2.4, 1.8, 2.6), Vector3(0, 0.9, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(2.6, 1.9, 2.8)
	mesh(body, roof, color, Vector3(0, 0.95, 0))
	mesh(body, box_mesh(Vector3(0.6, 1.2, 0.02)), color.darkened(0.45), Vector3(0, 0.6, 1.41), 0.0)  # opening
	return body


## Stones in a ring, logs and a flickering fire with light. Returns the light (for flicker).
static func campfire(parent: Node, pos: Vector3, rng: RandomNumberGenerator) -> OmniLight3D:
	var root := solid(parent, pos)
	add_cylinder_shape(root, 0.6, 0.4, Vector3(0, 0.2, 0))
	for i in 8:
		var a := TAU * i / 8.0
		mesh(root, sphere_mesh(0.14), STONE.darkened(0.3), Vector3(cos(a) * 0.55, 0.08, sin(a) * 0.55), 0.0)
	for i in 3:
		var log_mi := mesh(root, cylinder_mesh(0.07, 0.07, 0.8, 6), BARK.darkened(0.2), Vector3(0, 0.12, 0), 0.0)
		log_mi.rotation = Vector3(PI * 0.5, TAU * i / 3.0, 0)
	var flame := MeshInstance3D.new()
	flame.mesh = cylinder_mesh(0.0, 0.3, 0.7, 8)
	flame.material_override = ToonMaterials.glow(FIRE, 3.0)
	flame.position = Vector3(0, 0.45, 0)
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = FIRE
	light.light_energy = 1.6
	light.omni_range = 6.0
	light.position = Vector3(0, 0.9, 0)
	root.add_child(light)
	return light


static func crate(parent: Node, pos: Vector3, rng: RandomNumberGenerator, size := 0.7) -> StaticBody3D:
	var body := block(parent, Vector3.ONE * size, WOOD.lightened(0.1), pos, rng.randf() * 0.6, "wood")
	mesh(body, box_mesh(Vector3(size * 1.02, size * 0.12, size * 1.02)), WOOD.darkened(0.25), Vector3(0, size * 0.5, 0), 0.0)
	return body


static func barrel(parent: Node, pos: Vector3) -> StaticBody3D:
	var body := solid(parent, pos, "wood")
	add_cylinder_shape(body, 0.35, 0.9, Vector3(0, 0.45, 0))
	mesh(body, cylinder_mesh(0.32, 0.32, 0.9), WOOD, Vector3(0, 0.45, 0))
	for y: float in [0.2, 0.7]:
		mesh(body, cylinder_mesh(0.335, 0.335, 0.06), Color(0.3, 0.3, 0.32), Vector3(0, y, 0), 0.0)
	return body


## A post with a lantern that glows (brighter at night through the light's energy only).
static func lamp_post(parent: Node, pos: Vector3) -> void:
	var body := solid(parent, pos, "wood")
	add_cylinder_shape(body, 0.12, 2.6, Vector3(0, 1.3, 0))
	mesh(body, box_mesh(Vector3(0.12, 2.6, 0.12)), WOOD.darkened(0.2), Vector3(0, 1.3, 0), 0.01)
	mesh(body, box_mesh(Vector3(0.5, 0.06, 0.06)), WOOD.darkened(0.2), Vector3(0.2, 2.5, 0), 0.0)
	var lantern := MeshInstance3D.new()
	lantern.mesh = box_mesh(Vector3(0.2, 0.26, 0.2))
	lantern.material_override = ToonMaterials.glow(Color(1.0, 0.8, 0.45), 2.5)
	lantern.position = Vector3(0.4, 2.3, 0)
	body.add_child(lantern)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.45)
	light.light_energy = 0.9
	light.omni_range = 5.0
	light.position = Vector3(0.4, 2.2, 0)
	body.add_child(light)


## A cottage: walls, a gabled roof, a door facing +Z and two windows. Size = footprint (x, wall height, z).
static func cottage(parent: Node, pos: Vector3, size: Vector3, rot_y: float, roof_color := ROOF) -> StaticBody3D:
	var body := solid(parent, pos, "wood")
	body.rotation.y = rot_y
	add_box_shape(body, Vector3(size.x, size.y + 1.6, size.z), Vector3(0, (size.y + 1.6) * 0.5, 0))
	mesh(body, box_mesh(size), WALL, Vector3(0, size.y * 0.5, 0))
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		mesh(body, box_mesh(Vector3(0.2, size.y, 0.2)), WOOD.darkened(0.2),
				Vector3(corner.x * size.x * 0.5, size.y * 0.5, corner.y * size.z * 0.5), 0.0)
	var roof := PrismMesh.new()  # triangle across the depth (Z), ridge along the width (X)
	roof.size = Vector3(size.z + 0.6, size.z * 0.7, size.x + 0.6)
	var roof_mi := mesh(body, roof, roof_color, Vector3(0, size.y + size.z * 0.35, 0))
	roof_mi.rotation.y = PI * 0.5
	mesh(body, box_mesh(Vector3(0.9, 1.7, 0.08)), WOOD.darkened(0.3), Vector3(0, 0.85, size.z * 0.5 + 0.04), 0.0)
	for side: float in [-1.0, 1.0]:
		var window := MeshInstance3D.new()
		window.mesh = box_mesh(Vector3(0.6, 0.55, 0.06))
		window.material_override = ToonMaterials.glow(Color(1.0, 0.85, 0.55), 0.8)
		window.position = Vector3(side * size.x * 0.3, size.y * 0.6, size.z * 0.5 + 0.04)
		body.add_child(window)
	return body


## A market stall: a counter, four posts and a striped cloth roof.
static func stall(parent: Node, pos: Vector3, rot_y: float, cloth: Color) -> StaticBody3D:
	var body := solid(parent, pos, "wood")
	body.rotation.y = rot_y
	add_box_shape(body, Vector3(2.4, 1.0, 1.0), Vector3(0, 0.5, 0))
	mesh(body, box_mesh(Vector3(2.4, 0.95, 0.9)), WOOD, Vector3(0, 0.48, 0))
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		mesh(body, box_mesh(Vector3(0.1, 2.3, 0.1)), WOOD.darkened(0.2), Vector3(corner.x * 1.15, 1.15, corner.y * 0.55), 0.0)
	for i in 4:
		var stripe := mesh(body, box_mesh(Vector3(0.62, 0.05, 1.5)), cloth if i % 2 == 0 else CANVAS,
				Vector3(-0.93 + i * 0.62, 2.35, 0.1), 0.0)
		stripe.rotation.x = -0.18
	return body


## A windmill: stone tower, cap and four sails on a hub. Returns the hub (rotate it on Z).
static func windmill(parent: Node, pos: Vector3, rot_y: float) -> Node3D:
	var body := solid(parent, pos)
	body.rotation.y = rot_y
	add_cylinder_shape(body, 2.0, 7.0, Vector3(0, 3.5, 0))
	mesh(body, cylinder_mesh(1.5, 2.1, 7.0, 10), WALL.darkened(0.05), Vector3(0, 3.5, 0))
	mesh(body, cylinder_mesh(0.0, 1.9, 2.0, 10), ROOF, Vector3(0, 8.0, 0))
	mesh(body, box_mesh(Vector3(0.9, 1.8, 0.1)), WOOD.darkened(0.3), Vector3(0, 0.9, 2.02), 0.0)
	var hub := Node3D.new()
	hub.position = Vector3(0, 6.2, 2.0)
	body.add_child(hub)
	mesh(hub, cylinder_mesh(0.25, 0.25, 0.5, 8), WOOD.darkened(0.3), Vector3.ZERO, 0.0).rotation.x = PI * 0.5
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.z = TAU * i / 4.0
		hub.add_child(arm)
		mesh(arm, box_mesh(Vector3(0.12, 4.6, 0.08)), WOOD, Vector3(0, 2.4, 0.15), 0.0)
		mesh(arm, box_mesh(Vector3(0.9, 3.4, 0.03)), CANVAS, Vector3(0.5, 2.8, 0.18), 0.0)
	return hub


## A wooden footbridge `length` long along +Z, walkable (a flat deck collider).
static func bridge(parent: Node, pos: Vector3, rot_y: float, length: float, width := 2.6) -> void:
	var body := solid(parent, pos, "wood")
	body.rotation.y = rot_y
	add_box_shape(body, Vector3(width, 0.3, length), Vector3(0, 0.15, 0))
	var planks := int(length / 0.45)
	for i in planks:
		mesh(body, box_mesh(Vector3(width, 0.08, 0.4)), WOOD.lightened(0.05 * (i % 2)),
				Vector3(0, 0.3, -length * 0.5 + 0.225 + i * 0.45), 0.0)
	for side: float in [-1.0, 1.0]:
		mesh(body, box_mesh(Vector3(0.1, 0.1, length)), WOOD.darkened(0.2), Vector3(side * width * 0.5, 0.95, 0), 0.0)
		for i in 4:
			mesh(body, box_mesh(Vector3(0.1, 0.7, 0.1)), WOOD.darkened(0.2),
					Vector3(side * width * 0.5, 0.6, -length * 0.5 + length * i / 3.0), 0.0)


## A strip of shallow water along `points` (walkable: no collider), `width` metres wide.
static func stream(parent: Node, points: PackedVector3Array, width: float, noise: Texture2D) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var side := (b - a).cross(Vector3.UP).normalized() * width * 0.5
		var y := Vector3(0, 0.03, 0)
		for v: Vector3 in [a - side + y, b - side + y, b + side + y, a - side + y, b + side + y, a + side + y]:
			tool.set_uv(Vector2(v.x, v.z) * 0.1)
			tool.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = tool.commit()
	mi.material_override = ToonMaterials.shader_material(WATER, {"noise_tex": noise})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Invisible walls around a rectangle (the area's edge), from (min_x, min_z) to (max_x, max_z).
static func edge(parent: Node, min_corner: Vector2, max_corner: Vector2) -> void:
	var body := solid(parent, Vector3.ZERO)
	var size := max_corner - min_corner
	var center := (min_corner + max_corner) * 0.5
	for wall: Array in [[Vector3(size.x + 2, 6, 1), Vector3(center.x, 3, min_corner.y)],
			[Vector3(size.x + 2, 6, 1), Vector3(center.x, 3, max_corner.y)],
			[Vector3(1, 6, size.y + 2), Vector3(min_corner.x, 3, center.y)],
			[Vector3(1, 6, size.y + 2), Vector3(max_corner.x, 3, center.y)]]:
		add_box_shape(body, wall[0], wall[1])
