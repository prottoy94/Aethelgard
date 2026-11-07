class_name SkinnedMeshBuilder
extends RefCounted
## Builds skinned meshes in code (Aurelia's stand-in body and clothes until her VRoid model arrives): tubes along
## limbs and the torso, and cloth sheets over bone chains. Positions are in the skeleton's rest space; each vertex
## carries up to 4 bone weights, given as {bone_index: weight}. Mesh bone indices are skeleton bone indices, so
## make_skin() binds every bone of the skeleton in order.

const RING_SEGMENTS := 12

## When on, the mesh carries vertex colours (sRGB, for the shaders' use_vertex_color): soft painted gradients.
## Vertices added without a colour of their own get `color`.
var vertex_colors := false
var color := Color.WHITE

var _colors := PackedColorArray()
var _verts := PackedVector3Array()
var _normals := PackedVector3Array()
var _bones := PackedInt32Array()
var _weights := PackedFloat32Array()
var _indices := PackedInt32Array()


func is_empty() -> bool:
	return _indices.is_empty()


func add_vertex(position: Vector3, normal: Vector3, weights: Dictionary, vertex_color: Variant = null) -> int:
	_colors.append(vertex_color if vertex_color is Color else color)
	var pairs: Array = []
	for bone: int in weights:
		if weights[bone] > 0.0:
			pairs.append([bone, float(weights[bone])])
	pairs.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	pairs.resize(mini(pairs.size(), 4))
	var total := 0.0
	for pair: Array in pairs:
		total += pair[1]
	for i in 4:
		if i < pairs.size():
			_bones.append(pairs[i][0])
			_weights.append(pairs[i][1] / total)
		else:
			_bones.append(0)
			_weights.append(0.0)
	_verts.append(position)
	_normals.append(normal.normalized())
	return _verts.size() - 1


## A ring of a tube: centre, the direction the tube runs, its radii (x = across `side`, y = across the front
## direction), the front reference direction and the bone weights of the ring: a {bone: weight} Dictionary, or a
## Callable(direction: Vector3) -> Dictionary for weights that change around the ring. Optional: the ring's vertex
## colour (a Color, or a Callable(across: float, out: float) -> Color for patterns round the ring: `across` -1..1
## along the side direction, `out` -1..1 towards the front), and `power` > 2 to flatten the front half of the ring
## (a superellipse; for faces).
static func ring(center: Vector3, axis: Vector3, radius: Vector2, front: Vector3, weights: Variant,
		ring_color: Variant = null, power := 2.0) -> Dictionary:
	return {"center": center, "axis": axis.normalized(), "radius": radius, "front": front, "weights": weights,
			"color": ring_color, "power": power}


## Adds a tube through `rings` (elliptical cross-sections). Caps close the ends (`cap_bulge` 0 = flat).
## `segments` 4 with `angle_offset` PI / 4 makes a box.
func add_tube(rings: Array, cap_start := false, cap_end := false, segments := RING_SEGMENTS, angle_offset := 0.0,
		cap_bulge := 0.6) -> void:
	var first := _verts.size()
	for r: Dictionary in rings:
		var axis: Vector3 = r.axis
		var side: Vector3 = (r.front as Vector3).cross(axis).normalized()
		var front := axis.cross(side).normalized()
		var radius: Vector2 = r.radius
		var power: float = r.get("power", 2.0)
		for k in segments + 1:
			var a := TAU * float(k) / segments + angle_offset
			var ca := cos(a)
			var sa := sin(a)
			if power != 2.0 and sa > 0.0:  # flatter front: |x/rx|^power + |z/rz|^power = 1
				ca = signf(ca) * pow(absf(ca), 2.0 / power)
				sa = pow(sa, 2.0 / power)
			var offset := side * ca * radius.x + front * sa * radius.y
			var normal := side * ca / maxf(radius.x, 0.001) + front * sa / maxf(radius.y, 0.001)
			add_vertex(r.center + offset, normal, _weights_at(r, normal.normalized()), _color_at(r, ca, sa))
	var stride := segments + 1
	for i in rings.size() - 1:
		for k in segments:
			var a := first + i * stride + k
			var b := a + stride
			_quad(a, a + 1, b + 1, b)
	if cap_start:
		var r0: Dictionary = rings[0]
		var depth := minf(r0.radius.x, r0.radius.y) * cap_bulge
		var tip := add_vertex(r0.center - (r0.axis as Vector3) * depth, -r0.axis, _weights_at(r0, -r0.axis), _color_at(r0, 0.0, 1.0))
		for k in segments:
			_indices.append_array([tip, first + k, first + k + 1])
	if cap_end:
		var rn: Dictionary = rings[rings.size() - 1]
		var base := first + (rings.size() - 1) * stride
		var depth := minf(rn.radius.x, rn.radius.y) * cap_bulge
		var tip := add_vertex(rn.center + (rn.axis as Vector3) * depth, rn.axis, _weights_at(rn, rn.axis), _color_at(rn, 0.0, 1.0))
		for k in segments:
			_indices.append_array([tip, base + k + 1, base + k])


