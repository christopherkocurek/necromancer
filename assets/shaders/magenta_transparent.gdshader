shader_type canvas_item;

// How close to pure magenta a color must be (lower = more strict)
uniform float tolerance : hint_range(0.01, 0.5) = 0.15;

void fragment() {
    vec4 c = texture(TEXTURE, UV);

    // Pure magenta is (1.0, 0.0, 1.0)
    // Check if this pixel is close to pure magenta
    // Key characteristics: high red, very low green, high blue

    bool is_magenta = c.r > 0.8 &&          // High red
                      c.g < tolerance &&     // Very low green (the key)
                      c.b > 0.8 &&          // High blue
                      abs(c.r - c.b) < 0.2; // Red and blue are similar

    if (is_magenta) {
        discard;
    }
    COLOR = c;
}
