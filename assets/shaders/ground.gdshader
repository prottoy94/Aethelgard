// Painterly ground: two grass tones broken up by noise, plus dirt where the vertex colour's red channel is high
// (paint paths into the mesh colours). Placeholder version: a winding path is generated from world position.
// `paths` off: plain grass (for meshes without painted colours, where paths are separate meshes).
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 grass_a : source_color = vec4(0.3, 0.52, 0.2, 1.0);
uniform vec4 grass_b : source_color = vec4(0.45, 0.62, 0.25, 1.0);
uniform vec4 dirt : source_color = vec4(0.62, 0.5, 0.33, 1.0);
uniform sampler2D noise_tex : hint_default_white;
uniform bool procedural_path = true;
uniform bool paths = true;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = texture(noise_tex, wpos.xz * 0.02).r;
	vec3 g = mix(grass_a.rgb, grass_b.rgb, n);
	float path = COLOR.r;
	if (procedural_path) {
		float d = abs(wpos.x - sin(wpos.z * 0.08) * 5.0);
		path = 1.0 - smoothstep(1.0, 1.8, d + (n - 0.5) * 1.2);
	}
	ALBEDO = mix(g, dirt.rgb, paths ? path : 0.0);
}
