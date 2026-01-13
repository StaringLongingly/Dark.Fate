shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D tex: source_color, filter_nearest;

uniform bool flip_x = false;
uniform bool black_background = false;

void fragment() {
	vec2 uv = UV;
	if (flip_x) uv.x = 1. - uv.x;
	vec4 color = texture(tex, uv);
	ALBEDO = color.rgb;
	if (black_background) ALPHA = (color.r+color.g+color.b)/3.;
	else ALPHA = color.a;
}