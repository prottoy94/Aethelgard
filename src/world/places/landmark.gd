class_name Landmark
extends Area3D
## A named place worth finding (owner request 2026-11-05: more to explore). The first time Aurelia walks in, it is
## discovered: a GameState flag remembers it, EventBus.place_reached fires (quests, the dragon egg's warmth) and the
## region shows "Discovered: <name>". The map (MapMenu) shows discovered places by name.

signal discovered(landmark: Landmark)

const PLAYER_LAYER := 1 << 1

@export var place_id: StringName
@export var display_name := ""
@export var radius := 8.0


func _ready() -> void:
	add_to_group(&"landmark")
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 6.0
	shape.shape = cylinder
	shape.position = Vector3(0, 3.0, 0)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func flag() -> StringName:
	return StringName("found_%s" % place_id)


func is_discovered() -> bool:
	return GameState.has_flag(flag())


func discover() -> bool:
	if is_discovered():
		return false
	GameState.set_flag(flag())
	EventBus.place_reached.emit(place_id)
	AudioManager.play(&"ui_quest_update")
	discovered.emit(self)
	return true


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		discover()
