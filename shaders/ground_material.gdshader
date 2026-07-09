shader_type canvas_item;
render_mode unshaded;

uniform vec2 texture_scale = vec2(512.0, 512.0);
uniform vec2 texture_offset = vec2(0.0, 0.0);

varying vec2 world_pos;

void vertex() {
	// Transform local vertex to world space using Godot 4 built-ins
	world_pos = vec2((MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy);
}

void fragment() {
	// Calculate UV coordinates based on absolute world position
	vec2 uv = (world_pos + texture_offset) / texture_scale;
	
	// Sample the texture
	COLOR = texture(TEXTURE, uv);
}
