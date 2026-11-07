// Aethelgard soft toon shader for character skin and hair: the same two-tone anime look as toon.gdshader, but each
// light counts for less and the shaded side keeps a tinted share of it. Pale colours (silver hair, light skin) then
// keep their tone: no washing out to white in bright sun, no dropping to grey in shade. Like anime faces, it doesn't
// receive cast shadows. Pair with toon_outline.gdshader as next_pass for outlines.
shader_type spatial;
render_mode shadows_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Multiply by the mesh's vertex colours (sRGB): painted gradients such as eyes, blush and hair shine.
uniform bool use_vertex_color = false;
// Share of each light that reaches the surface (ambient light is added as usual).
uniform float light_amount : hint_range(0.0, 2.0) = 0.5;
// How much of the light's own colour tints the surface (lower keeps warm sunsets from turning skin yellow).
uniform float light_tint : hint_range(0.0, 1.0) = 1.0;
// The shaded side: share of the light it still gets, its tint, and how soft the edge between the two tones is.
uniform float shade_amount : hint_range(0.0, 1.0) = 0.5;
uniform vec4 shade_tint : source_color = vec4(1.0, 0.86, 0.86, 1.0);
uniform float shade_softness : hint_range(0.0, 0.5) = 0.08;
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.8, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.1;

// Occlusion fade and hit flash, set per object like in toon.gdshader.
instance uniform float fade : hint_range(0.0, 1.0) = 0.0;
instance uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);


vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	if (fade > 0.0) {
		int bx = int(mod(FRAGCOORD.x, 4.0));
		int by = int(mod(FRAGCOORD.y, 4.0));
		if ((BAYER[bx + by * 4] + 0.5) / 16.0 < fade) {
			discard;
		}
	}
	vec3 base = albedo.rgb;
	if (use_vertex_color) {
		base *= srgb_to_linear(COLOR.rgb);
	}
	ALBEDO = base;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim_color.rgb * rim * rim_strength + vec3(hit_flash * 2.5);
}

void light() {
	float lit = smoothstep(-shade_softness, shade_softness, dot(NORMAL, LIGHT));
	vec3 tone = mix(shade_tint.rgb * shade_amount, vec3(1.0), lit);
	vec3 light_rgb = LIGHT_COLOR / PI;
	light_rgb = mix(vec3(dot(light_rgb, vec3(0.299, 0.587, 0.114))), light_rgb, light_tint);
	DIFFUSE_LIGHT += light_rgb * ATTENUATION * tone * light_amount;
}
