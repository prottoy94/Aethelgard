class_name TrialRune
extends StaticBody3D
## A rune stone of a Trial (Gust Trial runes): hidden in the mist as a faint shimmer until light magic (Lantern Glow)
## reveals it, then lit by Light (Light Mote, Lantern Glow). Its face shows `order` wind marks (one, two or three
## curls), the order the shrine asks for; shapes, not colours, so it reads in greyscale (NFR-ACC-02). RuneSequence
## checks the order and puts runes out again after a wrong one. Remembers being revealed (GameState).

signal lit_up(rune: TrialRune)
signal state_changed

const STONE := Color(0.6, 0.62, 0.6)
const MARK_DARK := Color(0.36, 0.42, 0.4)
const WIND := Color(0.72, 1.0, 0.86)
const HINT_ALPHA := 0.12
const REVEAL_GRACE := 0.4  ## s after being revealed when light doesn't count yet (Lantern Glow reveals and lights at once)
const HEIGHT := 1.0

@export var persist_id: StringName
@export var order := 1

var hidden := true
var is_lit := false
var _grace := 0.0
var _materials: Array[StandardMaterial3D] = []
var _marks: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _shape: CollisionShape3D


func _ready() -> void:
	collision_layer = 1  # world
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, HEIGHT, 0.4)
	_shape.shape = box
	_shape.position = Vector3(0, HEIGHT * 0.5, 0)
	_shape.disabled = true
	add_child(_shape)
	_build()
	var receiver := ElementalReceiver.new()
	receiver.position = Vector3(0, HEIGHT * 0.6, 0)
	receiver.radius = 0.8
	add_child(receiver)
	receiver.element_hit.connect(_on_element_hit)
	if GameState.get_object_state(persist_id).get("revealed", false):
		hidden = false
		_show(1.0)
		_shape.disabled = false
	else:
		add_to_group(&"revealable")
		_show(0.0)


func _process(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)


func is_on() -> bool:
	return is_lit


## Called by light spells (Lantern Glow).
func reveal() -> void:
	if not hidden:
		return
	hidden = false
	_grace = REVEAL_GRACE
	remove_from_group(&"revealable")
	_shape.set_deferred(&"disabled", false)
	GameState.set_object_state(persist_id, {"revealed": true})
	AudioManager.play(&"puzzle_hidden_reveal", global_position)
	create_tween().tween_method(_show, 0.0, 1.0, 0.8)
	state_changed.emit()


func light_up() -> void:
	if is_lit or hidden:
		return
	set_lit(true)
	AudioManager.play(&"puzzle_rune_light", global_position)
	lit_up.emit(self)


## Lights or puts out its marks without a sound (RuneSequence after a wrong order; a solved Trial on load).
func set_lit(on: bool) -> void:
	is_lit = on
	for mark in _marks:
		var material := mark.material_override as StandardMaterial3D
		material.albedo_color = WIND if on else MARK_DARK
		material.emission_enabled = on
		material.emission = WIND
		material.emission_energy_multiplier = 2.5
	_light.light_energy = 1.2 if on else 0.0
	state_changed.emit()


## Shown when the order was wrong: a dull flash before going dark.
func fizzle() -> void:
	set_lit(false)
	var tween := create_tween()
	tween.tween_property(_light, "light_energy", 0.8, 0.05)
	tween.tween_property(_light, "light_energy", 0.0, 0.4)


func _on_element_hit(element: Elements.Type, _from: Vector3) -> void:
	if element == Elements.Type.LIGHT and _grace <= 0.0:
		light_up()


## 0 = a faint shimmer in the mist, 1 = solid stone.
func _show(amount: float) -> void:
	for material in _materials:
		material.albedo_color.a = lerpf(HINT_ALPHA, 1.0, amount)
		material.emission_energy_multiplier = lerpf(1.2, 0.0, amount)
	for mark in _marks:
		mark.visible = amount > 0.5


func _build() -> void:
	var slab_material := StandardMaterial3D.new()
	slab_material.albedo_color = STONE
	slab_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slab_material.emission_enabled = true
	slab_material.emission = WIND
	_materials.append(slab_material)
	var slab := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, HEIGHT, 0.35)
	slab.mesh = mesh
	slab.material_override = slab_material
	slab.position = Vector3(0, HEIGHT * 0.5, 0)
	add_child(slab)
	var top := MeshInstance3D.new()
	var top_mesh := PrismMesh.new()
	top_mesh.size = Vector3(0.8, 0.3, 0.35)
	top.mesh = top_mesh
	top.material_override = slab_material
	top.position = Vector3(0, HEIGHT + 0.15, 0)
	add_child(top)
	for i in order:  # one curl per breath, stacked up its face (-Z side)
		var mark := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.07
		torus.outer_radius = 0.11
		mark.mesh = torus
		var material := StandardMaterial3D.new()
		material.albedo_color = MARK_DARK
		mark.material_override = material
		mark.rotation_degrees.x = 90.0
		var spacing := 0.26
		mark.position = Vector3(0, HEIGHT * 0.5 + (i - (order - 1) * 0.5) * spacing, -0.19)
		add_child(mark)
		_marks.append(mark)
	_light = OmniLight3D.new()
	_light.light_color = WIND
	_light.light_energy = 0.0
	_light.omni_range = 3.0
	_light.position = Vector3(0, HEIGHT * 0.6, -0.6)
	add_child(_light)
