// Aethelgard toon shader: two-tone anime shading, soft rim light, optional wind sway and glow.
// Used for characters, props and foliage. Pair with toon_outline.gdshader as next_pass for outlines.
shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.8, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.35;
// Wind sway in metres at the top of the mesh; 0 = static.
uniform float wind : hint_range(0.0, 1.0) = 0.0;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 16.0) = 0.0;

// Occlusion fade (0 = solid, 1 = gone), set per object by the camera rig with
// set_instance_shader_parameter("fade", x). Dithered, so the object stays in the cheap opaque pass.
instance uniform float fade : hint_range(0.0, 1.0) = 0.0;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);


void vertex() {
	if (wind > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		VERTEX.x += sin(TIME * 1.2 + wp.x * 0.35 + wp.z * 0.25) * wind;
		VERTEX.z += cos(TIME * 0.9 + wp.x * 0.2) * wind * 0.5;
	}
}

void fragment() {
	if (fade > 0.0) {
		int bx = int(mod(FRAGCOORD.x, 4.0));
		int by = int(mod(FRAGCOORD.y, 4.0));
		if ((BAYER[bx + by * 4] + 0.5) / 16.0 < fade) {
			discard;
		}
	}
	ALBEDO = albedo.rgb * texture(albedo_texture, UV).rgb;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim_color.rgb * rim * rim_strength + emission.rgb * emission_energy;
}
