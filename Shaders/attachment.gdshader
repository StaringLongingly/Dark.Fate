shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D tex: source_color, filter_nearest;
uniform vec2 curvature;
uniform bool anisotropic;
uniform vec2 mesh_size;

float curve(float size, float input, float strength) {
	float normalized = input / size;
	return normalized * normalized * strength;
}

void vertex() {
	vec2 curve_amount = curvature;
	vec2 size = mesh_size;

	if (!anisotropic) {
		curve_amount.y = curve_amount.x;
		size.y = size.x;
	}

	VERTEX.z += curve(size.x, VERTEX.x, curve_amount.x);
	VERTEX.z += curve(size.y, VERTEX.y, curve_amount.y);
}

void fragment() {
	vec4 color = texture(tex, UV);
	ALPHA = color.a;
	ALBEDO = color.rgb;
}