## An ellipsoid with radii along the basis axes (basis.y is its long axis). `color` (optional): a Color, or a
## Callable(t: float, across: float, out: float) -> Color, t going 0..1 along the long axis.
func add_ellipsoid(center: Vector3, radii: Vector3, weights: Variant, basis := Basis(), rings := 8,
		color: Variant = null) -> void:
	var list := []
	for i in rings + 1:
		var a := PI * float(i) / rings
		var r := maxf(sin(a), 0.02)
		var t := float(i) / rings
		var c: Variant = color
		if color is Callable:
			c = func(across: float, out: float) -> Color: return (color as Callable).call(t, across, out)
		list.append(ring(center - basis.y * cos(a) * radii.y, basis.y, Vector2(r * radii.x, r * radii.z), basis.z, weights,
				c))
	add_tube(list, true, true, RING_SEGMENTS, 0.0, 0.0)


## A box (slightly soft-shaded) with its size along the basis axes.
func add_box(center: Vector3, size: Vector3, weights: Variant, basis := Basis()) -> void:
	var r := Vector2(size.x, size.z) * 0.5 * sqrt(2.0)
	add_tube([ring(center - basis.y * size.y * 0.5, basis.y, r, basis.z, weights),
			ring(center + basis.y * size.y * 0.5, basis.y, r, basis.z, weights)], true, true, 4, PI / 4.0, 0.0)


static func _color_at(r: Dictionary, across: float, out: float) -> Variant:
	var c: Variant = r.get("color")
	return (c as Callable).call(across, out) if c is Callable else c


static func _weights_at(r: Dictionary, direction: Vector3) -> Dictionary:
	var w: Variant = r.weights
	return (w as Callable).call(direction) if w is Callable else w


## Adds a sheet from a grid of points (rows of equal length) with matching weights. Normals face `outward`
## (a point the sheet curves away from, e.g. the body's centre). Two-sided: the back is a mirrored copy.
## `colors` (optional): a grid of vertex colours matching `points`.
func add_sheet(points: Array, weights: Array, outward_from: Vector3, two_sided := true, colors: Array = []) -> void:
	var rows := points.size()
	var cols: int = (points[0] as Array).size()
	for side_sign: float in ([1.0, -1.0] if two_sided else [1.0]):
		var first := _verts.size()
		for r in rows:
			for c in cols:
				var p: Vector3 = points[r][c]
				var along_u: Vector3 = points[r][mini(c + 1, cols - 1)] - points[r][maxi(c - 1, 0)]
				var along_v: Vector3 = points[mini(r + 1, rows - 1)][c] - points[maxi(r - 1, 0)][c]
				var n := along_u.cross(along_v).normalized()
				if n.dot(p - outward_from) < 0.0:
					n = -n
				add_vertex(p, n * side_sign, weights[r][c], colors[r][c] if not colors.is_empty() else null)
		for r in rows - 1:
			for c in cols - 1:
				var a := first + r * cols + c
				var b := a + cols
				var outward_ok := _normals[a].dot(((points[r][c + 1] as Vector3) - points[r][c]).cross(
						(points[r + 1][c] as Vector3) - points[r][c])) > 0.0
				if outward_ok:  # the stored normal already faces this side
					_quad(a, a + 1, b + 1, b)
				else:
					_quad(a, b, b + 1, a + 1)


## (vertex count, index count): pass to smooth_normals() to smooth what is added after this point.
func mark() -> Vector2i:
	return Vector2i(_verts.size(), _indices.size())


## Recomputes normals from the faces added since `from` (a mark()), welding vertices at the same position, so
## tapered shapes (a chin, the crown) shade correctly.
func smooth_normals(from: Vector2i) -> void:
	var sums := {}
	for i in range(from.y, _indices.size(), 3):
		var a := _verts[_indices[i]]
		var b := _verts[_indices[i + 1]]
		var c := _verts[_indices[i + 2]]
		var n := (c - a).cross(b - a)  # front faces wind clockwise: this points outwards
		for v in [_indices[i], _indices[i + 1], _indices[i + 2]]:
			var key := Vector3i((_verts[v] * 20000.0).round())
			sums[key] = (sums.get(key, Vector3.ZERO) as Vector3) + n
	for v in range(from.x, _verts.size()):
		var key := Vector3i((_verts[v] * 20000.0).round())
		if sums.has(key) and (sums[key] as Vector3).length() > 0.0:
			_normals[v] = (sums[key] as Vector3).normalized()


func commit() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _normals
	if vertex_colors:
		arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_BONES] = _bones
	arrays[Mesh.ARRAY_WEIGHTS] = _weights
	arrays[Mesh.ARRAY_INDEX] = _indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## A Skin that binds every skeleton bone in order (bind i = bone i), at its current rest pose.
static func make_skin(skeleton: Skeleton3D) -> Skin:
	var skin := Skin.new()
	for bone in skeleton.get_bone_count():
		skin.add_bind(bone, skeleton.get_bone_global_rest(bone).affine_inverse())
	return skin


## Front faces wind clockwise in Godot.
func _quad(a: int, b: int, c: int, d: int) -> void:
	_indices.append_array([a, c, b, a, d, c])
