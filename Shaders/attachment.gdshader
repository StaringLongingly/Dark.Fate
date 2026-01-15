shader_type spatial;
render_mode unshaded, cull_disabled;
render_mode blend_mix, depth_draw_opaque; // For effects

uniform sampler2D tex: source_color, filter_nearest;
uniform vec2 mesh_size = vec2(1);

// X-axis bezier curve (4 2D points)
uniform bool x_mirror = true;
uniform vec2 x_point_0 = vec2(-.5,0);
uniform vec2 x_point_1 = vec2(-.165,0);
uniform vec2 x_point_2 = vec2(.165, 0);
uniform vec2 x_point_3 = vec2(.5,0);

// Y-axis bezier curve (4 2D points)
uniform bool y_mirror = true;
uniform vec2 y_point_0 = vec2(-.5,0);
uniform vec2 y_point_1 = vec2(-.165,0);
uniform vec2 y_point_2 = vec2(.165, 0);
uniform vec2 y_point_3 = vec2(.5,0);

// 2D Cubic bezier curve function
vec2 bezier_cubic_2d(float t, vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
	float u = 1.0 - t;
	float tt = t * t;
	float uu = u * u;
	float uuu = uu * u;
	float ttt = tt * t;

	return uuu * p0 + 3.0 * uu * t * p1 + 3.0 * u * tt * p2 + ttt * p3;
}

void vertex() {
	vec2 half_size = mesh_size / 2.0;

	vec2 x0 = x_point_0;
	vec2 x1 = x_point_1;
	vec2 x2 = x_point_2;
	vec2 x3 = x_point_3;

	vec2 y0 = y_point_0;
	vec2 y1 = y_point_1;
	vec2 y2 = y_point_2;
	vec2 y3 = y_point_3;

	// Lock endpoints to mesh boundaries
	x0.x = -half_size.x;
	x3.x = half_size.x;
	y0.x = -half_size.y;
	y3.x = half_size.y;

	// Mirror points
	if (x_mirror) {
		x2 = vec2(-x1.x, x1.y);
		x3.y = x0.y; // Mirror Y value but keep X locked
	}
	if (y_mirror) {
		y2 = vec2(-y1.x, y1.y);
		y3.y = y0.y; // Mirror Y value but keep X locked
	}

	// X-axis curve: interpolate based on vertex X position
	float t_x = (VERTEX.x / half_size.x + 1.0) * 0.5; // Convert from -half_size..half_size to 0..1
	vec2 curve_x = bezier_cubic_2d(t_x, x0, x1, x2, x3);
	VERTEX.x = curve_x.x; // Use curve's X for actual X position
	VERTEX.z += curve_x.y; // Use curve's Y for Z offset

	// Y-axis curve: interpolate based on vertex Y position
	float t_y = (VERTEX.y / half_size.y + 1.0) * 0.5; // Convert from -half_size..half_size to 0..1
	vec2 curve_y = bezier_cubic_2d(t_y, y0, y1, y2, y3);
	VERTEX.y = curve_y.x; // Use curve's X for actual Y position
	VERTEX.z += curve_y.y; // Use curve's Y for Z offset
}

void fragment() {
	vec4 color = texture(tex, UV);
	ALPHA = color.a;
	ALBEDO = color.rgb;
}