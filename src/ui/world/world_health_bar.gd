class_name WorldHealthBar
extends Node3D
## A small health bar floating above an enemy. Appears when it's hurt and hides again after a while.

const WIDTH := 0.9
const HEIGHT := 0.09
const SHOW_TIME := 4.0

var _fill: MeshInstance3D
var _back: MeshInstance3D
var _hide_timer := 0.0


func _ready() -> void:
	_back = _quad(Color(0.08, 0.06, 0.1, 0.85), Vector2(WIDTH + 0.04, HEIGHT + 0.04), 0)
	_fill = _quad(Color("e04848"), Vector2(WIDTH, HEIGHT), 1)
	visible = false


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera and visible:
		global_basis = camera.global_basis  # face the camera as one piece
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			visible = false


func set_ratio(ratio: float) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	_fill.scale.x = maxf(r, 0.001)
	_fill.position.x = -WIDTH * (1.0 - r) / 2.0
	visible = r > 0.0
	_hide_timer = SHOW_TIME


func _quad(color: Color, size: Vector2, priority: int) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = priority
	material.albedo_color = color
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
