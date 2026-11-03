class_name LanternBrazier
extends StaticBody3D
## An old lantern brazier of Elderroot (FR-PUZ-01): Light magic (Light Mote, Lantern Glow) sets it burning.
## A part of a Puzzle. Stays lit once lit (remembered through GameState by persist_id).

signal state_changed

const STONE := Color(0.62, 0.6, 0.56)
const FLAME := Color(1.0, 0.78, 0.42)
const COALS := Color(0.22, 0.17, 0.15)
const BOWL_HEIGHT := 1.15

@export var persist_id: StringName
@export var lit_by: Array[Elements.Type] = [Elements.Type.LIGHT]

var is_lit := false
var _flame: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	collision_layer = 1  # world
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.4
	cylinder.height = BOWL_HEIGHT
	shape.shape = cylinder
	shape.position = Vector3(0, BOWL_HEIGHT * 0.5, 0)
	add_child(shape)
	_build_visual()
	var receiver := ElementalReceiver.new()
	receiver.position = Vector3(0, BOWL_HEIGHT, 0)
	receiver.radius = 0.8
	add_child(receiver)
	receiver.element_hit.connect(_on_element_hit)
	if GameState.get_object_state(persist_id).get("lit", false):
		_show_lit(true)


func is_on() -> bool:
	return is_lit


func light_up() -> void:
	if is_lit:
		return
	_show_lit(false)
	GameState.set_object_state(persist_id, {"lit": true})
	state_changed.emit()


func _on_element_hit(element: Elements.Type, _from: Vector3) -> void:
	if element in lit_by:
		light_up()


func _show_lit(instant: bool) -> void:
	is_lit = true
	_flame.visible = true
	_light.visible = true
	if not instant:
		_flame.scale = Vector3.ONE * 0.2
		create_tween().tween_property(_flame, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)


func _process(_delta: float) -> void:
	if is_lit:
		var flicker := 1.0 + sin(Time.get_ticks_msec() * 0.013) * 0.06 + sin(Time.get_ticks_msec() * 0.031) * 0.04
		_flame.scale.y = flicker
		_light.light_energy = 1.6 * flicker


func _build_visual() -> void:
	var stone := ToonMaterials.toon(STONE, 0.2, 0.015)
	var base := CylinderMesh.new()
	base.top_radius = 0.3
	base.bottom_radius = 0.42
	base.height = 0.25
	_add(base, stone, Vector3(0, 0.125, 0))
	var post := CylinderMesh.new()
	post.top_radius = 0.14
	post.bottom_radius = 0.18
	post.height = 0.75
	_add(post, stone, Vector3(0, 0.62, 0))
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.42
	bowl.bottom_radius = 0.2
	bowl.height = 0.2
	_add(bowl, stone, Vector3(0, BOWL_HEIGHT - 0.1, 0))
	var coals := CylinderMesh.new()
	coals.top_radius = 0.34
	coals.bottom_radius = 0.34
	coals.height = 0.04
	_add(coals, ToonMaterials.toon(COALS, 0.1), Vector3(0, BOWL_HEIGHT + 0.01, 0))
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.2
	flame_mesh.height = 0.55
	_flame = _add(flame_mesh, ToonMaterials.glow(FLAME, 4.0), Vector3(0, BOWL_HEIGHT + 0.22, 0))
	_flame.visible = false
	_light = OmniLight3D.new()
	_light.light_color = FLAME
	_light.light_energy = 1.6
	_light.omni_range = 5.0
	_light.position = Vector3(0, BOWL_HEIGHT + 0.4, 0)
	_light.visible = false
	add_child(_light)


func _add(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	add_child(mi)
	return mi
