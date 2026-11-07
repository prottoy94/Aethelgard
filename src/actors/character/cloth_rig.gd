class_name ClothRig
extends RefCounted
## Gives a character's hair and clothes physics: adds bone chains to the skeleton and simulates them with Godot's
## SpringBoneSimulator3D (the same kind of spring bones a VRoid model brings). Skinned meshes made with
## SkinnedMeshBuilder are then weighted to the chain bones. Positions are in the skeleton's rest space.


## Adds a chain of bones through `points` under `parent` (the last point is the tip). Returns the bone indices.
static func add_chain(skeleton: Skeleton3D, parent: int, prefix: String, points: Array) -> PackedInt32Array:
	var bones := PackedInt32Array()
	var parent_global := skeleton.get_bone_global_rest(parent)
	var last := parent
	for i in points.size():
		var here: Vector3 = points[i]
		var next: Vector3 = points[i + 1] if i + 1 < points.size() else here + (here - (points[i - 1] as Vector3))
		var global := Transform3D(_basis_along(next - here), here)
		var bone := skeleton.add_bone("%s_%d" % [prefix, i])
		skeleton.set_bone_parent(bone, last)
		var local := parent_global.affine_inverse() * global
		skeleton.set_bone_rest(bone, local)
		skeleton.reset_bone_pose(bone)
		bones.append(bone)
		parent_global = global
		last = bone
	return bones


## Adds a simulated chain (root to tip) to `simulator` with the group's settings.
static func simulate(simulator: SpringBoneSimulator3D, skeleton: Skeleton3D, bones: PackedInt32Array,
		settings: ClothChainSettings) -> void:
	var i := simulator.setting_count
	simulator.setting_count = i + 1
	simulator.set_root_bone_name(i, skeleton.get_bone_name(bones[0]))
	simulator.set_end_bone_name(i, skeleton.get_bone_name(bones[bones.size() - 1]))
	simulator.set_stiffness(i, settings.stiffness)
	simulator.set_drag(i, settings.drag)
	simulator.set_gravity(i, settings.gravity)
	simulator.set_radius(i, settings.radius)


## A capsule the chains can't pass through, on a body bone (offset and length along the bone, skeleton units).
static func add_capsule(simulator: SpringBoneSimulator3D, bone_name: StringName, offset: Vector3, radius: float,
		height: float) -> SpringBoneCollisionCapsule3D:
	var capsule := SpringBoneCollisionCapsule3D.new()
	capsule.bone_name = bone_name
	capsule.position_offset = offset
	capsule.radius = radius
	capsule.height = maxf(height, radius * 2.0)
	simulator.add_child(capsule)
	return capsule


## Weights for a point `s` segments down a chain (0 = root joint): owned by its segment's bone, blending into the
## neighbouring bone towards each joint so bends stay smooth. Bone 0's head blends into `parent`.
static func chain_weights(bones: PackedInt32Array, s: float, parent: int, scale := 1.0) -> Dictionary:
	var segments := bones.size() - 1
	var j := clampi(floori(s), 0, segments - 1)
	var f := clampf(s - j, 0.0, 1.0)
	var w := {}
	if f >= 0.5:
		_add(w, bones[j], (1.5 - f) * scale)
		_add(w, bones[mini(j + 1, segments - 1)] if j + 1 < segments else bones[j], (f - 0.5) * scale)
	else:
		_add(w, bones[j], (0.5 + f) * scale)
		_add(w, bones[j - 1] if j > 0 else parent, (0.5 - f) * scale)
	return w


## Mixes weight dictionaries: a * (1 - t) + b * t.
static func mix(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var w := {}
	for bone: int in a:
		_add(w, bone, a[bone] * (1.0 - t))
	for bone: int in b:
		_add(w, bone, b[bone] * t)
	return w


static func _add(w: Dictionary, bone: int, value: float) -> void:
	w[bone] = float(w.get(bone, 0.0)) + value


static func _basis_along(direction: Vector3) -> Basis:
	var y := direction.normalized() if direction.length() > 0.0001 else Vector3.DOWN
	var x := Vector3.FORWARD.cross(y) if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT.cross(y)
	x = x.normalized()
	return Basis(x, y, x.cross(y).normalized())
