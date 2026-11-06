class_name CapeSway
extends Node3D
## Keeps Aurelia's cape hanging down from her shoulders instead of turning stiffly with her chest, and lets it float back
## behind her as she speeds up (a placeholder for cloth until her VRoid model, which has its own spring bones).
## Sits on a chest bone attachment; follows its position, but takes only the character's facing, plus a swing.

const MAX_SWING_DEG := 55.0   ## when running fast
const FULL_SPEED := 6.0       ## m/s at which it reaches the full swing
const FOLLOW := 6.0           ## how quickly it reacts

var visual: Node3D            ## the character's visual (its yaw is the facing)
var _swing := 0.0
var _last_position := Vector3.ZERO


func _process(delta: float) -> void:
	if visual == null or delta <= 0.0:
		return
	var here := global_position
	var moved := Vector2(here.x - _last_position.x, here.z - _last_position.z).length() / delta
	_last_position = here
	var target := clampf(moved / FULL_SPEED, 0.0, 1.0) * deg_to_rad(MAX_SWING_DEG)
	_swing = lerpf(_swing, target, 1.0 - exp(-FOLLOW * delta))
	var size := get_parent_node_3d().global_basis.get_scale()
	var facing := visual.global_basis.orthonormalized()
	# The cape hangs along -Y behind the back (+Z of the visual, which faces -Z); swinging lifts its hem backwards.
	global_basis = (facing * Basis(Vector3.RIGHT, -_swing)).scaled(size)
