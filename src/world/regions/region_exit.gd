class_name RegionExit
extends Area3D
## Walk into it to travel to another region (TECHNICAL_DESIGN.md §4.7). Aurelia keeps her health and stamina.
## Give it a size; it builds its own box shape. Ignores her for a moment after a region loads, so arriving next to
## an exit doesn't bounce her straight back.

const PLAYER_LAYER := 1 << 1
const ARM_DELAY := 1.0  ## s

@export var target_region: StringName
@export var target_spawn: StringName = &"start"
@export var size := Vector3(4, 3, 1.5)

var _armed := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0, size.y * 0.5, 0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(ARM_DELAY).timeout.connect(func() -> void: _armed = true)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or not _armed or player.health.is_dead() or SceneLoader.is_changing:
		return
	var state := SaveManager.capture_player(player)
	state.erase("position")  # she appears at the target spawn instead
	SceneLoader.change_region(target_region, target_spawn, state)
