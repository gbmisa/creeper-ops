// Creeper surface. A flat lattice (same spacing and triangle split as the terrain) lifted to
// the per-cell display level from CreeperMesh, interpolated with the SAME terraced bilinear
// weights as Grid.smooth_y. The surface is flat over pools, runs into cliff walls, and dips
// under the ground at shorelines; anything below the terrain is discarded, so the visible
// edge is exactly where creeper meets ground.
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;  // opaque: no see-through ground

uniform sampler2D height_tex : filter_nearest, repeat_disable;
uniform sampler2D surf_tex : filter_nearest, repeat_disable;
uniform sampler2D depth_tex : filter_nearest, repeat_disable;
uniform vec2 cells = vec2(80.0);
uniform float cell = 2.0;
uniform float level_h = 1.0;
uniform float band = 0.6667;
uniform vec3 shallow : source_color = vec3(0.10, 0.32, 0.95);
uniform vec3 deep : source_color = vec3(0.02, 0.05, 0.30);
uniform vec3 glow : source_color = vec3(0.12, 0.40, 1.0);

varying float vdepth;
varying float vabove;
varying float vlevel;
varying vec3 wpos;

float fetch(sampler2D t, vec2 c) {
	ivec2 i = ivec2(clamp(c, vec2(0.0), cells - 1.0));
	return texelFetch(t, i, 0).r;
}

vec2 terrace(vec2 t) {
	return clamp((t - 0.5 + band * 0.5) / band, 0.0, 1.0);
}

float bil(sampler2D t, vec2 wxz) {
	vec2 f = wxz / cell - 0.5;
	vec2 i = floor(f);
	vec2 fr = terrace(f - i);
	float a = fetch(t, i);
	float b = fetch(t, i + vec2(1.0, 0.0));
	float c = fetch(t, i + vec2(0.0, 1.0));
	float d = fetch(t, i + vec2(1.0, 1.0));
	return mix(mix(a, b, fr.x), mix(c, d, fr.x), fr.y);
}

void vertex() {
	vec2 p = VERTEX.xz;
	float s = bil(surf_tex, p);
	vabove = s - bil(height_tex, p);
	vdepth = bil(depth_tex, p);
	vlevel = s;
	VERTEX.y = s * level_h + 0.03;
	float e = cell / 3.0;
	float l = bil(surf_tex, p - vec2(e, 0.0));
	float r = bil(surf_tex, p + vec2(e, 0.0));
	float u = bil(surf_tex, p - vec2(0.0, e));
	float dn = bil(surf_tex, p + vec2(0.0, e));
	NORMAL = normalize(vec3((l - r) * level_h, 2.0 * e, (u - dn) * level_h));
	wpos = VERTEX;
}

// Cheap value noise for a slow, organic surface shimmer (no checkerboard).
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	if (vabove < 0.0) discard;
	float k = clamp(vdepth / 4.0, 0.0, 1.0);
	float n = vnoise(wpos.xz * 0.35 + vec2(TIME * 0.25, -TIME * 0.18)) * 0.6
		+ vnoise(wpos.xz * 0.9 - vec2(TIME * 0.4, TIME * 0.3)) * 0.4;
	vec3 col = mix(shallow, deep, sqrt(k));
	// CW3-style contour lines every creeper level make depth readable from above.
	float lv = fract(vlevel);
	float lw = fwidth(vlevel) * 1.2 + 0.015;
	float contour = (1.0 - smoothstep(0.0, lw, lv)) * smoothstep(0.15, 0.6, vdepth);
	// Bright rim where the creeper meets the ground.
	float rim = 1.0 - smoothstep(0.0, 0.18, vabove);
	ALBEDO = col * (0.85 + 0.3 * n) + vec3(0.2, 0.4, 0.9) * contour * 0.35;
	EMISSION = glow * (0.08 + 0.10 * (1.0 - k) + 0.06 * n + 0.45 * rim + 0.25 * contour);
	ROUGHNESS = 0.6;
	SPECULAR = 0.15;
	METALLIC = 0.1;
}
