class_name NpcPlaceholder
extends Node3D
## A villager built from simple shapes (NpcLook), with a gentle idle sway. The NPC's "Visual" child, so a real
## model can replace it without code changes.

const WOOD := Color(0.48, 0.34, 0.22)

var look: NpcLook
var _body: Node3D
var _time := 0.0


func _ready() -> void:
	_time = randf() * TAU
	_body = Node3D.new()
	add_child(_body)
	var h := look.height
	var robe := _cone(h * 0.17, h * 0.11, h * 0.58)
	_add(robe, ToonMaterials.toon(look.robe, 0.3, 0.015), Vector3(0, h * 0.29, 0))
	var chest := CapsuleMesh.new()
	chest.radius = h * 0.1
	chest.height = h * 0.34
	_add(chest, ToonMaterials.toon(look.robe.darkened(0.08), 0.3, 0.015), Vector3(0, h * 0.64, 0))
	var sash := BoxMesh.new()
	sash.size = Vector3(h * 0.21, h * 0.05, h * 0.2)
	_add(sash, ToonMaterials.toon(look.accent, 0.3), Vector3(0, h * 0.55, 0))
	var head := SphereMesh.new()
	head.radius = h * 0.085
	head.height = h * 0.17
	var head_y := h * 0.88
	_add(head, ToonMaterials.toon(look.skin, 0.4, 0.012), Vector3(0, head_y, 0))
	_build_hair(h, head_y)
	_build_prop(h)


func _process(delta: float) -> void:
	_time += delta
	_body.rotation.z = sin(_time * 1.3) * 0.02
	_body.position.y = sin(_time * 2.6) * 0.008


func _build_hair(h: float, head_y: float) -> void:
	var material := ToonMaterials.toon(look.hair_color, 0.35, 0.012)
	var cap := SphereMesh.new()
	cap.radius = h * 0.09
	cap.height = h * 0.12
	match look.hair:
		NpcLook.Hair.BALD_BEARD:
			var beard := _cone(h * 0.06, h * 0.01, h * 0.16)
			var beard_mi := _add(beard, material, Vector3(0, head_y - h * 0.1, -h * 0.05))
			beard_mi.rotation.x = PI
			for side: float in [-1.0, 1.0]:
				var tuft := SphereMesh.new()
				tuft.radius = h * 0.035
				tuft.height = h * 0.07
				_add(tuft, material, Vector3(side * h * 0.075, head_y, 0.0))
		NpcLook.Hair.LONG:
			_add(cap, material, Vector3(0, head_y + h * 0.03, 0.01))
			var back := BoxMesh.new()
			back.size = Vector3(h * 0.16, h * 0.22, h * 0.05)
			_add(back, material, Vector3(0, head_y - h * 0.08, h * 0.06))
		NpcLook.Hair.PIGTAILS:
			_add(cap, material, Vector3(0, head_y + h * 0.03, 0.01))
			for side: float in [-1.0, 1.0]:
				var tail := SphereMesh.new()
				tail.radius = h * 0.045
				tail.height = h * 0.11
				_add(tail, material, Vector3(side * h * 0.11, head_y - h * 0.02, h * 0.02))
		_:
			_add(cap, material, Vector3(0, head_y + h * 0.03, 0.01))


func _build_prop(h: float) -> void:
	match look.prop:
		NpcLook.Prop.STAFF:
			var staff := CylinderMesh.new()
			staff.top_radius = 0.025
			staff.bottom_radius = 0.03
			staff.height = h * 1.05
			_add(staff, ToonMaterials.toon(WOOD, 0.2, 0.01), Vector3(h * 0.17, h * 0.5, -h * 0.05))
		NpcLook.Prop.BASKET:
			var basket := CylinderMesh.new()
			basket.top_radius = h * 0.09
			basket.bottom_radius = h * 0.07
			basket.height = h * 0.08
			_add(basket, ToonMaterials.toon(Color(0.7, 0.55, 0.32), 0.3, 0.01), Vector3(h * 0.16, h * 0.45, -h * 0.06))
			var flowers := SphereMesh.new()
			flowers.radius = h * 0.06
			flowers.height = h * 0.06
			_add(flowers, ToonMaterials.toon(Color("f2c94c"), 0.5), Vector3(h * 0.16, h * 0.5, -h * 0.06))


static func _cone(bottom: float, top: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	return mesh


func _add(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	_body.add_child(mi)
	return mi
