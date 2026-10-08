// Shared shader helpers: cheap procedural noise (value, fbm, cellular) and bump mapping.
// Included by the terrain and creeper shaders.

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm3(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + 17.1) * 0.3 + vnoise(p * 4.11 - 9.3) * 0.15;
}

// Cellular distance (F1, F2) for cracks, flagstones and pebbles.
vec2 voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash12(i + g), hash12(i + g + 41.7));
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return vec2(d1, d2);
}

// Bump mapping from a scalar field via screen-space derivatives (Mikkelsen). World space.
vec3 bumped(vec3 n, vec3 wp, float h, float strength) {
	vec3 dpdx = dFdx(wp);
	vec3 dpdy = dFdy(wp);
	float hx = dFdx(h);
	float hy = dFdy(h);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (hx * r1 + hy * r2);
	return normalize(abs(det) * n - grad * strength);
}
