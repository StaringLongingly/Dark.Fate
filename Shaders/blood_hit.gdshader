shader_type spatial;
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled;

uniform float height: hint_range(0.0, 1.0, 0.01) = 0.;
uniform float t_spawn: hint_range(0.0, 1.0, 0.01) = 0.;
uniform float t_despawn: hint_range(0.0, 1.0, 0.01) = 0.;
uniform uint resolution = 16;

uniform vec3 start_color: source_color;
uniform vec3 end_color: source_color;

bool in_square(vec2 p, float h) {
	return abs(p.y) < h;
}

bool in_triangle(vec2 p, float t) {
	return (p.x + abs(p.y) < t);
}

bool should_render(vec2 p, float t1, float t2, float h) {
	bool result = true;
	result = result && in_square(p, h);
	result = result && in_triangle(p, t1);
	result = result && !in_triangle(p, t2);
	return result;
}

float rand(vec2 co) { return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	if (UV.x < .5) discard;
	vec2 uv = vec2(
		UV.x*2.-1.,
		(UV.y-.5)*2.
	);
	uv = floor(uv * float(resolution)) / float(resolution);

	if (!should_render(uv, t_spawn, t_despawn, height)) discard;
	float t_blend = t_despawn * rand(uv);
	vec3 color = mix(start_color, end_color, t_blend);
	ALBEDO = color;
}