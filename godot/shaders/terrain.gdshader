// Terrain: per-pixel grass/rock/stone look (terrain_look.gdshaderinc), plus every command-mode ground overlay drawn as smooth
// tints ON the surface (never separate quads that clip):
//   collector field  = union of collector discs, masked by "claimable" (dry, not Blight)
//   network cover    = faint discs of connected relays while placing
//   ghost footprint  = soft disc, green when placeable, red when not
//   range ring(s)    = anti-aliased circles (placement range, selection, move target)
shader_type spatial;
render_mode cull_back;

#include "res://shaders/terrain_look.gdshaderinc"

uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
uniform float level_h = 1.25;
uniform float is_cave = 0.0;
uniform float bump_strength = 0.05;
uniform sampler2D claim_tex : filter_nearest, repeat_disable; // R = cell claimed by a collector
uniform vec2 map_size = vec2(160.0);
uniform float show_overlay = 1.0;
uniform float show_cover = 0.0;

uniform vec4 field_preview = vec4(0.0); // xy = centre, z = half-size m, w = on (placing a collector)
uniform int field_plan_count = 0;
uniform vec4 field_plans[48]; // drag-build: xy centre, z = half-size m, one 7x7 outline per planned collector
uniform int node_count = 0;
uniform vec4 nodes[96];        // xy = world xz, z = link radius m

uniform vec4 ghost = vec4(0.0);          // xy, z = radius m, w = on
uniform float ghost_ok = 1.0;
uniform vec4 ring_a = vec4(0.0);         // xy, z = radius m, w = on
uniform vec3 ring_a_color : source_color = vec3(0.37, 0.83, 1.0);
uniform vec4 ring_b = vec4(0.0);
uniform vec3 ring_b_color : source_color = vec3(0.62, 1.0, 0.48);
uniform int sel_count = 0;
uniform int plan_count = 0;
uniform vec4 plans[48];       // drag-build preview: xy, z = radius m, w = 1 ok / 0 blocked
uniform float plan_lines = 0.0; // 1 = chain: draw link lines between consecutive pieces
uniform vec4 sels[48];        // box-selected structures: xy, z = radius m, w = on

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

float disc(vec2 p, vec2 c, float r, float soft) {
	return 1.0 - smoothstep(r - soft, r + soft, length(p - c));
}

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-4), 0.0, 1.0);
	return length(p - a - ab * t);
}

float ring(vec2 p, vec4 r) {
	float d = abs(length(p - r.xy) - r.z);
	float aa = fwidth(d) * 1.5;
	return r.w * (1.0 - smoothstep(0.1, 0.1 + aa + 0.06, d));
}

void fragment() {
	vec3 wn = normalize(wnrm);
	float bump;
	float rough;
	vec3 glow;
	float near = 1.0 - smoothstep(4.0, 14.0, length(wpos - CAMERA_POSITION_WORLD));
	vec3 col = ground_look(COLOR.rgb, COLOR.a, wpos, wn, level_h, is_cave, near, bump, rough, glow);
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped(wn, wpos, bump, bump_strength), 0.0)).xyz);
	// Palette grade (fantasy dusk): richer, slightly warmer greens and earth. Overlays below are untouched.
	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(vec3(lum), col, 1.2) * vec3(0.92, 1.04, 0.95);
	vec2 p = wpos.xz;
	vec2 uv = p / map_size;
	bool inside = uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0;
	float emit = 0.0;
	if (inside && show_overlay > 0.5) {
		// Claimed cells: CW-style green squares with a thin grid line inside each tile.
		vec2 cf = uv * vec2(textureSize(claim_tex, 0));
		float claim = texelFetch(claim_tex, ivec2(cf), 0).r;
		vec2 lc = fract(cf);
		float bd = min(min(lc.x, 1.0 - lc.x), min(lc.y, 1.0 - lc.y));
		float grid = 1.0 - smoothstep(0.02, 0.02 + fwidth(cf.x) * 1.5, bd);
		col = mix(col, vec3(0.05, 0.36, 0.14), claim * 0.5);  // dark enough to read on pale rock
		col = mix(col, vec3(0.25, 0.80, 0.40), claim * grid * 0.55);
		emit += claim * 0.03;
		if (show_cover > 0.5) {
			float cover = 0.0;
			for (int i = 0; i < node_count; i++) cover = max(cover, disc(p, nodes[i].xy, nodes[i].z, 0.6));
			col = mix(col, vec3(0.35, 0.75, 1.0), cover * 0.14);
		}
	}
	if (field_preview.w > 0.5) {
		vec2 q = abs(p - field_preview.xy);
		float m = max(q.x, q.y);
		float inside = 1.0 - step(field_preview.z, m);
		float outline = 1.0 - smoothstep(0.0, 0.12 + fwidth(m), abs(m - field_preview.z));
		col = mix(col, vec3(0.4, 1.0, 0.55), inside * 0.16 + outline * 0.7);
		emit += outline * 0.2;
	}
	for (int i = 0; i < field_plan_count; i++) {
		vec2 fq = abs(p - field_plans[i].xy);
		float fm = max(fq.x, fq.y);
		float fill = 1.0 - step(field_plans[i].z, fm);
		float edge = 1.0 - smoothstep(0.0, 0.12 + fwidth(fm), abs(fm - field_plans[i].z));
		col = mix(col, vec3(0.4, 1.0, 0.55), fill * 0.16 + edge * 0.7);
		emit += edge * 0.2;
	}
	if (ghost.w > 0.5) {
		float g = disc(p, ghost.xy, ghost.z, 0.35);
		vec3 gc = ghost_ok > 0.5 ? vec3(0.2, 1.0, 0.55) : vec3(1.0, 0.25, 0.25);
		col = mix(col, gc, g * 0.5);
		emit += g * 0.15;
	}
	for (int i = 0; i < plan_count; i++) {
		vec3 pc = plans[i].w > 0.5 ? vec3(0.2, 1.0, 0.55) : vec3(1.0, 0.25, 0.25);
		float g = disc(p, plans[i].xy, plans[i].z, 0.3);
		if (plan_lines > 0.5 && i > 0) {
			float sd = segment(p, plans[i - 1].xy, plans[i].xy);
			g = max(g, 1.0 - smoothstep(0.08, 0.14 + fwidth(sd), sd));
		}
		col = mix(col, pc, g * 0.55);
		emit += g * 0.2;
	}
	float ra = ring(p, ring_a);
	float rb = ring(p, ring_b);
	float rs = 0.0;  // group rings: thicker and warm so they read on the green field
	for (int i = 0; i < sel_count; i++) {
		float d = abs(length(p - sels[i].xy) - sels[i].z);
		rs = max(rs, 1.0 - smoothstep(0.22, 0.3 + fwidth(d) * 1.5, d));
	}
	col = mix(col, ring_a_color, ra * 0.85);
	col = mix(col, ring_b_color, rb * 0.85);
	col = mix(col, vec3(1.0, 0.86, 0.35), rs * 0.9);
	ALBEDO = col;
	EMISSION = glow + col * emit + ring_a_color * ra * 0.35 + ring_b_color * rb * 0.35 + vec3(1.0, 0.86, 0.35) * rs * 0.4;
	ROUGHNESS = rough;
	SPECULAR = 0.2;
}
