shader_type canvas_item;

uniform sampler2D tex : repeat_enable; 

void fragment() {
    // Samples the real texture using the mesh's UV coordinates
    COLOR = texture(tex, UV);
}