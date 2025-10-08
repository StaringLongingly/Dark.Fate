shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;
varying vec3 pos;

uniform vec3 base_color: source_color;

void vertex() { pos = VERTEX; }

// Inverse lerp of x with bounds a, b
float linearstep(float a, float b, float x) {
    float result = (x - a) / (b - a);
    clamp(result, 0., 1.);
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
	const float LOW_BOUND = -.1;
	const float HIGH_BOUND = .1;
	float height = linearstep(LOW_BOUND, HIGH_BOUND, height_unscaled); // From 0. to 1.
	float angle = acos(dot(normalize(vec2(pos.x, pos.z)), vec2(0, -1))) / PI; // From 0. to 1.

	vec3 color = base_color;

	float t = TIME * 2.;

	float mult = clamp(.5-height, 0., 1.);
	mult = 1.;
	if (in_arrow(angle, height-t)) color += vec3(0., 0., 1.) * mult; // Hair Highlight

	color = clamp(color, vec3(0.), vec3(1.)); // Prevent Bloom
	ALBEDO = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), color.rgb * (1.0 / 12.92), lessThan(color.rgb, vec3(0.04045)));
	if (height > 1. || height < 0.) ALBEDO = vec3(1.); // Debugging
}