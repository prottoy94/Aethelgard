// Grass blades for MultiMesh: base-to-tip colour gradient, wind bend, flat "up" lighting so blades read as a soft field.
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.22, 0.42, 0.16, 1.0);
uniform vec4 tip_color : source_color = vec4(0.66, 0.8, 0.34, 1.0);
uniform float wind_strength : hint_range(0.0, 0.5) = 0.12;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float bend = UV.y * UV.y;
	VERTEX.x += sin(TIME * 2.0 + wp.x * 0.5 + wp.z * 0.4) * wind_strength * bend;
	VERTEX.z += cos(TIME * 1.6 + wp.z * 0.5) * wind_strength * 0.5 * bend;
}

void fragment() {
	ALBEDO = mix(base_color.rgb, tip_color.rgb, UV.y);
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
