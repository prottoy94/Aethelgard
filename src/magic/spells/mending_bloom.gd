class_name MendingBloomSpell
extends Spell
## Mending Bloom (GAME_DESIGN.md §6.4): a ring of glowing petals that heals Aurelia over a few seconds.
## Heals base_damage × power in total over `duration`.

const COLOR := Color(0.7, 1.0, 0.75)
const PETALS := 6

var _health: HealthComponent
var _time := 0.0
var _petals: Array[Node3D] = []


func _on_cast(_aim: Vector3) -> void:
	_health = caster.get_node_or_null(^"Health") as HealthComponent
	var material := ToonMaterials.glow(COLOR, 2.5)
	for i in PETALS:
		var petal := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.09
		mesh.height = 0.12
		petal.mesh = mesh
		petal.material_override = material
		add_child(petal)
		_petals.append(petal)


func _process(delta: float) -> void:
	if data == null:
		return
	var step := minf(delta, data.duration - _time)
	_time += delta
	if _health and step > 0.0:
		_health.heal(damage() * step / data.duration)
	if is_instance_valid(caster):
		global_position = caster.global_position
	for i in _petals.size():
		var a := TAU * i / PETALS + _time * 2.5
		_petals[i].position = Vector3(cos(a) * 0.7, 0.4 + _time * 0.3, sin(a) * 0.7)
	if _time >= data.duration:
		queue_free()
