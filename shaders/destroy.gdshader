shader_type canvas_item;

uniform float t = 0;

void fragment() {
	vec4 normal_color = texture(TEXTURE, UV);
	if (UV.y > t) {
		COLOR = normal_color;
	} else {
		COLOR = vec4(0);
	}
}