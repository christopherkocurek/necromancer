shader_type canvas_item;

// Book cover depth shader - simulates embossed leather with a sense of
// physical thickness and dimensionality. Applied to the cover TextureRect.

uniform float depth_intensity : hint_range(0.0, 0.5) = 0.2;
uniform vec2 light_dir = vec2(-0.4, -0.3); // Light from upper-left
uniform float edge_darken : hint_range(0.0, 0.3) = 0.12;
uniform float inner_shadow : hint_range(0.0, 0.2) = 0.06;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;

    // Pseudo-normal from height map (using luminance as height)
    float h_center = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    float h_right = dot(texture(TEXTURE, UV + vec2(pixel_size.x * 2.0, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float h_down = dot(texture(TEXTURE, UV + vec2(0.0, pixel_size.y * 2.0)).rgb, vec3(0.299, 0.587, 0.114));

    vec2 normal = vec2(h_center - h_right, h_center - h_down);

    // Directional light dot product
    float ndotl = dot(normalize(normal), normalize(light_dir));
    float shade = 0.5 + ndotl * depth_intensity;

    // Edge darkening (book thickness illusion)
    float edge_x = smoothstep(0.0, 0.04, UV.x) * smoothstep(1.0, 0.96, UV.x);
    float edge_y = smoothstep(0.0, 0.04, UV.y) * smoothstep(1.0, 0.96, UV.y);
    float edge = edge_x * edge_y;
    shade *= mix(1.0 - edge_darken, 1.0, edge);

    // Inner shadow at page opening (center of book)
    float center_dist = abs(UV.x - 0.5);
    float center_shadow = smoothstep(0.02, 0.08, center_dist);
    shade *= mix(1.0 - inner_shadow, 1.0, center_shadow);

    COLOR = vec4(tex.rgb * shade, tex.a);
}
