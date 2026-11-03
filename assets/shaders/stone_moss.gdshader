// Ancient stone with moss growing on upward-facing surfaces ("moss grows on forgotten stone").
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 stone : source_color = vec4(0.66, 0.64, 0.6, 1.0);
uniform vec4 moss : source_color = vec4(0.36, 0.52, 0.22, 1.0);
uniform sampler2D noise_tex : hint_default_white;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.6;
varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float n = texture(noise_tex, wpos.xz * 0.3 + vec2(wpos.y * 0.2)).r;
	float m = smoothstep(0.35, 0.8, wnorm.y * moss_amount + n * 0.6 - wpos.y * 0.04);
	ALBEDO = mix(stone.rgb * (0.85 + n * 0.3), moss.rgb, m);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vec3(1.0, 0.9, 0.75) * rim * 0.15;
}
