// Inverted-hull outline. Set as next_pass of a toon material. Thickness is in metres.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.12, 0.08, 0.14, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
