shader_type spatial;
render_mode unshaded;
render_mode cull_disabled; // Janky geometry T-T
render_mode blend_mix, depth_draw_opaque; // For effects
varying vec3 pos;
varying vec3 normal;

uniform vec3 lighting_angle;
uniform float gamma: hint_range(-1.0, 1.0, 0.01);
uniform bool use_lambert = true;
uniform vec3 light_color: source_color;
uniform float light_strength: hint_range(0.0, 1.0, 0.01);
uniform vec3 base_color: source_color;

uniform float head_radius = 2.;
uniform float hand_radius = 2.;
uniform float foot_radius = 2.;

uniform vec3 head_pos;
uniform vec3 left_hand_pos;
uniform vec3 right_hand_pos;
uniform vec3 left_foot_pos;
uniform vec3 right_foot_pos;

void vertex() { pos = VERTEX; normal = NORMAL; }

// Inverse lerp of x with bounds a, b
float linearstep(float a, float b, float x) {
    float result = (x - a) / (b - a);
    result = clamp(result, 0., 1.);
    return result;
}

void fragment() {
	float t = 0.;
	if (use_lambert) {
		float dot_product = dot(normalize(lighting_angle), NORMAL);
		float lambert = clamp(dot_product, 0., 1.);
		t = lambert;
	}
	
	vec3 color = mix(base_color, light_color, pow(t, 1./light_strength)) + gamma;
	color = clamp(color, vec3(0.), vec3(1.)); // Prevent Bloom
	ALBEDO = color;
	ALPHA = 1.;
	
	// Figure out if it should render
	bool transparent = true;
	vec3 world_pos = (MODEL_MATRIX * vec4(pos, 1.0)).xyz;
	transparent = transparent && (distance(world_pos, head_pos) > head_radius);
	transparent = transparent && (distance(world_pos, left_hand_pos) > hand_radius);
	transparent = transparent && (distance(world_pos, right_hand_pos) > hand_radius);
	transparent = transparent && (distance(world_pos, left_foot_pos) > foot_radius);
	transparent = transparent && (distance(world_pos, right_foot_pos) > foot_radius);
	if (transparent) discard;
}