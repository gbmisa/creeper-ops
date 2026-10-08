// Per-pixel ground surface for terrain.gdshader. The vertex colour carries the palette
// (height band, zone, castle material); its ALPHA carries the surface kind set by
// TerrainMesh._colour: 1 = natural, 0.66 = Blight, 0.33 = castle stone, 0 = spire.
// Returns the albedo and writes a bump height (turned into a normal by the caller),
// roughness and emission.
#include "res://shaders/noise.gdshaderinc"

vec3 grass_top(vec3 base, vec2 xz, float cave, float near, inout float bump) {
	float macro = fbm3(xz * 0.07);
	float mid = fbm3(xz * 0.33 + 3.7);
	float fine = vnoise(xz * 3.6);
	float blade = vnoise(xz * vec2(11.0, 9.0));
	vec3 c = base * (0.74 + 0.48 * macro);
	if (cave < 0.5) {
		float lush = smoothstep(0.0, 0.3, base.g - max(base.r, base.b));  // green bands only, not bare highland
		c = mix(c, c * vec3(0.78, 1.12, 0.72), lush * (0.55 + 0.35 * (1.0 - mid)));
		c = mix(c, c * vec3(1.2, 1.1, 0.72), smoothstep(0.6, 0.78, mid) * 0.35);  // dry tufts
		float dirt = smoothstep(0.66, 0.82, fbm3(xz * 0.21 + 11.0));
		c = mix(c, vec3(0.33, 0.26, 0.18) * (0.8 + 0.4 * fine), dirt * 0.65);
		vec2 pv = voronoi(xz * 1.4);  // scattered pebbles on the dirt
		float peb = (1.0 - smoothstep(0.16, 0.22, pv.x)) * step(0.55, dirt);
		c = mix(c, vec3(0.52, 0.49, 0.44) * (0.8 + 0.4 * fine), peb * 0.8);
		bump += peb * 0.6;
	}
	c *= 0.84 + 0.3 * fine;
	c *= 0.9 + 0.18 * blade;
	// Close to the camera: blade-scale streaks so first person isn't a smear.
	float close = vnoise(xz * vec2(38.0, 31.0)) * 0.6 + vnoise(xz * vec2(71.0, 83.0)) * 0.4;
	c *= mix(1.0, 0.8 + 0.4 * close, near);
	bump += fine * 0.35 + blade * 0.25 + close * near * 0.4;
	return c;
}

vec3 rock_wall(vec3 base, vec3 wp, float level_h, inout float bump) {
	float along = wp.x * 0.7 + wp.z * 0.7;
	float warp = fbm3(wp.xz * 0.25) * 1.6;
	float strata = vnoise(vec2(wp.y * 2.3 + warp, along * 0.08));
	float streak = vnoise(vec2(along * 1.9, wp.y * 0.3));
	float grit = vnoise(vec2(along * 6.0, wp.y * 6.0));
	vec3 c = base * (0.68 + 0.5 * strata) * (0.82 + 0.3 * streak) * (0.9 + 0.2 * grit);
	float ledge = fract(wp.y * 2.0 / level_h + warp * 0.15);
	c *= mix(0.55, 1.0, smoothstep(0.0, 0.07, ledge));  // thin cracks between rock beds
	float t = fract(wp.y / level_h + 0.001);
	c *= mix(0.5, 1.0, smoothstep(0.0, 0.45, t));      // occluded foot of each wall
	bump += strata * 0.9 + streak * 0.5 + grit * 0.2 - (1.0 - smoothstep(0.0, 0.07, ledge)) * 0.6;
	return c;
}

vec3 castle_stone(vec3 base, vec3 wp, vec3 wn, float cliff, inout float bump) {
	if (cliff > 0.5) {  // ashlar courses on walls
		float u = abs(wn.x) > abs(wn.z) ? wp.z : wp.x;
		float row = floor(wp.y / 0.42);
		u += mod(row, 2.0) * 0.45;
		float col = floor(u / 0.9);
		vec2 f = vec2(fract(u / 0.9) * 0.9, fract(wp.y / 0.42) * 0.42);
		float m = min(min(f.x, 0.9 - f.x), min(f.y, 0.42 - f.y));
		float mortar = 1.0 - smoothstep(0.02, 0.05, m);
		vec3 c = base * (0.82 + 0.3 * hash12(vec2(row, col))) * (0.9 + 0.2 * vnoise(wp.xy * 5.0 + wp.zy * 5.0));
		bump += (1.0 - mortar) * 0.8 + vnoise(vec2(u, wp.y) * 6.0) * 0.2;
		return mix(c, base * 0.35, mortar);
	}
	vec2 v = voronoi(wp.xz * 0.95);  // flagstones on tops
	float seam = 1.0 - smoothstep(0.03, 0.09, v.y - v.x);
	vec3 c = base * (0.85 + 0.25 * hash12(floor(wp.xz * 0.95 + v.x))) * (0.9 + 0.2 * vnoise(wp.xz * 4.0));
	bump += (1.0 - seam) * 0.7;
	return mix(c, base * 0.4, seam);
}

vec3 ground_look(vec3 base, float kind, vec3 wp, vec3 wn, float level_h, float cave, float near,
		out float bump, out float rough, out vec3 glow) {
	bump = 0.0;
	rough = 0.92;
	glow = vec3(0.0);
	float slope = 1.0 - clamp(wn.y, 0.0, 1.0);
	float cliff = smoothstep(0.22, 0.5, slope);
	if (kind < 0.16) {  // spire obsidian: glassy, faint veins
		rough = 0.35;
		bump += vnoise(wp.xz * 2.0 + wp.y) * 0.3;
		return base * (0.85 + 0.3 * vnoise(vec2(wp.x + wp.z, wp.y) * 1.5));
	}
	if (kind < 0.5) return castle_stone(base, wp, wn, cliff, bump);
	float bt = 0.0;
	float br = 0.0;
	vec3 top = grass_top(base, wp.xz, cave, near, bt);
	vec3 rock = rock_wall(base, wp, level_h, br);
	// Grass drapes a little over the top lip of each wall.
	float t = fract(wp.y / level_h + 0.001);
	float lip = smoothstep(0.78, 0.92, t) * cliff;
	float w = cliff * (1.0 - lip);
	vec3 c = mix(top, rock * 0.95, w);
	bump = mix(bt, br, w);
	if (kind < 0.83) {  // Blight: cracked crust glowing violet
		vec2 v = voronoi(wp.xz * 0.55);
		float crack = 1.0 - smoothstep(0.015, 0.045, v.y - v.x);
		c = mix(c, vec3(0.08, 0.02, 0.1), crack * 0.7);
		glow = vec3(0.3, 0.07, 0.42) * crack * smoothstep(0.35, 0.8, vnoise(wp.xz * 0.3));
		bump -= crack * 0.8;
	}
	return c;
}
