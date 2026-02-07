shader_type canvas_item;

// Page turn overlay shader - creates a sweeping fold/shadow effect.
// Apply to a TextureRect overlay covering the page area.
// Animate 'progress' from 0.0 -> 1.0 for a full page turn.
// At progress=0.5, swap the content underneath.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 page_tint : source_color = vec4(0.85, 0.78, 0.65, 1.0);
uniform float shadow_width : hint_range(0.05, 0.4) = 0.15;

void fragment() {
    // Fold position sweeps right-to-left (first half) then left-to-right (second half)
    float fold_x;
    if (progress < 0.5) {
        fold_x = 1.0 - progress * 2.0;
    } else {
        fold_x = (progress - 0.5) * 2.0;
    }

    float dist = UV.x - fold_x;

    // Shadow that falls ahead of the fold (the curling page casts shadow)
    float shadow = smoothstep(0.0, shadow_width, dist) * (1.0 - smoothstep(shadow_width, shadow_width * 2.5, dist));
    shadow *= 0.5;

    // Bright edge highlight at the fold crease (paper edge catching light)
    float edge = 1.0 - smoothstep(0.0, 0.02, abs(dist));
    float highlight = edge * 0.6;

    // Page covering: area on the fold side shows the turning page
    float cover;
    if (progress < 0.5) {
        // First half: fold sweeps left, page covers from right
        cover = smoothstep(0.01, 0.0, dist); // left of fold = covered by turning page
    } else {
        // Second half: fold sweeps right, revealing new page
        cover = smoothstep(-0.01, 0.0, dist); // right of fold = covered
    }

    // The turning page itself (slightly visible, semi-transparent parchment)
    float page_alpha = cover * 0.35;

    // Combined: shadow darkening + page tint + highlight
    float final_alpha = shadow + page_alpha + highlight;
    vec3 final_color = mix(vec3(0.05, 0.04, 0.03), page_tint.rgb, cover * 0.6 + highlight);

    COLOR = vec4(final_color, clamp(final_alpha, 0.0, 0.85));
}
