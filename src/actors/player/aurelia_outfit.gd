class_name AureliaOutfit
extends RefCounted
## Dresses the animated stand-in mannequin as Aurelia until her VRoid model arrives (Phase 2b): silver hair with a
## long tail down the back, elf ears, a plum hooded capelet and cape, and a cream skirt, in the placeholder's colours.
## Pieces hang on bones (BoneAttachment3D), so they move with the walk, run and cast animations. Placement is given in
## the skeleton's rest space (model units, facing +Z) and converted per bone, so bone axes don't matter.

const HAIR := Color("dcdce6")
const SKIN := Color("f5dccb")
const EYES := Color("8a5a26")
const BLUSH := Color("f2a6a6")
const CAPE := Color("4b2840")
const GOLD := Color("d4a849")
const DRESS := Color("e8e0c8")
const COAT := Color("2f5a3a")    ## the mannequin's own tint: her green coat
const OUTLINE := 0.012


static func dress(visual: HumanoidVisual) -> void:
	var skeleton := visual.skeleton
	if skeleton == null:
		return
	var head := _bone_origin(skeleton, &"Head")
	_piece(skeleton, &"Head", _sphere(0.135), SKIN, head + Vector3(0, 0.1, 0.0), Vector3.ONE)
	_piece(skeleton, &"Head", _sphere(0.1), SKIN, head + Vector3(0, 0.02, 0.02), Vector3(1.0, 1.0, 0.95))  # chin
	_piece(skeleton, &"Head", _cone(0.06, 0.07, 0.14), SKIN, head + Vector3(0, -0.06, 0.0), Vector3.ONE)  # neck
	# Hair over the top and back (the face stays free), bangs, side locks; amber eyes and a little blush.
	_piece(skeleton, &"Head", _sphere(0.145), HAIR, head + Vector3(0, 0.16, -0.045), Vector3(1.06, 0.9, 1.0))
	_piece(skeleton, &"Head", _box(Vector3(0.25, 0.07, 0.07)), HAIR, head + Vector3(0, 0.2, 0.085), Vector3.ONE)
	for side: float in [-1.0, 1.0]:
		_piece(skeleton, &"Head", _box(Vector3(0.05, 0.22, 0.07)), HAIR, head + Vector3(side * 0.12, 0.05, 0.05), Vector3.ONE)
		_piece(skeleton, &"Head", _sphere(0.022), EYES, head + Vector3(side * 0.048, 0.09, 0.128), Vector3(1, 1.3, 0.5))
		_piece(skeleton, &"Head", _sphere(0.018), BLUSH, head + Vector3(side * 0.078, 0.055, 0.118), Vector3(1.3, 0.7, 0.4))
	_piece(skeleton, &"Head", _box(Vector3(0.24, 0.5, 0.06)), HAIR, head + Vector3(0, -0.1, -0.13), Vector3.ONE)
	for side: float in [-1.0, 1.0]:
		var ear := _piece(skeleton, &"Head", _cone(0.0, 0.035, 0.16), SKIN, head + Vector3(side * 0.14, 0.13, 0.0),
				Vector3.ONE)
		ear.rotation_degrees = Vector3(0, 0, -side * 70.0)  # pointing out and a little up
	var chest_bone := &"UpperChest" if skeleton.find_bone(&"UpperChest") >= 0 else &"Chest"
	var chest := _bone_origin(skeleton, chest_bone)
	_piece(skeleton, chest_bone, _cone(0.11, 0.25, 0.18), CAPE, chest + Vector3(0, 0.06, -0.01), Vector3.ONE)  # capelet, below the chin
	_cape(visual, skeleton, chest_bone, chest + Vector3(0, 0.2, -0.17))
	var hips := _bone_origin(skeleton, &"Hips")
	_piece(skeleton, &"Hips", _cone(0.17, 0.32, 0.5), DRESS, hips + Vector3(0, -0.18, 0), Vector3.ONE)


## The cape hangs from the shoulders on a CapeSway (down, floating back as she runs), not rigidly on the chest.
static func _cape(visual: HumanoidVisual, skeleton: Skeleton3D, bone_name: StringName, rest_position: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	if bone < 0:
		return
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	var holder := Node3D.new()
	holder.transform = skeleton.get_bone_global_rest(bone).affine_inverse() * Transform3D(Basis(), rest_position)
	attachment.add_child(holder)
	var sway := CapeSway.new()
	sway.visual = visual
	holder.add_child(sway)
	for part: Array in [[_box(Vector3(0.5, 1.0, 0.035)), CAPE, Vector3(0, -0.5, 0.02)],
			[_box(Vector3(0.51, 0.04, 0.04)), GOLD, Vector3(0, -1.0, 0.02)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = ToonMaterials.toon(part[1], 0.35, OUTLINE)
		mi.position = part[2]
		sway.add_child(mi)


static func _bone_origin(skeleton: Skeleton3D, bone_name: StringName) -> Vector3:
	var bone := skeleton.find_bone(bone_name)
	return skeleton.get_bone_global_rest(bone).origin if bone >= 0 else Vector3.ZERO


## Adds `mesh` on `bone_name`, placed at `rest_position` (skeleton rest space).
static func _piece(skeleton: Skeleton3D, bone_name: StringName, mesh: Mesh, color: Color, rest_position: Vector3,
		piece_scale: Vector3) -> MeshInstance3D:
	var bone := skeleton.find_bone(bone_name)
	if bone < 0:
		return MeshInstance3D.new()
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	var holder := Node3D.new()
	holder.transform = skeleton.get_bone_global_rest(bone).affine_inverse() * Transform3D(Basis(), rest_position)
	attachment.add_child(holder)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = piece_scale
	mi.material_override = ToonMaterials.toon(color, 0.35, OUTLINE)
	holder.add_child(mi)
	return mi


static func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	return m


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _cone(top: float, bottom: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	return m
