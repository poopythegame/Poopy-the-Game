shader_type canvas_item;

uniform float progress = 0.;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    if (SCREEN_UV.x < progress)
        COLOR = texture(screen_texture, SCREEN_UV);
    else
        COLOR = vec4(0.);
}