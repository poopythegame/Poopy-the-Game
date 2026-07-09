shader_type canvas_item;
render_mode unshaded;

uniform vec2 texture_scale = vec2(512.0, 512.0);
uniform vec2 texture_offset = vec2(0.0, 0.0);

varying vec2 world_pos;

void vertex() {
	world_pos = vec2((MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy);
}

void fragment() {
	vec2 uv = (world_pos + texture_offset) / texture_scale;
	float y = UV.y * texture_scale.y;
	if (y < 0.0 || y > 1.0)
		COLOR.a = 0.0;
	else
		COLOR = texture(TEXTURE, vec2(uv.x, y));
}
