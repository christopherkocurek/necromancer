shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec2 uv = UV * 2.0 - 1.0;
    float vignette = 1.0 - dot(uv * (1.0 - softness), uv * (1.0 - softness));
    vignette = clamp(vignette, 0.0, 1.0);
    vignette = smoothstep(0.0, 1.0, vignette);

    COLOR = tex;
    COLOR.rgb = mix(vignette_color.rgb, COLOR.rgb, mix(1.0, vignette, intensity));
}
