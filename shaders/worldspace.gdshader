shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable;
uniform float scale = 0.05; // Adjust how large the texture appears in world space

varying vec2 world_pos;

void vertex() {
	// Convert local vertex position into global world space coordinates
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Sample the texture based on world position rather than local UV
	vec2 uv = world_pos * scale;
	COLOR = texture(noise_tex, uv);
}