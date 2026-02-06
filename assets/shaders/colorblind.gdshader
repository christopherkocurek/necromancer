shader_type canvas_item;

uniform int mode : hint_range(0, 3) = 0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (mode == 0) {
		COLOR = c;
		return;
	}
	// Daltonization matrices
	mat3 to_lms = mat3(
		vec3(0.31399022, 0.63951294, 0.04649755),
		vec3(0.15537241, 0.75789446, 0.08670142),
		vec3(0.01775239, 0.10944209, 0.87256922)
	);
	mat3 from_lms = mat3(
		vec3(5.47221206, -4.6419601, 0.16963708),
		vec3(-1.1252419, 2.29317094, -0.1678952),
		vec3(0.02980165, -0.19318073, 1.16364789)
	);
	mat3 sim;
	if (mode == 1) { // Protanopia
		sim = mat3(
			vec3(0.0, 1.05118294, -0.05116099),
			vec3(0.0, 1.0, 0.0),
			vec3(0.0, 0.0, 1.0)
		);
	} else if (mode == 2) { // Deuteranopia
		sim = mat3(
			vec3(1.0, 0.0, 0.0),
			vec3(0.9513092, 0.0, 0.04866992),
			vec3(0.0, 0.0, 1.0)
		);
	} else { // Tritanopia
		sim = mat3(
			vec3(1.0, 0.0, 0.0),
			vec3(0.0, 1.0, 0.0),
			vec3(-0.86744736, 1.86727089, 0.0)
		);
	}
	vec3 lms = to_lms * c.rgb;
	vec3 sim_lms = sim * lms;
	vec3 error = lms - sim_lms;
	// Daltonize: shift error to visible channels
	vec3 correction;
	correction.r = 0.0;
	correction.g = 0.7 * error.r + 1.0 * error.g;
	correction.b = 0.7 * error.r + error.b;
	COLOR = vec4(clamp(c.rgb + correction, vec3(0.0), vec3(1.0)), c.a);
}
