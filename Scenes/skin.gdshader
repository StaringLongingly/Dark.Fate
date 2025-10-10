shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;
varying vec3 pos;
varying vec3 normal;

uniform vec3 lighting_angle;
uniform float gamma: hint_range(0.0, 1.0, 0.01);
uniform vec3 light_color: source_color;
uniform vec3 base_color: source_color;

void vertex() { pos = VERTEX; normal = NORMAL; }

// Inverse lerp of x with bounds a, b
float linearstep(float a, float b, float x) {
    float result = (x - a) / (b - a);
    clamp(result, 0., 1.);
    return result;
}

void fragment() {
	float dot_product = dot(normalize(lighting_angle), NORMAL);
	float lambert = clamp(dot_product, 0., 1.);
	float t = lambert + gamma;
	
	vec3 color = mix(base_color, light_color, t);
	color = clamp(color, vec3(0.), vec3(1.)); // Prevent Bloom
	ALBEDO = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), color.rgb * (1.0 / 12.92), lessThan(color.rgb, vec3(0.04045)));
}