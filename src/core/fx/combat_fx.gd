class_name CombatFx
extends RefCounted
## Small combat feedback helpers (GAME_DESIGN.md §7 "feel"): hit flash, hit-stop and floating damage numbers.

const FLASH_TIME := 0.12
const HIT_STOP_SCALE := 0.05
const NUMBER_RISE := 0.9      ## m
const NUMBER_TIME := 0.7      ## s

## Turn off in tests so frozen time doesn't slow them down.
static var hit_stop_enabled := true
static var _hit_stop_active := false


## Flashes every toon mesh under `root` white for a moment.
static func flash(root: Node3D) -> void:
	var meshes := _geometry_under(root)
	if meshes.is_empty() or not root.is_inside_tree():
		return
	var tween := root.create_tween()
	tween.tween_method(func(v: float) -> void:
		for mesh in meshes:
			if is_instance_valid(mesh):
				mesh.set_instance_shader_parameter(&"hit_flash", v), 1.0, 0.0, FLASH_TIME)


## Freezes the game for a few hundredths of a second so hits feel solid.
static func hit_stop(tree: SceneTree, seconds: float) -> void:
	if not hit_stop_enabled or _hit_stop_active or seconds <= 0.0:
		return
	_hit_stop_active = true
	Engine.time_scale = HIT_STOP_SCALE
	await tree.create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


## Spawns a floating number above `position`. Colour shows effectiveness (strong = gold, resisted = grey).
static func damage_number(parent: Node, position: Vector3, amount: float, multiplier: float) -> void:
	floating_text(parent, position, str(roundi(amount)),
			Color("ffd34d") if multiplier > 1.0 else (Color("b0b0b0") if multiplier < 1.0 else Color.WHITE),
			56 if multiplier > 1.0 else 44)


## Floating text above `position` that rises and fades (damage numbers, "Immune").
static func floating_text(parent: Node, position: Vector3, text: String, color: Color, size := 44) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = size
	label.outline_size = 14
	label.pixel_size = 0.005
	label.modulate = color
	parent.add_child(label)
	label.global_position = position
	var tween := label.create_tween()
	tween.tween_property(label, "global_position", position + Vector3(0, NUMBER_RISE, 0), NUMBER_TIME).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, NUMBER_TIME).set_delay(NUMBER_TIME * 0.4)
	tween.tween_callback(label.queue_free)


static func _geometry_under(node: Node) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	if node is GeometryInstance3D and not node is Label3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_geometry_under(child))
	return result
