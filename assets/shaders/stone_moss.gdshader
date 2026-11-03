// Ancient stone with moss growing on upward-facing surfaces ("moss grows on forgotten stone").
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 stone : source_color = vec4(0.66, 0.64, 0.6, 1.0);
uniform vec4 moss : source_color = vec4(0.36, 0.52, 0.22, 1.0);
uniform sampler2D noise_tex : hint_default_white;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.6;

// Occlusion fade (0 = solid, 1 = gone), set per object by the camera rig with
// set_instance_shader_parameter("fade", x). Dithered, so the object stays in the cheap opaque pass.
instance uniform float fade : hint_range(0.0, 1.0) = 0.0;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (fade > 0.0) {
		int bx = int(mod(FRAGCOORD.x, 4.0));
		int by = int(mod(FRAGCOORD.y, 4.0));
		if ((BAYER[bx + by * 4] + 0.5) / 16.0 < fade) {
			discard;
		}
	}
	float n = texture(noise_tex, wpos.xz * 0.3 + vec2(wpos.y * 0.2)).r;
	float m = smoothstep(0.35, 0.8, wnorm.y * moss_amount + n * 0.6 - wpos.y * 0.04);
	ALBEDO = mix(stone.rgb * (0.85 + n * 0.3), moss.rgb, m);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vec3(1.0, 0.9, 0.75) * rim * 0.15;
}
