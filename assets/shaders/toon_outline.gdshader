// Inverted-hull outline. Set as next_pass of a toon material. Thickness is in metres.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.12, 0.08, 0.14, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.02;
// Never thinner than this many screen pixels (0 = off): a fine line up close that still shows from far away.
uniform float min_pixels : hint_range(0.0, 4.0) = 0.0;

// Occlusion fade (0 = solid, 1 = gone), set per object by the camera rig with
// set_instance_shader_parameter("fade", x). Dithered, so the object stays in the cheap opaque pass.
instance uniform float fade : hint_range(0.0, 1.0) = 0.0;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);


void vertex() {
	float width = thickness;
	// Perspective views only: shadow maps (orthographic for the sun) would blow the line up into a big blob shadow.
	if (min_pixels > 0.0 && PROJECTION_MATRIX[3][3] == 0.0) {
		float depth = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
		float pixel = 2.0 * depth / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y) / length(MODEL_MATRIX[1].xyz);
		width = max(width, min_pixels * pixel);
	}
	VERTEX += NORMAL * width;
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
