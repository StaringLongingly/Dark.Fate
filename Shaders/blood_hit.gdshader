shader_type spatial;
render_mode unshaded;

uniform float t_size: hint_range(0.0, 1.0, 0.01) = 0.;
uniform float t_alpha: hint_range(0.0, 1.0, 0.01) = 0.;
uniform float t_color: hint_range(0.0, 1.0, 0.01) = 0.;

uniform vec3 start_color: source_color;
uniform vec3 end_color: source_color;

// Converts a color from linear light gamma to sRGB gamma
vec4 from_linear(vec4 linearRGB) {
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);
    return vec4(mix(higher, lower, cutoff), linearRGB.a);
}

bool in_star(vec2 p, float t_x, float t_y) {
	p.x = abs(p.x)/t_x;
	p.y = abs(p.y)/t_y;
	return p.x + p.y < 1.;
}

void fragment() {
	vec2 uv = UV;
	uv = (uv-.5)*2.;

	if (!in_star(uv, sqrt(t_size), t_size*t_size)) ALPHA = 0.;
	else ALPHA = 1.-t_alpha;
	ALBEDO = vec3(mix(start_color, end_color, t_color));

}