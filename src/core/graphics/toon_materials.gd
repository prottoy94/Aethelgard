class_name ToonMaterials
extends RefCounted
## Builds materials from the project's shared shaders (assets/shaders/), so every object uses one style.

const TOON := preload("res://assets/shaders/toon.gdshader")
const OUTLINE := preload("res://assets/shaders/toon_outline.gdshader")


static func shader_material(shader: Shader, params: Dictionary = {}) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key: String in params:
		material.set_shader_parameter(key, params[key])
	return material


## Toon material. `outline` is the outline thickness in metres (0 = none).
static func toon(color: Color, rim := 0.35, outline := 0.0, wind := 0.0,
		emission := Color.BLACK, emission_energy := 0.0) -> ShaderMaterial:
	var material := shader_material(TOON, {"albedo": color, "rim_strength": rim, "wind": wind,
			"emission": emission, "emission_energy": emission_energy})
	if outline > 0.0:
		material.next_pass = shader_material(OUTLINE, {"thickness": outline})
	return material


## Unshaded glowing material for magic, lanterns and light effects.
static func glow(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
