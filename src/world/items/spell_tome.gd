class_name SpellTome
extends Node3D
## A spell tome lying in the world (FR-MAG-07). Pick it up (E) to carry it; read it at a Lantern Shrine to learn
## the spell. A hidden tome is invisible until revealed by light (Lantern Glow), apart from a faint shimmer.
## Remembers being taken through GameState (persist_id).

const BOB_HEIGHT := 0.08
const SPIN_SPEED := 0.8
const HOVER := 0.9
const HINT_ALPHA := 0.15

@export var spell: SpellData
@export var persist_id: StringName
@export var hidden := false

var _book: Node3D
var _interactable: InteractableComponent
var _time := 0.0
var _materials: Array[BaseMaterial3D] = []


func _ready() -> void:
	if GameState.get_object_state(persist_id).get("taken", false) or PlayerData.knows(spell.id) or spell.id in PlayerData.tomes:
		queue_free()
		return
	_build_book()
	_interactable = InteractableComponent.new()
	_interactable.prompt_verb = "Take %s tome" % spell.display_name
	_interactable.prompt_height = 1.7
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	shape.shape = sphere
	shape.position = Vector3(0, HOVER, 0)
	_interactable.add_child(shape)
	add_child(_interactable)
	_interactable.interacted.connect(_on_taken)
	if hidden:
		add_to_group(&"revealable")
		_set_alpha(HINT_ALPHA)
		_interactable.set_deferred(&"monitorable", false)


func _process(delta: float) -> void:
	_time += delta
	if _book:
		_book.position.y = HOVER + sin(_time * 2.0) * BOB_HEIGHT
		_book.rotation.y += SPIN_SPEED * delta


## Called by light spells (Lantern Glow).
func reveal() -> void:
	if not hidden:
		return
	hidden = false
	remove_from_group(&"revealable")
	_interactable.monitorable = true
	AudioManager.play(&"puzzle_hidden_reveal", global_position)
	EventBus.secret_found.emit(persist_id)
	create_tween().tween_method(_set_alpha, HINT_ALPHA, 1.0, 0.6)


func _on_taken(_by: Node) -> void:
	PlayerData.add_tome(spell)
	AudioManager.play(&"combat_loot_pickup", global_position)
	GameState.set_object_state(persist_id, {"taken": true})
	var tween := create_tween()
	tween.tween_property(_book, "scale", Vector3.ONE * 1.6, 0.15)
	tween.tween_property(_book, "scale", Vector3.ZERO, 0.2)
	tween.tween_callback(queue_free)


func _build_book() -> void:
	_book = Node3D.new()
	add_child(_book)
	var cover_color := Elements.color(spell.element).darkened(0.35)
	_add_part(Vector3(0.42, 0.08, 0.32), cover_color, 0.0, Vector3.ZERO)
	_add_part(Vector3(0.38, 0.06, 0.29), Color("f1ead2"), 0.0, Vector3(0.02, 0.0, 0.0))  # pages
	_add_part(Vector3(0.1, 0.1, 0.1), Elements.color(spell.element), 3.0, Vector3(0, 0.07, 0))  # glowing rune
	var light := OmniLight3D.new()
	light.light_color = Elements.color(spell.element)
	light.light_energy = 0.8
	light.omni_range = 2.5
	_book.add_child(light)


func _add_part(size: Vector3, color: Color, glow: float, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	mi.material_override = material
	mi.position = pos
	_book.add_child(mi)
	_materials.append(material)


func _set_alpha(alpha: float) -> void:
	for material in _materials:
		material.albedo_color.a = alpha
