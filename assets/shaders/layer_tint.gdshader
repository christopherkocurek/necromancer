shader_type canvas_item;

// Layer tint color - multiplied with texture color
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// How strongly to apply the tint (0.0 = no tint, 1.0 = full tint)
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;

// Gamma correction for dark DCSS terrain tiles (lower = brighter)
uniform float gamma : hint_range(0.1, 1.0) = 0.4;

// Magenta transparency tolerance (for DCSS tileset)
uniform float magenta_tolerance : hint_range(0.01, 0.5) = 0.15;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // First check for magenta transparency (from DCSS tileset)
    bool is_magenta = tex.r > 0.8 &&
                      tex.g < magenta_tolerance &&
                      tex.b > 0.8 &&
                      abs(tex.r - tex.b) < 0.2;

    if (is_magenta) {
        discard;
    }

    // Brighten dark DCSS terrain tiles with gamma correction
    vec3 bright = pow(tex.rgb, vec3(gamma));

    // Apply layer tint
    vec4 base = vec4(bright, tex.a);
    vec4 tinted = base * tint_color;
    COLOR = mix(base, tinted, tint_strength);
}
