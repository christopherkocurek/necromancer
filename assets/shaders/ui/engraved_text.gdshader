shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 0.15);
uniform vec2 shadow_offset = vec2(1.0, 1.0);
uniform vec2 highlight_offset = vec2(-1.0, -1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;

    // Shadow (bottom-right)
    vec4 shadow = texture(TEXTURE, UV - shadow_offset * pixel_size);
    // Highlight (top-left)
    vec4 highlight = texture(TEXTURE, UV - highlight_offset * pixel_size);

    // Composite: shadow behind, then highlight, then text on top
    vec4 result = vec4(0.0);
    result = mix(result, shadow_color, shadow.a * shadow_color.a * (1.0 - tex.a));
    result = mix(result, highlight_color, highlight.a * highlight_color.a * (1.0 - tex.a));
    result = mix(result, tex, tex.a);

    COLOR = result;
}
