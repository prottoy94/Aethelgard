// Inverted-hull outline. Set as next_pass of a toon material. Thickness is in metres.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.12, 0.08, 0.14, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.02;

// Occlusion fade (0 = solid, 1 = gone), set per object by the camera rig with
// set_instance_shader_parameter("fade", x). Dithered, so the object stays in the cheap opaque pass.
instance uniform float fade : hint_range(0.0, 1.0) = 0.0;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);


void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	if (fade > 0.0) {
		int bx = int(mod(FRAGCOORD.x, 4.0));
		int by = int(mod(FRAGCOORD.y, 4.0));
		if ((BAYER[bx + by * 4] + 0.5) / 16.0 < fade) {
			discard;
		}
	}
	ALBEDO = outline_color.rgb;
}
