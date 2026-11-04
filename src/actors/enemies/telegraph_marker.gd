class_name TelegraphMarker
extends Node3D
## The warning on the ground for an EnemyMoveData (FR-CMB-05): a filling ring (MELEE all around, RING), a sector
## (MELEE with an arc), a lane (CHARGE) or a fan of lines (VOLLEY). Red, brightening as the hit comes. Stays flat on the
## ground and follows the enemy's facing while it winds up.

const COLOR := Color(1.0, 0.28, 0.18)
const HEIGHT := 0.05
const SEGMENTS := 40

var _mesh: MeshInstance3D
var _fill: MeshInstance3D
var _material: StandardMaterial3D
var _fill_material: StandardMaterial3D


func _ready() -> void:
	top_level = true
	_material = _make_material(0.35)
	_fill_material = _make_material(0.5)
	_mesh = MeshInstance3D.new()
	_mesh.material_override = _material
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_fill = MeshInstance3D.new()
	_fill.material_override = _fill_material
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fill)
	visible = false


## Shows the warning for `move` at `origin`, pointing along `forward`, `progress` 0–1 of the wind-up.
func show_move(move: EnemyMoveData, origin: Vector3, forward: Vector3, progress: float) -> void:
	if move == null or move.kind == EnemyMoveData.Kind.SUMMON:
		visible = false
		return
	if not visible:
		_mesh.mesh = _shape(move, 1.0)
	visible = true
	global_position = Vector3(origin.x, origin.y + HEIGHT, origin.z)
	if Vector2(forward.x, forward.z).length_squared() > 0.0001:
		rotation = Vector3(0, Player.yaw_of(forward), 0)
	var p := clampf(progress, 0.0, 1.0)
	_fill.mesh = _shape(move, maxf(p, 0.02))
	_material.albedo_color.a = 0.25 + 0.3 * p
	_fill_material.albedo_color.a = 0.35 + 0.35 * p


func hide_marker() -> void:
	visible = false


## A flat mesh for the move, `scale_amount` of its full size (the filling part grows to 1).
static func _shape(move: EnemyMoveData, scale_amount: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	match move.kind:
		EnemyMoveData.Kind.CHARGE:
			var half := move.width * 0.5
			var far := -move.length * scale_amount
			_quad(tool, Vector3(-half, 0, 0), Vector3(half, 0, 0), Vector3(half, 0, far), Vector3(-half, 0, far))
		EnemyMoveData.Kind.VOLLEY:
			var reach := move.projectile_range * scale_amount
			for i in move.count:
				var t := 0.5 if move.count == 1 else float(i) / (move.count - 1)
				var angle := deg_to_rad(lerpf(-move.spread_deg * 0.5, move.spread_deg * 0.5, t))
				var dir := Vector3(-sin(angle), 0, -cos(angle))
				var side := Vector3(dir.z, 0, -dir.x) * move.projectile_radius
				_quad(tool, -side, side, side + dir * reach, -side + dir * reach)
		_:
			var arc := deg_to_rad(clampf(move.arc_deg, 1.0, 360.0))
			var radius := move.radius * scale_amount
			var steps := maxi(int(SEGMENTS * arc / TAU), 4)
			for i in steps:
				var a0 := -arc * 0.5 + arc * i / steps
				var a1 := -arc * 0.5 + arc * (i + 1) / steps
				tool.add_vertex(Vector3.ZERO)
				tool.add_vertex(Vector3(-sin(a1), 0, -cos(a1)) * radius)
				tool.add_vertex(Vector3(-sin(a0), 0, -cos(a0)) * radius)
	return tool.commit()


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v: Vector3 in [a, c, b, a, d, c]:
		tool.add_vertex(v)


static func _make_material(alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(COLOR, alpha)
	material.no_depth_test = false
	return material
