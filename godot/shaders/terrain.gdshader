// Terrain: vertex colour + grain, plus every command-mode ground overlay drawn as smooth
// tints ON the surface (never separate quads that clip):
//   collector field  = union of collector discs, masked by "claimable" (dry, not Blight)
//   network cover    = faint discs of connected relays while placing
//   ghost footprint  = soft disc, green when placeable, red when not
//   range ring(s)    = anti-aliased circles (placement range, selection, move target)
shader_type spatial;
render_mode cull_back;

uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
uniform sampler2D claim_tex : filter_nearest, repeat_disable; // R = cell claimed by a collector
uniform vec2 map_size = vec2(160.0);
uniform float show_overlay = 1.0;
uniform float show_cover = 0.0;

uniform vec4 field_preview = vec4(0.0); // xy = centre, z = half-size m, w = on (placing a collector)
uniform int node_count = 0;
uniform vec4 nodes[96];        // xy = world xz, z = link radius m

uniform vec4 ghost = vec4(0.0);          // xy, z = radius m, w = on
uniform float ghost_ok = 1.0;
uniform vec4 ring_a = vec4(0.0);         // xy, z = radius m, w = on
uniform vec3 ring_a_color : source_color = vec3(0.37, 0.83, 1.0);
uniform vec4 ring_b = vec4(0.0);
uniform vec3 ring_b_color : source_color = vec3(0.62, 1.0, 0.48);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float disc(vec2 p, vec2 c, float r, float soft) {
	return 1.0 - smoothstep(r - soft, r + soft, length(p - c));
}

float ring(vec2 p, vec4 r) {
	float d = abs(length(p - r.xy) - r.z);
	float aa = fwidth(d) * 1.5;
	return r.w * (1.0 - smoothstep(0.1, 0.1 + aa + 0.06, d));
}

void fragment() {
	vec3 col = COLOR.rgb * (0.8 + 0.35 * texture(grain, wpos.xz / 7.0).r);
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
		col = mix(col, vec3(0.30, 0.95, 0.50), claim * 0.28);
		col = mix(col, vec3(0.55, 1.0, 0.65), claim * grid * 0.45);
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
	if (ghost.w > 0.5) {
		float g = disc(p, ghost.xy, ghost.z, 0.35);
		vec3 gc = ghost_ok > 0.5 ? vec3(0.2, 1.0, 0.55) : vec3(1.0, 0.25, 0.25);
		col = mix(col, gc, g * 0.5);
		emit += g * 0.15;
	}
	float ra = ring(p, ring_a);
	float rb = ring(p, ring_b);
	col = mix(col, ring_a_color, ra * 0.85);
	col = mix(col, ring_b_color, rb * 0.85);
	ALBEDO = col;
	EMISSION = col * emit + ring_a_color * ra * 0.35 + ring_b_color * rb * 0.35;
	ROUGHNESS = 0.93;
	SPECULAR = 0.2;
}
