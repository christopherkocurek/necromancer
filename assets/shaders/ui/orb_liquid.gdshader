shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 0.5;
uniform vec4 liquid_color : source_color = vec4(0.55, 0.1, 0.1, 1.0);
uniform vec4 liquid_surface : source_color = vec4(0.8, 0.15, 0.15, 1.0);
uniform float wobble_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wobble_amount : hint_range(0.0, 0.1) = 0.02;
uniform bool is_critical = false;

void fragment() {
    vec2 uv = UV;

    // Circular mask - discard pixels outside the orb
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    if (dist > 0.44) {
        discard;
    }

    // Wobble the fill line with sine wave
    float wave = sin(uv.x * 12.0 + TIME * wobble_speed) * wobble_amount;
    wave += sin(uv.x * 7.0 - TIME * wobble_speed * 0.7) * wobble_amount * 0.5;
    float fill_line = 1.0 - fill_level + wave;

    if (uv.y < fill_line) {
        // Empty portion (above liquid) - very dark
        float empty_depth = 1.0 - (uv.y / fill_line);
        COLOR = vec4(vec3(0.03 + empty_depth * 0.02), 0.95);
    } else {
        // Liquid portion
        float liquid_depth = (uv.y - fill_line) / max(fill_level, 0.01);
        COLOR = mix(liquid_surface, liquid_color, liquid_depth * 0.7);

        // Surface highlight (bright line at liquid surface)
        float surface_dist = abs(uv.y - fill_line);
        float surface_glow = smoothstep(0.025, 0.0, surface_dist);
        COLOR.rgb += vec3(0.25) * surface_glow;

        // Depth caustics (subtle moving light patterns in liquid)
        float caustic = sin(uv.x * 20.0 + uv.y * 15.0 + TIME * 1.5) * 0.5 + 0.5;
        caustic *= sin(uv.x * 13.0 - uv.y * 11.0 + TIME * 1.1) * 0.5 + 0.5;
        COLOR.rgb += vec3(0.03) * caustic * liquid_depth;
    }

    // Critical pulse effect (whole orb pulses when low)
    if (is_critical) {
        float pulse = sin(TIME * 4.0) * 0.5 + 0.5;
        COLOR.rgb += vec3(0.08, 0.0, 0.0) * pulse;
    }

    // Spherical depth illusion - darken edges
    float edge_factor = smoothstep(0.3, 0.44, dist);
    COLOR.rgb *= 1.0 - edge_factor * 0.6;

    // Glass highlight (top-left specular)
    float spec_dist = distance(uv, vec2(0.32, 0.28));
    float specular = smoothstep(0.18, 0.0, spec_dist) * 0.15;
    COLOR.rgb += vec3(specular);

    // Secondary smaller highlight
    float spec2_dist = distance(uv, vec2(0.38, 0.35));
    float specular2 = smoothstep(0.08, 0.0, spec2_dist) * 0.08;
    COLOR.rgb += vec3(specular2);
}
