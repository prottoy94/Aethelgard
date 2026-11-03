// Stylised turquoise water (placeholder): fresnel blend, glossy highlights, slight transparency.
shader_type spatial;
render_mode blend_mix, specular_schlick_ggx;

uniform vec4 shallow : source_color = vec4(0.38, 0.86, 0.86, 1.0);
uniform vec4 deep : source_color = vec4(0.1, 0.45, 0.66, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.88;

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(deep.rgb, shallow.rgb, 0.65 - f * 0.3);
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;
	ALPHA = opacity;
}
