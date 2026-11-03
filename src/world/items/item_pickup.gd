class_name ItemPickup
extends Area3D
## An item on the ground: enemy loot, or a placed item such as a quest's lost satchel. Walk over it to collect it
## (FR-ITM-01). If the bag can't take it all, the rest stays. Loot fades away after LIFETIME seconds; a placed item
## (with a persist_id) never does, and GameState remembers that it was taken.

const PLAYER_LAYER := 1 << 1  # layer 2
const RADIUS := 0.9
const LIFETIME := 90.0
const POP_TIME := 0.45
const POP_HEIGHT := 1.2
const HOVER := 0.35
const SPIN_SPEED := 1.5

@export var item: ItemData
@export var amount := 1
@export var persist_id: StringName  ## set for placed items (not loot)

var _visual: MeshInstance3D
var _time := 0.0
var _can_take := true


func _ready() -> void:
	if persist_id != &"" and GameState.get_object_state(persist_id).get("taken", false):
		set_process(false)
		queue_free()
		return
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	shape.position = Vector3(0, HOVER, 0)
	add_child(shape)
	_visual = MeshInstance3D.new()
	var gem := SphereMesh.new()  # 4 segments × 2 rings = a little diamond
	gem.radius = 0.16
	gem.height = 0.4
	gem.radial_segments = 4
	gem.rings = 2
	_visual.mesh = gem
	_visual.material_override = ToonMaterials.glow(item.color, 1.6)
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_visual)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.position.y = HOVER + sin(_time * 3.0) * 0.06
	_visual.rotation.y += SPIN_SPEED * delta
	if _time > LIFETIME and persist_id == &"":
		queue_free()


## Flies in a small arc from `origin` to where it was placed, then can be collected.
func pop_from(origin: Vector3) -> void:
	var rest := global_position
	_can_take = false
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		global_position = origin.lerp(rest, t) + Vector3(0, sin(t * PI) * POP_HEIGHT, 0), 0.0, 1.0, POP_TIME)
	tween.tween_callback(func() -> void:
		_can_take = true
		for body in get_overlapping_bodies():
			_on_body_entered(body))


## Puts as much as fits into the inventory. Returns true when nothing is left on the ground.
func collect() -> bool:
	var added := Inventory.add(item, amount)
	if added > 0:
		EventBus.item_collected.emit(item.id, added)
		amount -= added
	if amount > 0:
		return false
	if persist_id != &"":
		GameState.set_object_state(persist_id, {"taken": true})
	_can_take = false
	set_deferred(&"monitoring", false)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(queue_free)
	return true


func _on_body_entered(body: Node3D) -> void:
	if _can_take and body is Player:
		collect()
