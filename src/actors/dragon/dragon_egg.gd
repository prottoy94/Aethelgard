class_name DragonEgg
extends Node3D
## The dragon egg as a prop (placeholder: a speckled egg about 0.4 m tall with an inner glow). Used by the hatching
## scene: wobble(), crack() and burst() run while the game is paused (conversations).

const SHELL := Color("efe6d2")
const SPECKLE := Color("9a8a6a")
const GLOW := Color("ffd98a")
const HEIGHT := 0.4

var tint := GLOW     ## the glow colour (the chosen element's colour once picked)
var _shell: Node3D
var _light: OmniLight3D
var _shell_meshes: Array[MeshInstance3D] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	_shell = Node3D.new()
	add_child(_shell)
	var egg := SphereMesh.new()
	egg.radius = HEIGHT * 0.38
	egg.height = HEIGHT
	_add_shell(egg, ToonMaterials.toon(SHELL, 0.5, 0.01), Vector3(0, HEIGHT * 0.5, 0))
	for i in 9:
		var dot := SphereMesh.new()
		dot.radius = 0.018
		dot.height = 0.036
		var a := TAU * i / 9.0
		var y := HEIGHT * (0.3 + 0.45 * fmod(i * 0.37, 1.0))
		var r := HEIGHT * 0.36 * sin(PI * y / HEIGHT)
		_add_shell(dot, ToonMaterials.toon(SPECKLE, 0.2), Vector3(cos(a) * r, y, sin(a) * r))
	_light = OmniLight3D.new()
	_light.light_color = tint
	_light.light_energy = 0.6
	_light.omni_range = 2.5
	_light.position = Vector3(0, HEIGHT * 0.5, 0)
	add_child(_light)


func set_tint(color: Color) -> void:
	tint = color
	if _light:
		_light.light_color = color


## Rocks `times` times with a soft pulse of light and sound.
func wobble(times := 3) -> void:
	for i in times:
		AudioManager.play(&"dragon_egg_pulse", global_position)
		var tween := _tween()
		tween.tween_property(_shell, "rotation_degrees:z", 14.0, 0.12)
		tween.parallel().tween_property(_light, "light_energy", 2.2, 0.12)
		tween.tween_property(_shell, "rotation_degrees:z", -12.0, 0.18)
		tween.tween_property(_shell, "rotation_degrees:z", 0.0, 0.12)
		tween.parallel().tween_property(_light, "light_energy", 0.8, 0.3)
		tween.tween_interval(0.25)
		await tween.finished


## Glows brighter as cracks appear (the shell darkens in thin lines; placeholder: a bright flicker).
func crack() -> void:
	AudioManager.play(&"dragon_egg_crack", global_position)
	var tween := _tween()
	tween.tween_property(_light, "light_energy", 4.0, 0.5)
	tween.parallel().tween_property(_shell, "scale", Vector3(1.06, 0.97, 1.06), 0.5)
	tween.tween_property(_shell, "rotation_degrees:z", 6.0, 0.06)
	tween.tween_property(_shell, "rotation_degrees:z", -6.0, 0.08)
	tween.tween_property(_shell, "rotation_degrees:z", 0.0, 0.06)
	await tween.finished


## The shell flies apart in pieces and the egg is removed.
func burst() -> void:
	for mesh in _shell_meshes:
		var piece := mesh
		var away := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.6, 1.4), _rng.randf_range(-1, 1)).normalized()
		var tween := _tween()
		tween.tween_property(piece, "position", piece.position + away * 0.5, 0.45).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(piece, "scale", Vector3.ONE * 0.3, 0.45)
		tween.parallel().tween_property(piece, "transparency", 1.0, 0.45)
	var flash := _tween()
	flash.tween_property(_light, "light_energy", 6.0, 0.08)
	flash.tween_property(_light, "light_energy", 0.0, 0.6)
	flash.tween_callback(queue_free)


func _tween() -> Tween:
	return create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)


func _add_shell(mesh: Mesh, material: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	_shell.add_child(mi)
	_shell_meshes.append(mi)
