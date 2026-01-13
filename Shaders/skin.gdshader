shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;
varying vec3 pos;
varying vec3 normal;

uniform vec3 lighting_angle;
uniform float gamma: hint_range(0.0, 1.0, 0.01);
uniform vec3 light_color: source_color;
uniform vec3 base_color: source_color;
uniform float base_alpha: hint_range(0., 1., 0.01) = .8;

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
	float dot_product = dot(normalize(lighting_angle), NORMAL);
	float lambert = clamp(dot_product, 0., 1.);
	float t = lambert + gamma;
	
	vec3 color = mix(base_color, light_color, t);
	color = clamp(color, vec3(0.), vec3(1.)); // Prevent Bloom
	ALBEDO = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), color.rgb * (1.0 / 12.92), lessThan(color.rgb, vec3(0.04045)));
	
	// Figure out if it should render
	bool transparent = true;
	vec3 world_pos = (MODEL_MATRIX * vec4(pos, 1.0)).xyz;
	transparent = transparent && (distance(world_pos, head_pos) > head_radius);
	transparent = transparent && (distance(world_pos, left_hand_pos) > hand_radius);
	transparent = transparent && (distance(world_pos, right_hand_pos) > hand_radius);
	transparent = transparent && (distance(world_pos, left_foot_pos) > foot_radius);
	transparent = transparent && (distance(world_pos, right_foot_pos) > foot_radius);
	if (transparent) ALPHA = 0.;
	else ALPHA = clamp(base_alpha, 0., 1.);
}