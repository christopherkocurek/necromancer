shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec4 glow_color : source_color = vec4(0.784, 0.659, 0.306, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;

    // Only glow on border pixels (where alpha transitions)
    float edge = tex.a * (1.0 - texture(TEXTURE, UV + vec2(0.02, 0.0)).a);
    edge += tex.a * (1.0 - texture(TEXTURE, UV - vec2(0.02, 0.0)).a);
    edge += tex.a * (1.0 - texture(TEXTURE, UV + vec2(0.0, 0.02)).a);
    edge += tex.a * (1.0 - texture(TEXTURE, UV - vec2(0.0, 0.02)).a);
    edge = clamp(edge, 0.0, 1.0);

    COLOR = tex;
    COLOR.rgb += glow_color.rgb * edge * glow_intensity * pulse;
}
