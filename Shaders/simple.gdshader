shader_type spatial;
render_mode unshaded;

uniform sampler2D top_texture: source_color, filter_nearest;
uniform sampler2D side_texture: source_color, filter_nearest;
uniform sampler2D bottom_texture: source_color, filter_nearest;
uniform vec2 uv_scale = vec2(1);
varying vec3 model_pos;

void vertex() {
    model_pos = VERTEX;
}
void fragment() {
	vec2 uv = fract(UV * uv_scale);
	vec4 color = texture(side_texture, uv);
	if (model_pos.y > .999) color = texture(top_texture, UV*2.);
	if (model_pos.y < -.999) color = texture(bottom_texture, UV*2.);
	
	
	ALBEDO = color.rgb;
	//ALBEDO = vec3(uv, 0.);
	ALPHA = color.a;
}
