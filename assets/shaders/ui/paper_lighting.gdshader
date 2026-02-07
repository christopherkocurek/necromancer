shader_type canvas_item;

// Directional candlelight + paper grain shader for parchment pages.
// Simulates a light source hitting aged paper from one direction,
// with subtle fiber grain that catches the light.

uniform vec2 light_pos = vec2(0.25, 0.15); // Candlelight from upper-left
uniform float light_intensity : hint_range(0.0, 0.5) = 0.12;
uniform float grain_amount : hint_range(0.0, 0.1) = 0.025;
uniform float grain_scale : hint_range(10.0, 200.0) = 80.0;
uniform float warmth : hint_range(0.0, 0.2) = 0.04; // Warm candlelight tint
uniform float shadow_at_spine : hint_range(0.0, 0.3) = 0.08; // Darken near spine edge
uniform float desaturation : hint_range(0.0, 1.0) = 0.45; // Tame busy textures for readability
uniform float brightness_boost : hint_range(0.8, 1.5) = 1.15; // Lighten for text contrast

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Step 1: Desaturate and lighten FIRST so the texture is UI-friendly
    float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    vec3 tamed = mix(tex.rgb, vec3(gray), desaturation) * brightness_boost;

    // Directional lighting (falloff from light position)
    float dist = distance(UV, light_pos);
    float light = 1.0 + light_intensity * (1.0 - dist * 1.3);

    // Subtle paper grain using procedural noise (reduced from original)
    float n1 = fract(sin(dot(UV * grain_scale, vec2(12.9898, 78.233))) * 43758.5453);
    float n2 = fract(sin(dot(UV * grain_scale * 1.7, vec2(93.9898, 67.345))) * 24634.6345);
    float grain = (n1 * 0.6 + n2 * 0.4 - 0.5) * grain_amount * 0.5;

    // Warm candlelight color shift
    vec3 lit = tamed * light + grain;
    lit.r += warmth * light;
    lit.g += warmth * 0.5 * light;

    // Darken near left edge (spine shadow / gutter)
    float spine_shadow = smoothstep(0.0, 0.15, UV.x);
    lit *= mix(1.0 - shadow_at_spine, 1.0, spine_shadow);

    COLOR = vec4(lit, tex.a);
}
