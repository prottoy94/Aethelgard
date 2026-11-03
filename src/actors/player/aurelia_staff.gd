class_name AureliaStaff
extends Node3D
## Aurelia's gnarled staff with a teal gem and a hanging lantern (Game Images/white_hair_girl_character.jpeg).
## Built from simple shapes; the origin is where her hand grips it (staff runs along +Y).
## Shared by the placeholder model and the animated humanoid model (attached to the RightHand bone).

const WOOD := Color("6b4a2e")
const GEM := Color("4fd6e0")
const FLAME := Color("ffb35a")
const IRON := Color("3a2a20")
const CHAIN := Color("5a3a24")
const OUTLINE := 0.012
## How far the staff reaches below / above the hand (m)
const BELOW_HAND := 0.85
const ABOVE_HAND := 0.75

var _lantern: Node3D
var _time := 0.0
var _swing := 0.0  # 0 = standing still, 1 = moving fast


func _ready() -> void:
	var length := BELOW_HAND + ABOVE_HAND
	_add(_cylinder(0.02, 0.024, length), ToonMaterials.toon(WOOD, 0.3, OUTLINE), Vector3(0, (ABOVE_HAND - BELOW_HAND) / 2.0, 0))
	var crook := TorusMesh.new()
	crook.inner_radius = 0.035
	crook.outer_radius = 0.055
	var crook_node := _add(crook, ToonMaterials.toon(WOOD, 0.3), Vector3(0, ABOVE_HAND + 0.03, -0.03))
	crook_node.rotation_degrees = Vector3(0, 90, 90)
	crook_node.scale = Vector3(1.0, 0.45, 1.0)
	var gem := SphereMesh.new()
	gem.radius = 0.038
	gem.height = 0.076
	_add(gem, ToonMaterials.toon(GEM, 0.0, 0.0, 0.0, GEM, 3.0), Vector3(0, ABOVE_HAND + 0.03, -0.03))
	_lantern = Node3D.new()
	_lantern.position = Vector3(0, ABOVE_HAND - 0.01, -0.1)
	add_child(_lantern)
	_add(_cylinder(0.004, 0.004, 0.08), ToonMaterials.toon(CHAIN, 0.2), Vector3(0, -0.04, 0), _lantern)
	var cage := BoxMesh.new()
	cage.size = Vector3(0.065, 0.1, 0.065)
	_add(cage, ToonMaterials.toon(IRON, 0.2), Vector3(0, -0.13, 0), _lantern)
	var flame := BoxMesh.new()
	flame.size = Vector3(0.05, 0.07, 0.07)
	_add(flame, ToonMaterials.glow(FLAME, 4.0), Vector3(0, -0.13, 0), _lantern)
	var light := OmniLight3D.new()
	light.light_color = FLAME
	light.light_energy = 0.8
	light.omni_range = 3.5
	light.position = Vector3(0, -0.13, 0)
	_lantern.add_child(light)


func _process(delta: float) -> void:
	_time += delta
	_lantern.rotation_degrees.x = sin(_time * 3.0) * (4.0 + 10.0 * _swing)


## 0–1: how much the lantern swings (set from movement speed).
func set_swing(amount: float) -> void:
	_swing = clampf(amount, 0.0, 1.0)


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	return m


func _add(mesh: Mesh, material: Material, pos: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi
