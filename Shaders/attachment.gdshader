shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D tex: source_color, filter_nearest;
uniform vec2 mesh_size = vec2(1);
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

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

// Derivative of cubic bezier (for tangent calculation)
vec2 bezier_cubic_2d_derivative(float t, vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
	float u = 1.0 - t;
	float uu = u * u;
	float tt = t * t;
	
	return 3.0 * uu * (p1 - p0) + 6.0 * u * t * (p2 - p1) + 3.0 * tt * (p3 - p2);
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
		x3.y = x0.y;
	}
	if (y_mirror) {
		y2 = vec2(-y1.x, y1.y);
		y3.y = y0.y;
	}

	// X-axis curve
	float t_x = (VERTEX.x / half_size.x + 1.0) * 0.5;
	vec2 curve_x = bezier_cubic_2d(t_x, x0, x1, x2, x3);
	vec2 tangent_x = bezier_cubic_2d_derivative(t_x, x0, x1, x2, x3);
	
	// Y-axis curve
	float t_y = (VERTEX.y / half_size.y + 1.0) * 0.5;
	vec2 curve_y = bezier_cubic_2d(t_y, y0, y1, y2, y3);
	vec2 tangent_y = bezier_cubic_2d_derivative(t_y, y0, y1, y2, y3);

	// Apply deformation
	VERTEX.x = curve_x.x;
	VERTEX.y = curve_y.x;
	VERTEX.z = curve_x.y + curve_y.y;

	// Calculate tangent vectors in 3D space
	vec3 tangent_u = normalize(vec3(tangent_x.x, 0.0, tangent_x.y));
	vec3 tangent_v = normalize(vec3(0.0, tangent_y.x, tangent_y.y));
	
	// Calculate normal as cross product of tangents
	vec3 new_normal = normalize(cross(tangent_u, tangent_v));
	
	// Update the normal
	NORMAL = new_normal;
}

void fragment() {
	vec4 color = texture(tex, UV);
	
	// Alpha scissor: discard pixels below threshold
	if (color.a < alpha_scissor) {
		discard;
	}
	
	// Treat as fully opaque - don't set ALPHA at all
	ALBEDO = color.rgb;
}