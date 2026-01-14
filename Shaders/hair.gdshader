shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;

varying vec3 pos;
uniform vec3 reference_point; // World position of reference bone
uniform mat3 reference_rotation; // Rotation matrix of reference bone (inverse)
uniform vec3 base_color: source_color;
uniform vec3 highlight_color: source_color;
uniform float low_bound;
uniform float high_bound;

void vertex() { 
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 relative_pos = world_pos - reference_point;
    pos = reference_rotation * relative_pos; // Rotate into bone's local space
}

// Inverse lerp of x with bounds a, b
float linearstep(float a, float b, float x) {
    float result = (x - a) / (b - a);
	result = clamp(result, 0., 1.);
    return result;
}

bool in_arrow(float x, float y) {
	x = fract(x);
	y = fract(y);
	bool result = false;
	if (x + y < 1.) result = true;
	if (x + y + .3 < 1.) result = false;
	return result;
}

void fragment() {
	float height_unscaled = pos.y;
	float height = linearstep(low_bound, high_bound, height_unscaled); // From 0. to 1.
	float angle = acos(dot(normalize(vec2(pos.x, pos.z)), vec2(0, -1))) / PI; // From 0. to 1.

	vec3 color = base_color;

	float t = TIME * 2.;

	float mult = clamp(.5-height, 0., 1.);
	mult = 1.;
	if (in_arrow(angle, height-t)) color += highlight_color * mult; // Hair Highlight

	color = clamp(color, vec3(0.), vec3(1.)); // Prevent Bloom
	ALBEDO = color;
	if (height > 1.) ALBEDO = vec3(1.); // Debugging
	if (height < 0.) ALBEDO = vec3(0.); // Debugging
}