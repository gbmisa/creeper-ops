shader_type sky;
render_mode use_debanding;

// Warm dusk. The sun disc sits on LIGHT0_DIRECTION, which Godot sets to the
// DirectionalLight3D's +Z (opposite the rays), so it matches the scene light.
uniform vec4 sky_top : source_color = vec4(0.169, 0.216, 0.400, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.875, 0.643, 0.541, 1.0);
uniform vec4 sun_glow : source_color = vec4(1.0, 0.72, 0.42, 1.0);
uniform vec4 ground_horizon : source_color = vec4(0.541, 0.416, 0.416, 1.0);
uniform vec4 ground_bottom : source_color = vec4(0.180, 0.141, 0.188, 1.0);
uniform vec4 cloud_tint : source_color = vec4(0.62, 0.50, 0.62, 1.0);

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.11369, 0.13787));
	p += dot(p, vec3(p.y + 19.19, p.z + 19.19, p.x + 19.19));
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

void sky() {
	float up = EYEDIR.y;
	// Tight curve: horizon colour is a band, not a slab across the zenith.
	float sky_t = clamp(pow(1.0 - clamp(up, 0.0, 1.0), 7.0), 0.0, 1.0);
	vec3 col = mix(sky_top.rgb, sky_horizon.rgb, sky_t);

	float sun_dot = -1.0;
	vec3 sun_col = sun_glow.rgb;
	if (LIGHT0_ENABLED) {
		sun_dot = dot(LIGHT0_DIRECTION, EYEDIR);
		sun_col = LIGHT0_COLOR.rgb * LIGHT0_ENERGY;
	}
	float toward = clamp(sun_dot, 0.0, 1.0);
	float band = exp(-abs(up) * 9.0);
	col = mix(col, sun_glow.rgb, band * toward * 0.85);

	// Disc about 1.2 degrees across, corona out to 16 degrees.
	float disc = cos(radians(1.2));
	float corona = cos(radians(16.0));
	if (sun_dot > disc) {
		col = sun_col;
	} else if (sun_dot > corona) {
		float t = (sun_dot - corona) / (disc - corona);
		col = mix(col, sun_col, pow(clamp(t, 0.0, 1.0), 1.6));
	}

	// High wisps only. Two octaves; no TIME, so the radiance map can stay cached.
	if (up > 0.2) {
		vec3 np = vec3(EYEDIR.x * 3.2, up * 2.4, EYEDIR.z * 3.2);
		float n = value_noise(np) * 0.65 + value_noise(np * 2.2 + vec3(4.2, 1.3, 2.8)) * 0.35;
		float w = smoothstep(0.58, 0.78, n);
		w *= smoothstep(0.2, 0.46, up) * (1.0 - smoothstep(0.8, 0.96, up));
		vec3 wisp = mix(cloud_tint.rgb, vec3(1.0, 0.84, 0.7), toward);
		col = mix(col, wisp, w * 0.55);
	}

	float g = clamp(pow(1.0 + min(up, 0.0), 12.0), 0.0, 1.0);
	vec3 ground = mix(ground_bottom.rgb, ground_horizon.rgb, g);
	COLOR = mix(ground, col, smoothstep(-0.04, 0.02, up));
}
